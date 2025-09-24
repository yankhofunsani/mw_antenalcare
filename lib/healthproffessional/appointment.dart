import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

enum MenuItem {
  home,
  scheduleSession,
  scheduleSpecial,
  deleteSessions,
  deleteAppointments,
}

class _AppointmentPageState extends State<AppointmentPage> {
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _patients = [];
  final List<String> _selectedPatients = [];

  TimeOfDay? _sessionStart;
  TimeOfDay? _sessionEnd;

  MenuItem _selectedMenu = MenuItem.home;
  bool _isSchedulingMode = false;

  // Fetch patients for date 
  Future<void> _fetchPatientsForDate(DateTime date) async {
    final lowerBound = date.subtract(const Duration(days: 5));
    final upperBound = date.add(const Duration(days: 5));

    final sessionSnap = await FirebaseFirestore.instance.collection('session_data').get();

    List<Map<String, dynamic>> tempPatients = [];

    for (var doc in sessionSnap.docs) {
      final sessionData = doc.data();
      final regNo = sessionData['registration_number'] ?? '';
      final name = sessionData['patient_name'] ?? '';

      final visitMap = sessionData['visit'] as Map<String, dynamic>?;
      if (visitMap == null || visitMap['next_visit_date'] == null) continue;

      DateTime? nextVisit;
      final rawNextVisit = visitMap['next_visit_date'];

      if (rawNextVisit is Timestamp) {
        nextVisit = rawNextVisit.toDate();
      } else if (rawNextVisit is String) {
        nextVisit = DateTime.tryParse(rawNextVisit);
      }

      if (nextVisit == null) continue;
      if (nextVisit.isBefore(lowerBound) || nextVisit.isAfter(upperBound)) continue;

      tempPatients.add({
        "id": doc.id,
        "registration_number": regNo,
        "name": name,
        "next_visit": nextVisit,
      });
    }

    setState(() {
      _patients = tempPatients;
    });
  }

  // --Scheduled sessions-- //
  Stream<QuerySnapshot> _scheduledSessionsStream() {
    return FirebaseFirestore.instance
        .collection('ANC_session_register')
        .orderBy('session_date', descending: false)
        .snapshots();
  }

