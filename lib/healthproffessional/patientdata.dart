import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  _PatientHomePageState createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _selectedPatient;
  String? _registrationNumber;

  Map<String, dynamic>? _personalData;
  Map<String, dynamic>? _medicalHistory;
  Map<String, dynamic>? _sessionData;

  String? _currentView;

  Future<List<Map<String, dynamic>>> _loadPatients() async {
    final snapshot = await FirebaseFirestore.instance.collection("patients").get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        "fullname": "${data["firstname"]} ${data["surname"]}",
        "registration_number": data["registration_number"],
        ...data,
      };
    }).toList();
  }

  
  Future<void> _fetchData(String regNo, String type) async {
    if (type == "patients") {
      final snap = await FirebaseFirestore.instance
          .collection("patients")
          .where("registration_number", isEqualTo: regNo)
          .get();
      if (snap.docs.isNotEmpty) _personalData = snap.docs.first.data();
             _personalData!.remove("createdAt");
    } else if (type == "anc_registers") {
      final snap = await FirebaseFirestore.instance
          .collection("anc_registers")
          .where("registration_number", isEqualTo: regNo)
          .get();
      if (snap.docs.isNotEmpty) {
        _medicalHistory = snap.docs.first.data();
        _medicalHistory!.remove("createdAt");
      }
    } else if (type == "session_data") {
      final snap = await FirebaseFirestore.instance
          .collection("session_data")
          .where("registration_number", isEqualTo: regNo)
          .get();
      if (snap.docs.isNotEmpty) {
        _sessionData = snap.docs.first.data();
        _sessionData!.remove("createdAt");
      }
    }

    setState(() {
      _currentView = type;
    });
  }

  // Timestamps to Dates
  String _formatValue(dynamic value) {
    if (value is Timestamp) {
      return DateFormat("yyyy-MM-dd").format(value.toDate());
    } else if (value is Map) {
      // map handling
      return value.entries.map((e) => "${e.key}: ${_formatValue(e.value)}").join(", ");
    } else {
      return value.toString();
    }
  }

  
  Widget _buildTable(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      return const Text("No data available");
    }

    final entries = data.entries.toList();
    return Table(
      border: TableBorder.all(color: Colors.grey.shade400, width: 0.5),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(3),
      },
      children: entries.map((e) {
        return TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
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

  // Print function
  Future<void> _printDocument(Map<String, dynamic>? data, String title) async {
    if (data == null) return;

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              children: data.entries.map((e) {
                return pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(e.key)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(_formatValue(e.value))),
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

  // Sidebar
  Widget _buildSidebar() {
    return ListView(
      children: [
        const DrawerHeader(
          child: Text(" Patient Data", style: TextStyle(fontSize: 20)),
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
                value: _selectedPatient,
                items: patients.map((p) {
                  return DropdownMenuItem<String>(
                    value: p["fullname"],
                    child: Text(p["fullname"]),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedPatient = val);
                  final patient = patients.firstWhere((p) => p["fullname"] == val);
                  _registrationNumber = patient["registration_number"];
                },
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.dashboard, color: Colors.black),
          title: const Text("Dashboard", style: TextStyle(color: Colors.black)),
          onTap: () {
            Navigator.pushReplacementNamed(context, '/admindashboard');
          },
        ),
        ListTile(
          leading: const Icon(Icons.person, color: Colors.black),
          title: const Text("Personal Data"),
          onTap: () => _fetchData(_registrationNumber!, "patients"),
        ),
        ListTile(
          leading: const Icon(Icons.healing, color: Colors.black),
          title: const Text("Medical History"),
          onTap: () => _fetchData(_registrationNumber!, "anc_registers"),
        ),
        ListTile(
          leading: const Icon(Icons.medical_services, color: Colors.black),
          title: const Text("ANC Session Data"),
          onTap: () => _fetchData(_registrationNumber!, "session_data"),
        ),
      ],
    );
  }

  // Content
  Widget _buildContent() {
    if (_currentView == "patients") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Personal Data", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          _buildTable(_personalData),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _printDocument(_personalData, "Personal Data"),
            child: const Text("Print"),
          ),
        ],
      );
    } else if (_currentView == "anc_registers") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Medical History", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          _buildTable(_medicalHistory),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _printDocument(_medicalHistory, "Medical History"),
            child: const Text("Print"),
          ),
        ],
      );
    } else if (_currentView == "session_data") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ANC Session Data", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          _buildTable(_sessionData),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _printDocument(_sessionData, "ANC Session Data"),
            child: const Text("Print"),
          ),
        ],
      );
    }

    return const Center(
      child: Text("Welcome to information center please Select a section from the sidebar",style: TextStyle(color: Colors.black),),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      key: _scaffoldKey,
      body: Row(
        children: [
          Container(width: 220, color: Colors.grey.shade100, child: _buildSidebar()),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: Image.asset("assets/images/patientdatabackg.jpg", fit: BoxFit.cover)),
                Container(color: Colors.black.withOpacity(0.2)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(child: _buildContent()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
