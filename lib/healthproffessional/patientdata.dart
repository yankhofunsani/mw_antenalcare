import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

//patient data display
class PatientDataPage extends StatefulWidget {
  const PatientDataPage({super.key});

  @override
  State<PatientDataPage> createState() => _PatientDataPageState();
}

class _PatientDataPageState extends State<PatientDataPage> {
  String? _selectedPatientId;
  String? _selectedPatientName;
  String? _selectedSection;

  Map<String, dynamic>? _personalData;
  Map<String, dynamic>? _medicalHistory;
  Map<String, dynamic>? _sessionData;

  // Fetch patient data based on section
  Future<void> _fetchData(String patientId, String section) async {
    if (section == "patients") {
      final snap = await FirebaseFirestore.instance
          .collection("patients")
          .doc(patientId)
          .get();
      if (snap.exists) {
        _personalData = snap.data();
        _personalData!.remove("createdAt");
      }
    } else if (section == "anc_registers") {
      final snap = await FirebaseFirestore.instance
          .collection("anc_registers")
          .where("registration_number",
              isEqualTo: _personalData?['registration_number'])
          .get();
      if (snap.docs.isNotEmpty) {
        _medicalHistory = snap.docs.first.data();
        _medicalHistory!.remove("createdAt");
      }
    } else if (section == "session_data") {
      final snap = await FirebaseFirestore.instance
          .collection("session_data")
          .where("registration_number",
              isEqualTo: _personalData?['registration_number'])
          .get();
      if (snap.docs.isNotEmpty) {
        _sessionData = snap.docs.first.data();
        _sessionData!.remove("createdAt");
      }
    }
    setState(() {});
  }

  // Format helper
  String _formatValue(dynamic value) {
    if (value is Timestamp) {
      return DateFormat("yyyy-MM-dd").format(value.toDate());
    } else if (value is Map) {
      return value.entries
          .map((e) => "${e.key}: ${_formatValue(e.value)}")
          .join(", ");
    } else {
      return value.toString();
    }
  }

  // Build table
  Widget _buildTable(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      return const Text("No data available");
    }
    return Table(
      border: TableBorder.all(color: Colors.grey.shade400, width: 0.5),
      columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
      children: data.entries.map((e) {
        return TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(e.key,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(_formatValue(e.value)),
            ),
          ],
        );
      }).toList(),
    );
  }

  // PDF print
  Future<void> _printDocument(Map<String, dynamic>? data, String title) async {
    if (data == null) return;

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title,
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              children: data.entries.map((e) {
                return pw.TableRow(
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(e.key)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(_formatValue(e.value))),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<List<Map<String, dynamic>>> _loadPatients() async {
    final snapshot = await FirebaseFirestore.instance.collection("patients").get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        "id": doc.id,
        "fullname": "${data["firstname"]} ${data["surname"]}",
        "registration_number": data["registration_number"],
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? activeData;
    String header = "Select a patient and data type";

    if (_selectedSection == "patients") {
      activeData = _personalData;
      header = "Personal Data of ${_selectedPatientName ?? ''}";
    } else if (_selectedSection == "anc_registers") {
      activeData = _medicalHistory;
      header = "Medical History of ${_selectedPatientName ?? ''}";
    } else if (_selectedSection == "session_data") {
      activeData = _sessionData;
      header = "ANC Session Data of ${_selectedPatientName ?? ''}";
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
              child: Image.asset("assets/images/patientdatabackg.jpg",
                  fit: BoxFit.cover)),
          Container(color: Colors.black.withOpacity(0.2)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(header,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Patient selector and section
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _loadPatients(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      final patients = snapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: "Select Patient"),
                            value: _selectedPatientId,
                            items: patients.map((p) {
                              return DropdownMenuItem<String>(
                                value: p["id"],
                                child: Text(p["fullname"]),
                              );
                            }).toList(),
                            onChanged: (id) async {
                              setState(() {
                                _selectedPatientId = id;
                                _selectedPatientName = patients
                                    .firstWhere((p) => p["id"] == id)["fullname"];
                                _personalData = null;
                                _medicalHistory = null;
                                _sessionData = null;
                              });
                              if (_selectedSection != null) {
                                await _fetchData(_selectedPatientId!, _selectedSection!);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: "Select Section"),
                            value: _selectedSection,
                            items: const [
                              DropdownMenuItem(value: "patients", child: Text("Personal Data")),
                              DropdownMenuItem(value: "anc_registers", child: Text("Medical History")),
                              DropdownMenuItem(value: "session_data", child: Text("ANC Session Data")),
                            ],
                            onChanged: (section) async {
                              setState(() {
                                _selectedSection = section;
                                _personalData = null;
                                _medicalHistory = null;
                                _sessionData = null;
                              });
                              if (_selectedPatientId != null) {
                                await _fetchData(_selectedPatientId!, _selectedSection!);
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildTable(activeData),

                  if (activeData != null) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _printDocument(activeData, header),
                      child: const Text("Print"),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//
class PatientSidebar extends StatefulWidget {
  final void Function(String regNo, String patientName, String section)
      onSelectionChanged;

  const PatientSidebar({super.key, required this.onSelectionChanged});

  @override
  State<PatientSidebar> createState() => _PatientSidebarState();
}

class _PatientSidebarState extends State<PatientSidebar> {
  String? _selectedRegNo;
  String? _selectedName;

  Future<List<Map<String, dynamic>>> _loadPatients() async {
    final snapshot = await FirebaseFirestore.instance.collection("patients").get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        "fullname": "${data["firstname"]} ${data["surname"]}",
        "registration_number": data["registration_number"],
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const DrawerHeader(
          child: Text("Patient Data", style: TextStyle(fontSize: 20)),
        ),

        FutureBuilder<List<Map<String, dynamic>>>(
          future: _loadPatients(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final patients = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Select Patient"),
                value: _selectedRegNo,
                items: patients.map((p) {
                  return DropdownMenuItem<String>(
                    value: p["registration_number"],
                    child: Text(p["fullname"]),
                  );
                }).toList(),
                onChanged: (regNo) {
                  setState(() {
                    _selectedRegNo = regNo;
                    _selectedName = patients.firstWhere((p) => p["registration_number"] == regNo)["fullname"];
                  });
                },
              ),
            );
          },
        ),

        const Divider(),
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text("Personal Data"),
          onTap: () {
            if (_selectedRegNo != null && _selectedName != null) {
              widget.onSelectionChanged(_selectedRegNo!, _selectedName!, "patients");
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.healing),
          title: const Text("Medical History"),
          onTap: () {
            if (_selectedRegNo != null && _selectedName != null) {
              widget.onSelectionChanged(_selectedRegNo!, _selectedName!, "anc_registers");
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.medical_services),
          title: const Text("ANC Session Data"),
          onTap: () {
            if (_selectedRegNo != null && _selectedName != null) {
              widget.onSelectionChanged(_selectedRegNo!, _selectedName!, "session_data");
            }
          },
        ),

        const Divider(),
        ListTile(
          leading: const Icon(Icons.dashboard),
          title: const Text("Dashboard"),
          onTap: () {
            Navigator.pushReplacementNamed(context, "/admindashboard");
          },
        ),
      ],
    );
  }
}

/// homepage with side bar
class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 220,
            color: Colors.grey.shade100,
            child: PatientSidebar(
              onSelectionChanged: (regNo, name, section) {
                setState(() {
                 });
              },
            ),
          ),

          // Main content
          Expanded(
            child: PatientDataPage( ) 
            ),
        ],
      ),
    );
  }
}