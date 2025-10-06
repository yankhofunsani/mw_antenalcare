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
  bool _isLoading = true;

  List<Map<String, dynamic>> appointmentRequests = [];
  List<Map<String, dynamic>> scheduledAppointments = [];
  List<Map<String, dynamic>> deniedAppointments = [];

  User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    if (user != null) _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    if (user == null) return;

    final patientSnap = await FirebaseFirestore.instance
        .collection('patients')
        .where('email', isEqualTo: user!.email)
        .limit(1)
        .get();

    if (patientSnap.docs.isEmpty) return;

    final regNumber = patientSnap.docs.first.data()['registration_number'];
    final name = patientSnap.docs.first.data()['firstname'] +
        ' ' +
        patientSnap.docs.first.data()['surname'];

    // Appointment Requests
    final requestSnap = await FirebaseFirestore.instance
        .collection('appointment_request')
        .where('registration_number', isEqualTo: regNumber)
        .orderBy('createdAt', descending: true)
        .get();

    // Scheduled Appointments
    final scheduledSnap = await FirebaseFirestore.instance
        .collection('scheduled_appointment')
        .where('registration_number', isEqualTo: regNumber)
        .orderBy('scheduled_datetime', descending: true)
        .get();

    // Denied Appointments
    final deniedSnap = await FirebaseFirestore.instance
        .collection('denied_appointment')
        .where('registration_number', isEqualTo: regNumber)
        .orderBy('createdAt', descending: true)
        .get();

    setState(() {
      appointmentRequests = requestSnap.docs.map((doc) {
        final data = doc.data();
        final requestedDate = data['preferred_date'];
        String dateText = "N/A";
        if (requestedDate is Timestamp) {
          dateText = DateFormat('dd MMM yyyy').format(requestedDate.toDate());
        }
        return {
          'patient_name': data['patient_name'] ?? name,
          'registration_number': data['registration_number'] ?? regNumber,
          'reason': data['reason'] ?? '',
          'preferred_date': dateText,
          'status': data['status'] ?? 'sent',
          'id': doc.id,
        };
      }).toList();

      scheduledAppointments = scheduledSnap.docs.map((doc) {
        final data = doc.data();
        final scheduledDate = data['scheduled_datetime'];
        String dateText = "N/A";
        if (scheduledDate is Timestamp) {
          dateText = DateFormat('dd MMM yyyy – HH:mm')
              .format(scheduledDate.toDate());
        }
        return {
          'assigned_doctor': data['assigned_doctor'] ?? '',
          'scheduled_datetime': dateText,
          'status': data['status'] ?? 'scheduled',
          'reason': data['reason'] ?? '',
          'id': doc.id,
        };
      }).toList();

      deniedAppointments = deniedSnap.docs.map((doc) {
        final data = doc.data();
        return {
          'patient_name': data['patient_name'] ?? name,
          'registration_number': data['registration_number'] ?? regNumber,
          'reason': data['reason'] ?? '',
          'denied_reason': data['denied_reason'] ?? 'Not specified',
          'status': 'denied',
          'id': doc.id,
        };
      }).toList();

      _isLoading = false;
    });
  }

  // Reschedule denied appointment
  Future<void> _reschedule(Map<String, dynamic> denied) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime == null) return;

    final newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    final firestore = FirebaseFirestore.instance;

    await firestore.collection('appointment_request').add({
      'patient_name': denied['patient_name'],
      'registration_number': denied['registration_number'],
      'reason': denied['reason'],
      'preferred_date': newDateTime,
      'status': 'pending',
      'createdAt': DateTime.now(),
    });

    await firestore
        .collection('denied_appointment')
        .doc(denied['id'])
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reschedule request sent successfully")));
    _fetchAppointments();
  }

  // Book a new appointment
  Future<void> _bookAppointment() async {
    if (user == null) return;

    final patientSnap = await FirebaseFirestore.instance
        .collection('patients')
        .where('email', isEqualTo: user!.email)
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
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Book Appointment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: "Patient Name"),
                enabled: false,
              ),
              TextFormField(
                initialValue: regNumber,
                decoration:
                    const InputDecoration(labelText: "Registration Number"),
                enabled: false,
              ),
              TextFormField(
                controller: reasonController,
                decoration:
                    const InputDecoration(labelText: "Reason for Appointment"),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text("Preferred Date: "),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setStateDialog(() {
                          selectedDate = date;
                        });
                      }
                    },
                    child: Text(selectedDate == null
                        ? "Select Date"
                        : DateFormat('dd MMM yyyy').format(selectedDate!)),
                  )
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () async {
                  if (reasonController.text.isEmpty || selectedDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please fill all fields")));
                    return;
                  }

                  await FirebaseFirestore.instance
                      .collection('appointment_request')
                      .add({
                    'patient_name': name,
                    'registration_number': regNumber,
                    'reason': reasonController.text,
                    'preferred_date': selectedDate,
                    'status': 'pending',
                    'createdAt': DateTime.now(),
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Appointment requested")));
                  _fetchAppointments();
                },
                child: const Text("Submit")),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> items,
      Widget Function(Map<String, dynamic>) builder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        items.isEmpty
            ? const Center(child: Text("No records found."))
            : ListView.builder(
                itemCount: items.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) => builder(items[index]),
              ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text("Sessions & Appointments",style: TextStyle(color: Colors.white),
        
      ),
      backgroundColor: Colors.pinkAccent,
      leading: const Icon(Icons.calendar_month, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSection(
                    "Appointment Requests",
                    appointmentRequests,
                    (item) => Card(
                      child: ListTile(
                        title: Text(
                            "${item['preferred_date']} - ${item['reason']}"),
                        trailing: Text(item['status'],
                            style: const TextStyle(
                                color: Colors.purpleAccent,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),

                  _buildSection(
                    "Scheduled Appointments",
                    scheduledAppointments,
                    (item) => Card(
                      child: ListTile(
                        title: Text("With Dr. ${item['assigned_doctor']}"),
                        subtitle: Text(
                            "On: ${item['scheduled_datetime']}\nReason: ${item['reason']}"),
                        trailing: Text(item['status'],
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),

                  _buildSection(
                    "Denied Appointments",
                    deniedAppointments,
                    (item) => Card(
                      child: ListTile(
                        title: Text("Reason: ${item['reason']}"),
                        subtitle:
                            Text("Denied because: ${item['denied_reason']}"),
                        trailing: ElevatedButton(
                          onPressed: () => _reschedule(item),
                          child: const Text("Reschedule"),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _bookAppointment,
        icon: const Icon(Icons.add),
        label: const Text("Book Appointment"),
        backgroundColor: Colors.pinkAccent,
      ),
    );
  }
}