  Future<void> _saveSession() async {
    if (_selectedDate == null || _selectedPatients.isEmpty || _sessionStart == null || _sessionEnd == null) return;

    final selectedData = _patients
        .where((p) => _selectedPatients.contains(p['id']))
        .map((p) => {
              "registration_number": p['registration_number'],
              "name": p['name'],
              "session_date": _selectedDate,
              "start_time": _sessionStart!.format(context),
              "end_time": _sessionEnd!.format(context),
            })
        .toList();

    final existing = await FirebaseFirestore.instance
        .collection('ANC_session_register')
        .where("session_date", isEqualTo: Timestamp.fromDate(_selectedDate!))
        .get();

    if (existing.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("A session already exists for this date")),
      );
      return;
    }

    for (var entry in selectedData) {
      await FirebaseFirestore.instance.collection('ANC_session_register').add(entry);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Session scheduled successfully!")),
    );

    setState(() {
      _selectedPatients.clear();
      _patients.clear();
      _selectedDate = null;
      _sessionStart = null;
      _sessionEnd = null;
      _isSchedulingMode = false;
    });
  }

  // Print session
  Future<void> _printSummary(Map<String, dynamic> session) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("ANC Session Summary",
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text("Patient: ${session['name']}"),
              pw.Text("Registration No: ${session['registration_number']}"),
              pw.Text("Session Date: ${DateFormat('yyyy-MM-dd').format((session['session_date'] as Timestamp).toDate())}"),
              pw.Text("Start Time: ${session['start_time']}"),
              pw.Text("End Time: ${session['end_time']}"),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _fetchPatientsForDate(picked);
    }
  }

  //  Special Appointment Functions 
  Future<void> _declineAppointment(String docId, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection('denied_appointment').add({
      ...data,
      "status": "denied",
      "denied_at": Timestamp.now(),
    });

    await FirebaseFirestore.instance.collection('appointment_request').doc(docId).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Appointment request declined.")),
    );

    setState(() {});
  }

  void _reviewAppointment(BuildContext context, String docId, Map<String, dynamic> data) async {
    final doctorsSnap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .get();

    final doctorList = doctorsSnap.docs
        .map((d) => {
              "uid": d.id,
              "name": "${d['firstname']} ${d['surname']}",
            })
        .toList();

    String? selectedDoctorName;
    String? selectedDoctorUid;
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Review Appointment"),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Patient: ${data['patient_name']}"),
                    Text("Reason: ${data['reason']}"),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      hint: const Text("Select Doctor"),
                      value: selectedDoctorUid,
                      items: doctorList.map((doc) {
                        return DropdownMenuItem(
                          value: doc["uid"],
                          child: Text(doc["name"]!),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedDoctorUid = val;
                          selectedDoctorName = doctorList
                              .firstWhere((doc) => doc["uid"] == val)["name"];
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => selectedDate = picked);
                      },
                      child: Text(selectedDate == null
                          ? "Pick Date"
                          : DateFormat('yyyy-MM-dd').format(selectedDate!)),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) setState(() => selectedTime = picked);
                      },
                      child: Text(selectedTime == null
                          ? "Pick Time"
                          : selectedTime!.format(context)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedDoctorUid == null || selectedDate == null || selectedTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please fill all fields")),
                      );
                      return;
                    }

                    final scheduledDateTime = DateTime(
                      selectedDate!.year,
                      selectedDate!.month,
                      selectedDate!.day,
                      selectedTime!.hour,
                      selectedTime!.minute,
                    );

                    await FirebaseFirestore.instance.collection('scheduled_appointment').add({
                      ...data,
                      "doctor_uid": selectedDoctorUid,
                      "assigned_doctor": selectedDoctorName,
                      "scheduled_datetime": Timestamp.fromDate(scheduledDateTime),
                      "status": "scheduled",
                    });

                    await FirebaseFirestore.instance
                        .collection('appointment_request')
                        .doc(docId)
                        .delete();

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Appointment scheduled successfully!")),
                    );

                    setState(() {});
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // -Delete ANC  Session 
  Future<void> _deleteSession(String docId) async {
    await FirebaseFirestore.instance.collection('ANC_session_register').doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Session deleted successfully!")),
    );
  }

  // Delete Appointments 
  Future<void> _deleteAppointment(String docId) async {
    await FirebaseFirestore.instance.collection('scheduled_appointment').doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Appointment deleted successfully!")),
    );
  }

  //  Build Page 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 220,
            color: Colors.grey.shade100,
            child: Column(
              children: [
                const SizedBox(height: 50),
                const Text("Menu", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                _buildSidebarItem(MenuItem.home, "Home", Icons.home),
                _buildSidebarItem(MenuItem.scheduleSession, "Schedule ANC Session", Icons.calendar_today),
                _buildSidebarItem(MenuItem.scheduleSpecial, "Schedule Special Appointment", Icons.event_available),
                _buildSidebarItem(MenuItem.deleteSessions, "Delete Old Sessions", Icons.delete),
                _buildSidebarItem(MenuItem.deleteAppointments, "Delete Old Appointments", Icons.delete_forever),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.dashboard, color: Colors.black),
                  title: const Text("Dashboard", style: TextStyle(color: Colors.black)),
                  onTap: () => Navigator.pushReplacementNamed(context, "/admindashboard"),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildMainContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(MenuItem item, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: _selectedMenu == item ? Colors.blue : Colors.black),
      title: Text(title, style: TextStyle(color: _selectedMenu == item ? Colors.blue : Colors.black)),
      selected: _selectedMenu == item,
      onTap: () {
        setState(() {
          _selectedMenu = item;
          _isSchedulingMode = false;
        });
      },
    );
  }

  // Main Content 
  Widget _buildMainContent() {
    switch (_selectedMenu) {
      case MenuItem.home:
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            _buildActionCard("Schedule ANC Session", Icons.calendar_today, () {
              setState(() => _selectedMenu = MenuItem.scheduleSession);
            }),
            _buildActionCard("Schedule Special Appointment", Icons.event_available, () {
              setState(() => _selectedMenu = MenuItem.scheduleSpecial);
            }),
            _buildActionCard("Delete Old Sessions", Icons.delete, () {
              setState(() => _selectedMenu = MenuItem.deleteSessions);
            }),
            _buildActionCard("Delete Old Appointments", Icons.delete_forever, () {
              setState(() => _selectedMenu = MenuItem.deleteAppointments);
            }),
          ],
        );

      // ------------------- Schedule ANC Session ------------------- //
      case MenuItem.scheduleSession:
        if (!_isSchedulingMode) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => _selectedMenu = MenuItem.home),
                  ),
                  const SizedBox(width: 8),
                  const Text("Scheduled ANC Sessions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: _scheduledSessionsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No scheduled sessions."));
                  }
                  final sessions = snapshot.data!.docs;
                  return Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          final session = sessions[index].data() as Map<String, dynamic>;
                          final docId = sessions[index].id;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(session['name'] ?? ''),
                              subtitle: Text(
                                  "Date: ${DateFormat('yyyy-MM-dd').format((session['session_date'] as Timestamp).toDate())} | Start: ${session['start_time']} | End: ${session['end_time']}"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.print, color: Colors.blue),
                                    onPressed: () => _printSummary(session),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteSession(docId),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text("Schedule New Session"),
                          onPressed: () => setState(() => _isSchedulingMode = true),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        } else {
          // scheduling form
          return _buildScheduleSessionForm();
        }

      // Schedule Special Appointment  //
      case MenuItem.scheduleSpecial:
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('appointment_request').get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No appointment requests found."));
            }

            final requests = snapshot.data!.docs;

            return ListView.builder(
              shrinkWrap: true,
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final data = requests[index].data() as Map<String, dynamic>;
                final docId = requests[index].id;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text("Patient: ${data['patient_name'] ?? 'Unknown'}"),
                    subtitle: Text("Reason: ${data['reason'] ?? ''}"),
                    trailing: Wrap(
                      spacing: 10,
                      children: [
                        ElevatedButton(
                          onPressed: () => _reviewAppointment(context, docId, data),
                          child: const Text("Review"),
                        ),
                        OutlinedButton(
                          onPressed: () => _declineAppointment(docId, data),
                          child: const Text("Decline", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );

      // ------------------- Delete Old Sessions ------------------- //
      case MenuItem.deleteSessions:
  return StreamBuilder<QuerySnapshot>(
    stream: _scheduledSessionsStream(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(child: Text("No old sessions found."));
      }
      final sessions = snapshot.data!.docs;
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Delete Old ANC Sessions",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index].data() as Map<String, dynamic>;
                final docId = sessions[index].id;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(session['name'] ?? ''),
                    subtitle: Text(
                        "Date: ${DateFormat('yyyy-MM-dd').format((session['session_date'] as Timestamp).toDate())}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteSession(docId),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
      // ------------------- Delete Old Appointments ------------------- //
      case MenuItem.deleteAppointments:
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('scheduled_appointment')
        .orderBy('scheduled_datetime', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(child: Text("No old appointments found."));
      }
      final appointments = snapshot.data!.docs;
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Delete Old Appointments",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final app = appointments[index].data() as Map<String, dynamic>;
                final docId = appointments[index].id;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(app['patient_name'] ?? ''),
                    subtitle: Text(
                        "Doctor: ${app['assigned_doctor'] ?? ''} | Date: ${app['scheduled_datetime'] != null ? DateFormat('yyyy-MM-dd HH:mm').format((app['scheduled_datetime'] as Timestamp).toDate()) : ''}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteAppointment(docId),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
    }
  }
  // ------------------- Schedule Session Form ------------------- //
 Widget _buildScheduleSessionForm() {
  return Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => _isSchedulingMode = false),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Schedule ANC Session",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _selectedDate == null
                        ? "Pick Session Date"
                        : "Session Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}",
                  ),
                  onPressed: _pickDate,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Patient Table
              _patients.isEmpty
                  ? const Center(child: Text("No patients found for the selected date range."))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        columns: const [
                          DataColumn(label: Text("Reg No")),
                          DataColumn(label: Text("Name")),
                          DataColumn(label: Text("Next Visit")),
                          DataColumn(label: Text("Select")),
                        ],
                        rows: _patients.map((p) {
                          final isSelected = _selectedPatients.contains(p['id']);
                          return DataRow(cells: [
                            DataCell(Text(p['registration_number'] ?? "")),
                            DataCell(Text(p['name'] ?? "")),
                            DataCell(Text(DateFormat('yyyy-MM-dd').format(p['next_visit']))),
                            DataCell(Checkbox(
                              value: isSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedPatients.add(p['id']);
                                  } else {
                                    _selectedPatients.remove(p['id']);
                                  }
                                });
                              },
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.access_time),
                    label: Text(_sessionStart == null
                        ? "Pick Start Time"
                        : "Start: ${_sessionStart!.format(context)}"),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) setState(() => _sessionStart = picked);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    ),
                  ),
                  const SizedBox(width: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.access_time),
                    label: Text(_sessionEnd == null
                        ? "Pick End Time"
                        : "End: ${_sessionEnd!.format(context)}"),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) setState(() => _sessionEnd = picked);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Save Session"),
                  onPressed: _saveSession,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  // ------------------- Action Card ------------------- //
  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 3,
        child: Container(
          padding: const EdgeInsets.all(16),
          width: 250,
          height: 100,
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.blue),
              const SizedBox(width: 20),
              Flexible(
                child: Text(title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
