import 'package:flutter/material.dart';


class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  _SessionsPageState createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  List<String> sessions = [
    "Routine Checkup - 15 July 2025, 10:00 AM",
    "Ultrasound - 22 July 2025, 9:00 AM",
  ];

  void _bookAppointment() {
    setState(() {
      sessions.add("New Appointment - ${DateTime.now().toLocal()}");
    });
  }

  void _cancelAppointment(int index) {
    setState(() {
      sessions.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sessions')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Upcoming Sessions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: sessions.isEmpty
                  ? const Center(child: Text("No upcoming sessions."))
                  : ListView.builder(
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: ListTile(
                            title: Text(sessions[index]),
                            trailing: IconButton(
                              icon: Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => _cancelAppointment(index),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _bookAppointment,
              icon: Icon(Icons.add),
              label: Text("Book Appointment"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}