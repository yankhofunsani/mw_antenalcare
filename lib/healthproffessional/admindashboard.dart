import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/auth/login.dart';
import '/healthproffessional/registrationpage.dart'; 
import '/healthproffessional/anc_register.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
                _buildSidebarItem(
                  context,
                  Icons.dashboard,
                  "Dashboard",
                  const DashboardScreen(), 
                ),
                _buildSidebarItem(
                  context,
                  Icons.person_add,
                  "Register User",
                  const RegistrationPage(), 
                ),
                _buildSidebarItem(
                  context,
                  Icons.event,
                  "Appointments",
                  Scaffold(
                    appBar: AppBar(title: const Text("Appointments")),
                    body: const Center(child: Text("Appointments Page")),
                  ),
                ),
                _buildSidebarItem(
                  context,
                  Icons.pregnant_woman,
                  "ANC Registration",
                    ANCRegisterPage(),
                ),
                _buildSidebarItem(
                  context,
                  Icons.folder_shared,
                  "Patient Records",
                  Scaffold(
                    appBar: AppBar(title: const Text("Patient Records")),
                    body: const Center(child: Text("Patient Records Page")),
                  ),
                ),
                 _buildSidebarItem(
                  context,
                  Icons.pregnant_woman,
                  "ANC Session details",
                  Scaffold(
                    appBar: AppBar(title: const Text("Patient session details")),
                    body: const Center(child: Text("Patient anc session page")),
                  ),
                ),



                const Spacer(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text("Logout"),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
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

                  // Stats row
                  Row(
                    children: const [
                      Expanded(
                        child: _StatCard(
                          title: "Total Patients",
                          value: "1,247",
                          subtitle: "+12% from last week",
                          icon: Icons.people,
                          color: Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _StatCard(
                          title: "Today's Appointments",
                          value: "24",
                          subtitle: "+3 from last week",
                          icon: Icons.calendar_today,
                          color: Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _StatCard(
                          title: "New Registrations",
                          value: "8",
                          subtitle: "+2 from last week",
                          icon: Icons.person_add,
                          color: Colors.orange,
                        ),
                      ),
                      Expanded(
                        child: _StatCard(
                          title: "Pending Records",
                          value: "5",
                          subtitle: "-1 from last week",
                          icon: Icons.pending_actions,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Appointments + Pending Tasks
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Expanded(child: _AppointmentsCard()),
                      SizedBox(width: 16),
                      Expanded(child: _TasksCard()),
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

  // Sidebar item with navigation
  static Widget _buildSidebarItem(
    BuildContext context,
    IconData icon,
    String label,
    Widget page,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(label),
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
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
    super.key,
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
  const _AppointmentsCard({super.key});

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
            _appointmentItem("Emma Thompson", "Routine Checkup", "09:00 AM"),
            _appointmentItem("Maria Garcia", "Ultrasound", "10:30 AM"),
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
  const _TasksCard({super.key});

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
              "Pending Tasks",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _taskItem("Complete ANC registration for Emma Thompson", "2 hours ago", "High"),
            _taskItem("Update patient records for Maria Garcia", "4 hours ago", "Medium"),
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
