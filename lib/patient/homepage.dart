import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
  String? userEmail = FirebaseAuth.instance.currentUser?.email;
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome $userEmail' ,style: TextStyle(color:Colors.white)),
        backgroundColor: Colors.pinkAccent,
        actions: [
          IconButton(               
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginPage()),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Header
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

            // Progress Bar Card
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.pinkAccent, Colors.purple]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Week 24 of 40", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text("Your baby is about the size of a corn", style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 12),
                  Stack(
                    children: [
                      Container(height: 10, width: double.infinity, color: Colors.black),
                      FractionallySizedBox(
                        widthFactor: 24 / 40,
                        child: Container(height: 10, color: Colors.pink),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text("16 weeks remaining", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Vitals
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: const [
                          Icon(Icons.favorite, color: Colors.red),
                          SizedBox(height: 8),
                          Text("72", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          Text("BPM"),
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
                        children: const [
                          Icon(Icons.monitor_heart, color: Colors.blue),
                          SizedBox(height: 8),
                          Text("120/80", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          Text("Blood Pressure"),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Appointments
            const Text("Upcoming Appointments", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                title: const Text("Dr. Sarah Johnson"),
                subtitle: const Text("Routine Checkup"),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text("Mar 15"),
                    Text("10:00 AM"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
