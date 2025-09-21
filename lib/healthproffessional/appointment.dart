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

  int specialAppointments = 0;
  int ancSessions = 0;

  MenuItem _selectedMenu = MenuItem.home;

  Future<void> _fetchPatientsForDate(DateTime date) async {
    final lowerBound = date.subtract(const Duration(days: 5));
    final upperBound = date.add(const Duration(days: 5));

    final sessionSnap = await FirebaseFirestore.instance
        .collection('session_data')
        .where('next_visit_date', isGreaterThanOrEqualTo: Timestamp.fromDate(lowerBound))
        .where('next_visit_date', isLessThanOrEqualTo: Timestamp.fromDate(upperBound))
        .get();

    List<Map<String, dynamic>> tempPatients = [];

    for (var doc in sessionSnap.docs) {
      final sessionData = doc.data();
      final regNo = sessionData['registration_number'] ?? '';
      final nextVisit = (sessionData['next_visit_date'] as Timestamp).toDate();

      final patientSnap = await FirebaseFirestore.instance
          .collection('patients')
          .where('registration_number', isEqualTo: regNo)
          .limit(1)
          .get();

      String name = '';
      if (patientSnap.docs.isNotEmpty) {
        name = patientSnap.docs.first['name'] ?? '';
      }

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

  Future<void> _saveSession() async {
    if (_selectedDate == null || _selectedPatients.isEmpty) return;

    final selectedData = _patients
        .where((p) => _selectedPatients.contains(p['id']))
        .map((p) => {
              "registration_number": p['registration_number'],
              "name": p['name'],
              "session_date": _selectedDate,
            })
        .toList();

    for (var entry in selectedData) {
      await FirebaseFirestore.instance.collection('ANC_session_register').add(entry);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Session saved successfully!")),
    );

    _printSummary(selectedData);
  }

  Future<void> _printSummary(List<Map<String, dynamic>> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("ANC Session Summary", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text("Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}"),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ["Reg No", "Name"],
                data: data.map((e) => [e['registration_number'], e['name']]).toList(),
              ),
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
                _buildSidebarItem(MenuItem.scheduleSession, "Schedule Antenatal Care", Icons.calendar_today),
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
        });
      },
    );
  }

  Widget _buildMainContent() {
    switch (_selectedMenu) {
      case MenuItem.home:
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildActionCard("Schedule Antenatal Care Session", Icons.calendar_today, () {
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

      case MenuItem.scheduleSession:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(onPressed: _pickDate, child: const Text("Pick Session Date")),
            const SizedBox(height: 20),
            if (_selectedDate != null) ...[
              Text("Patients around ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (_patients.isEmpty)
                const Text(
                  "No patients needing the session are available close to this date.",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                )
              else
                Column(
                  children: [
                    DataTable(
                      columns: const [
                        DataColumn(label: Text("Select")),
                        DataColumn(label: Text("Reg No")),
                        DataColumn(label: Text("Name")),
                        DataColumn(label: Text("Next Visit")),
                      ],
                      rows: _patients.map((p) {
                        return DataRow(
                          selected: _selectedPatients.contains(p['id']),
                          onSelectChanged: (selected) {
                            setState(() {
                              if (selected == true) {
                                _selectedPatients.add(p['id']);
                              } else {
                                _selectedPatients.remove(p['id']);
                              }
                            });
                          },
                          cells: [
                            DataCell(Checkbox(
                              value: _selectedPatients.contains(p['id']),
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
                            DataCell(Text(p['registration_number'])),
                            DataCell(Text(p['name'])),
                            DataCell(Text(DateFormat('yyyy-MM-dd').format(p['next_visit']))),
                          ],
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(onPressed: _saveSession, child: const Text("Save Session")),
                  ],
                ),
            ],
          ],
        );

      case MenuItem.scheduleSpecial:
        return const Text("Special Appointment scheduling screen (to be implemented)");

      case MenuItem.deleteSessions:
        return const Text("Delete old sessions screen (to be implemented)");

      case MenuItem.deleteAppointments:
        return const Text("Delete old appointments screen (to be implemented)");
    }
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        child: Container(
          width: 250,
          height: 120,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.blueAccent),
              const SizedBox(height: 10),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
