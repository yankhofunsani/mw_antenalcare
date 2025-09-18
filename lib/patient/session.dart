import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  _SessionsPageState createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  List<Map<String, dynamic>> sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final patientSnap = await FirebaseFirestore.instance
        .collection('patients')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (patientSnap.docs.isEmpty) return;

    final regNumber = patientSnap.docs.first.data()['registration_number'];
    final name = patientSnap.docs.first.data()['firstname'] +
        ' ' +
        patientSnap.docs.first.data()['surname'];

    final snap = await FirebaseFirestore.instance
        .collection('appointment_request')
        .where('registration_number', isEqualTo: regNumber)
        .orderBy('createdAt', descending: true)
        .get();

    setState(() {
      sessions = snap.docs.map((doc) {
        final data = doc.data();
        return {
          'patient_name': data['patient_name'] ?? name,
          'registration_number': data['registration_number'] ?? regNumber,
          'reason': data['reason'] ?? '',
          'preferred_date': (data['preferred_date'] as Timestamp?)?.toDate() ??
              DateTime.now(),
          'status': data['status'] ?? 'sent',
          'id': doc.id,
        };
      }).toList();
      _isLoading = false;
    });
  }

  void _openAppointmentForm() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final patientSnap = await FirebaseFirestore.instance
        .collection('patients')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (patientSnap.docs.isEmpty) return;

    final regNumber = patientSnap.docs.first.data()['registration_number'];
    final name = patientSnap.docs.first.data()['firstname'] +
        ' ' +
        patientSnap.docs.first.data()['surname'];

    final reasonController = TextEditingController();
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Request Appointment'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    initialValue: name,
                    decoration: const InputDecoration(
                      labelText: 'Patient Name',
                    ),
                    enabled: false,
                  ),
                  TextFormField(
                    initialValue: regNumber,
                    decoration: const InputDecoration(
                      labelText: 'Registration Number',
                    ),
                    enabled: false,
                  ),
                  TextFormField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason for Appointment',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Preferred Date: '),
                      TextButton(
                        child: Text(selectedDate != null
                            ? DateFormat('dd MMM yyyy').format(selectedDate!)
                            : 'Select Date'),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() {
                              selectedDate = date;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (reasonController.text.isEmpty || selectedDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Please fill all fields')));
                    return;
                  }

                  try {
                    await FirebaseFirestore.instance
                        .collection('appointment_request')
                        .add({
                      'patient_name': name,
                      'registration_number': regNumber,
                      'reason': reasonController.text,
                      'preferred_date': selectedDate,
                      'status': 'sent',
                      'createdAt': DateTime.now(),
                    });

                    Navigator.pop(context);
                    _fetchAppointments();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Appointment requested successfully')));
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to send request')));
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _resendRequest(Map<String, dynamic> session) {
    _openAppointmentForm();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessions and Appointments'),
        backgroundColor: Colors.grey.shade100,
        leading: const Icon(Icons.calendar_month, color: Colors.black)
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Appointment request',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: sessions.isEmpty
                        ? const Center(child: Text("No appointment request."))
                        : ListView.builder(
                            itemCount: sessions.length,
                            itemBuilder: (context, index) {
                              final session = sessions[index];
                              return Card(
                                child: ListTile(
                                  title: Text(
                                      '${DateFormat('dd MMM yyyy').format(session['preferred_date'])} - ${session['reason']}'),
                                  subtitle: Text('Status: ${session['status']}'),
                                  trailing: session['status'] == 'failed'
                                      ? ElevatedButton(
                                          onPressed: () =>
                                              _resendRequest(session),
                                          child: const Text('Resend'),
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.orangeAccent),
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _openAppointmentForm,
                    icon: const Icon(Icons.add),
                    label: const Text("Book Appointment",),
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
