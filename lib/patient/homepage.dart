import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
  final _firestore = FirebaseFirestore.instance;
  String? userEmail;
  String? registrationNumber;

  Map<String, dynamic>? latestSession;
  List<Map<String, dynamic>> upcomingAppointments = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail == null) return;


      final patientSnap = await _firestore
          .collection('patients')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (patientSnap.docs.isEmpty) return;
      registrationNumber = patientSnap.docs.first['registration_number'];

      final sessionSnap = await _firestore
          .collection('session_data')
          .where('registration_number', isEqualTo: registrationNumber)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

        if (sessionSnap.docs.isNotEmpty) {
        latestSession = sessionSnap.docs.first.data();
      }

      // upcoming session
      final today = DateTime.now();
      final ancSnap = await _firestore
          .collection('ANC_session_register')
          .where('registration_number', isEqualTo: registrationNumber)
          .get();

      upcomingAppointments = ancSnap.docs
          .where((doc) {
            final data = doc.data();
            final sessionDate = (data['session_date'] as Timestamp).toDate();
            return sessionDate.isAfter(today) || _isSameDay(sessionDate, today);
          })
          .map((doc) => doc.data())
          .toList();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error loading data: $e");
      setState(() => isLoading = false);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final visit = latestSession?['visit'] ?? {};
    final gestAgeRaw = visit['gest_age'];
    final gestAge = gestAgeRaw is num
      ? gestAgeRaw
      : num.tryParse(gestAgeRaw.toString()) ?? 0;
    final remainingWeeks = 40 - gestAge;
    final babyPresentation = visit['position_presentation'] ?? 'Unknown';
    final bp = visit['bp'] ?? 'N/A';
    final weight = visit['weight'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome Mother to be', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.pinkAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUserData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: const [
                  CircleAvatar(child: Icon(Icons.local_hospital)),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("MALAWI", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Antenatal Care", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.pinkAccent, Colors.purple]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Week $gestAge of 40",
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text("Your baby’s presentation: $babyPresentation",
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 12),
                    Stack(
                      children: [
                        Container(height: 10, width: double.infinity, color: Colors.black),
                        FractionallySizedBox(
                          widthFactor: gestAge / 40,
                          child: Container(height: 10, color: Colors.pink),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text("$remainingWeeks weeks remaining",
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(Icons.monitor_weight, color: Colors.purpleAccent),
                            const SizedBox(height: 8),
                            Text("$weight", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            const Text("Weight (kg)"),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(Icons.favorite, color: Colors.red),
                            const SizedBox(height: 8),
                            Text("$bp", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            const Text("Blood Pressure"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text("Upcoming Appointments",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...upcomingAppointments.map((appt) {
                final doctor = appt['doctor_name'] ?? ' Midwife';
                final sessionType = appt['session_type'] ?? 'Antenatal care routine session';
                final sessionDate = (appt['session_date'] as Timestamp).toDate();
                final formattedDate = DateFormat('MMM dd, yyyy').format(sessionDate);
                final formattedTime = DateFormat('hh:mm a').format(sessionDate);
                return Card(
                  child: ListTile(
                    title: Text(doctor),
                    subtitle: Text(sessionType),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(formattedDate),
                        Text(formattedTime),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
