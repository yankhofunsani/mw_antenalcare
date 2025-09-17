import 'package:flutter/material.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Tracker extends StatefulWidget {
  const Tracker({super.key});

  @override
  _TrackerState createState() => _TrackerState();
}

class _TrackerState extends State<Tracker> {
  String? patientName;
  String? registrationNumber;
  String? positionPresentation;
  String? fundalHeight;
  String? gestAge;
  DateTime? lmp;
  DateTime? edd;

  int? daysToGo;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadTrackerData();
  }

  Future<void> _loadTrackerData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => loading = false);
        return;
      }

      final patientSnap = await FirebaseFirestore.instance
          .collection("patients")
          .where("email", isEqualTo: user.email)
          .limit(1)
          .get();

      if (patientSnap.docs.isEmpty) {
        setState(() => loading = false);
        return;
      }

      final patientData = patientSnap.docs.first.data();
      registrationNumber = patientData["registration_number"];
      patientName = "${patientData["firstname"]} ${patientData["surname"]}";

      final sessionSnap = await FirebaseFirestore.instance
          .collection("session_data")
          .where("registration_number", isEqualTo: registrationNumber)
          .orderBy("createdAt", descending: true)
          .limit(1)
          .get();

      if (sessionSnap.docs.isNotEmpty) {
        final sessionData = sessionSnap.docs.first.data();
        final visit = sessionData["visit"] as Map<String, dynamic>;
        positionPresentation = visit["position_presentation"].toString();
        fundalHeight = visit["fundal_height"].toString();
        gestAge = visit["gest_age"].toString();
      }

      final ancSnap = await FirebaseFirestore.instance
          .collection("anc_registers")
          .where("registration_number", isEqualTo: registrationNumber)
          .limit(1)
          .get();

      if (ancSnap.docs.isNotEmpty) {
        final ancData = ancSnap.docs.first.data();
        lmp = (ancData["lmp"] as Timestamp).toDate();
        edd = (ancData["edd"] as Timestamp).toDate();
        daysToGo = edd!.difference(DateTime.now()).inDays;
      }

      setState(() => loading = false);
    } catch (e) {
      print("Error loading tracker: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Pregnancy Tracker",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.pinkAccent,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : registrationNumber == null
              ? const Center(child: Text("No patient data found"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (daysToGo != null) _buildProgressCard(daysToGo!),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          double maxWidth = constraints.maxWidth;
                          int cardsPerRow = maxWidth ~/ 200; 
                          if (cardsPerRow < 2) cardsPerRow = 2;
                          double cardWidth = (maxWidth - (cardsPerRow - 1) * 12) / cardsPerRow;

                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildInfoCard("Patient Name", patientName ?? "N/A", Icons.person, cardWidth),
                              _buildInfoCard("Registration Number", registrationNumber ?? "N/A", Icons.confirmation_num, cardWidth),
                              _buildInfoCard("Position Presentation", positionPresentation ?? "N/A", Icons.pregnant_woman, cardWidth),
                              _buildInfoCard("Fundal Height", fundalHeight ?? "N/A", Icons.height, cardWidth),
                              _buildInfoCard("Gestational Age", gestAge ?? "N/A", Icons.calendar_today, cardWidth),
                              _buildInfoCard("LMP", lmp != null ? DateFormat("dd MMM yyyy").format(lmp!) : "N/A", Icons.date_range, cardWidth),
                              _buildInfoCard("EDD", edd != null ? DateFormat("dd MMM yyyy").format(edd!) : "N/A", Icons.event_available, cardWidth),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, double width) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: Colors.pinkAccent),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(value, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(int daysLeft) {
    int totalPregnancyDays = 280;
    int elapsed = totalPregnancyDays - daysLeft;
    double progress = (elapsed / totalPregnancyDays).clamp(0, 1);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Days until delivery: $daysLeft",
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.pinkAccent)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                color: Colors.pinkAccent,
                minHeight: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
