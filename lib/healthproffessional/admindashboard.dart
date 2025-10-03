import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:mw_antenatalcare/healthproffessional/anc_session.dart';
import 'package:mw_antenatalcare/healthproffessional/appointment.dart';
import 'package:mw_antenatalcare/healthproffessional/patientdata.dart';
import '/auth/login.dart';
import '/healthproffessional/registrationpage.dart';
import '/healthproffessional/anc_register.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int totalPatients = 0;
  int todaysAppointments = 0;
  int newRegistrations = 0;
  int appointmentrequest=0;
  List<Map<String, dynamic>> todaysAppointmentList = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);

    // Total patients
    final patientSnapshot = await FirebaseFirestore.instance.collection('patients').get();
    final totalPatientsCount = patientSnapshot.docs.length;

    // New registrations (users)
    final userSnapshot = await FirebaseFirestore.instance.collection('users').get();
    final newRegistrationsCount = userSnapshot.docs.length;

    // Pending records (appointment_request)
    final pendingSnapshot = await FirebaseFirestore.instance.collection('appointment_request').get();
    final request=pendingSnapshot.docs.length;

    // Today's appointments
    final appointmentSnapshot = await FirebaseFirestore.instance
        .collection('scheduled_appointments')
        .where('scheduled_datetime', isGreaterThanOrEqualTo: DateTime(today.year, today.month, today.day))
        .where('scheduled_datetime', isLessThan: DateTime(today.year, today.month, today.day + 1))
        .get();

    final todaysAppointmentsCount = appointmentSnapshot.docs.length;
    final todaysAppointmentsList = appointmentSnapshot.docs.map((doc) => doc.data()).toList();

    setState(() {
      totalPatients = totalPatientsCount;
      newRegistrations = newRegistrationsCount;
      appointmentrequest=request;
      todaysAppointments = todaysAppointmentsCount;
      todaysAppointmentList = todaysAppointmentsList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DrawerHeader(
                  child: Text(
                    "QTECH ANTENAL CARE ADMIN",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildSidebarItem(context, Icons.dashboard, "Dashboard", const DashboardScreen()),
                _buildSidebarItem(context, Icons.person_add, "Register User", const RegistrationPage()),
                _buildSidebarItem(context, Icons.event, "Appointments", AppointmentPage()),
                _buildSidebarItem(context, Icons.pregnant_woman, "ANC Registration", ANCRegisterPage()),
                _buildSidebarItem(context, Icons.folder_shared, "Patient Records", PatientHomePage()),
                _buildSidebarItem(context, Icons.pregnant_woman, "ANC Session details", ANCSessionPage()),
                const Spacer(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text("Logout"),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                  },
                ),
              ],
            ),
          ),

          // Main Dashboard
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Dashboard",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

          //rows 
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: "Total Patients",
                          value: totalPatients.toString(),
                          subtitle: "",
                          icon: Icons.people,
                          color: Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _StatCard(
                          title: "Today's Appointments",
                          value: todaysAppointments.toString(),
                          subtitle: "",
                          icon: Icons.calendar_today,
                          color: Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _StatCard(
                          title: "New Registrations",
                          value: newRegistrations.toString(),
                          subtitle: "",
                          icon: Icons.person_add,
                          color: Colors.orange,
                        ),
                      ),
                      Expanded(
                        child: _StatCard(
                          title: "appointment Requests",
                          value: appointmentrequest.toString(),
                          subtitle: "",
                          icon: Icons.pending_actions,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // appointment and tasks
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _AppointmentsCard(todaysAppointmentList)),
                      const SizedBox(width: 16),
                      const Expanded(child: _TasksCard()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sidebar 
  static Widget _buildSidebarItem(BuildContext context, IconData icon, String label, Widget page) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(label),
      onTap: () {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(title, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentsCard extends StatelessWidget {
  final List<Map<String, dynamic>> appointments;

  const _AppointmentsCard(this.appointments);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Today's Appointments",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...appointments.map((appointment) {
              final name = appointment['patient_name'] ?? 'No Name';
              final type = appointment['type'] ?? 'General';
              final timestamp = appointment['scheduled_datetime'] as Timestamp;
              final time = DateFormat.jm().format(timestamp.toDate());
              return _appointmentItem(name, type, time);
            }).toList(),
          ],
        ),
      ),
    );
  }

  static Widget _appointmentItem(String name, String type, String time) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(type),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(time),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "Confirmed",
              style: TextStyle(fontSize: 12, color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}

class _TasksCard extends StatelessWidget {
  const _TasksCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "REMINDER",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _taskItem("Remember to schedule  ANC sessions on TUESDAY and THURSDAY EVERYWEEK", "weekly", "High"),
            _taskItem("Approve some special session requestn", "scheduled date", "Medium"),
          ],
        ),
      ),
    );
  }

  static Widget _taskItem(String title, String time, String priority) {
    Color color;
    switch (priority.toLowerCase()) {
      case "high":
        color = Colors.red;
        break;
      case "medium":
        color = Colors.orange;
        break;
      default:
        color = Colors.green;
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(time),
      trailing: Chip(
        label: Text(priority),
        backgroundColor: color.withOpacity(0.1),
        labelStyle: TextStyle(color: color),
      ),
    );
  }
}
