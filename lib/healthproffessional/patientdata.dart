import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  _PatientHomePageState createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _currentView;
  Map<String, dynamic>? _documentData;

  // Sidebar
  Widget _buildSidebar() {
    return ListView(
      children: [
        const DrawerHeader(
          child: Text(
            " Patient data",
            style: TextStyle(color: Colors.black, fontSize: 20),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.person, color: Colors.black),
          title: const Text("Patient Data", style: TextStyle(color: Colors.black)),
          onTap: () {
            setState(() => _currentView = 'cards');
          },
        ),
        ListTile(
          leading: const Icon(Icons.dashboard, color: Colors.black),
          title: const Text("Dashboard", style: TextStyle(color: Colors.black)),
          onTap: () {
            Navigator.pushReplacementNamed(context, '/admindashboard');
          },
        ),
      ],
    );
  }

  // main content
  Widget _buildCardsView(double width) {
    return Center(
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: [
          _buildCard("Personal Data", () => _fetchPatientData("patients"), width),
          _buildCard("Medical History", () => _fetchPatientData("anc_registers"), width),
          _buildCard("ANC Session Data", () => _fetchPatientData("session_data"), width),
        ],
      ),
    );
  }

  Widget _buildCard(String title, VoidCallback onTap, double width) {
    double cardWidth = width < 500 ? width * 0.8 : 250;
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 6,
        color: Colors.white.withOpacity(0.85), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: cardWidth,
          height: 150,
          child: Center(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  // Fetch patient data
  Future<void> _fetchPatientData(String collection) async {
    final nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Enter Patient Name"),
        content: TextField(controller: nameController),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final query = await FirebaseFirestore.instance
                  .collection(collection)
                  .where("firstname", isEqualTo: nameController.text.trim().split(" ").first)
                  .get();

              if (query.docs.isNotEmpty) {
                setState(() {
                  _documentData = query.docs.first.data();
                  _currentView = collection;
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Patient not found")),
                );
              }
            },
            child: const Text("Search"),
          ),
        ],
      ),
    );
  }

  // Document
  Widget _buildDataView() {
    if (_documentData == null) return const Center(child: Text("No Data Found"));

    return SingleChildScrollView(
      child: Card(
        color: Colors.white.withOpacity(0.9),
        elevation: 6,
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentView == "patients"
                    ? "Personal Data"
                    : _currentView == "anc_registers"
                        ? "Medical History"
                        : "ANC Session Data",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              ..._documentData!.entries.map((entry) {
                if (_currentView == "patients" &&
                    (entry.key == "firstname" || entry.key == "surname")) {
                  return const SizedBox.shrink(); 
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text("${entry.key}: ${entry.value}"),
                );
              }),
              if (_currentView == "patients")
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    "Full Name: ${_documentData!["firstname"]} ${_documentData!["surname"]}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => _currentView = 'cards'),
                    child: const Text("Back"),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _printDocument,
                    child: const Text("Print"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Print results
  Future<void> _printDocument() async {
    if (_documentData == null) return;

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              _currentView == "patients"
                  ? "Personal Data"
                  : _currentView == "anc_registers"
                      ? "Medical History"
                      : "ANC Session Data",
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.Divider(),
            ..._documentData!.entries.map(
              (e) => pw.Text("${e.key}: ${e.value}"),
            ),
            if (_currentView == "patients")
              pw.Text("Full Name: ${_documentData!["firstname"]} ${_documentData!["surname"]}"),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      key: _scaffoldKey,
      body: Row(
        children: [
          Container(
            width: 220,
            color:Colors.grey.shade100,
            child: _buildSidebar(),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    "assets/images/patientdatabackg.jpg",
                    fit: BoxFit.cover,
                  ),
                ),
                Container(color: Colors.black.withOpacity(0.2)), 
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _currentView == null || _currentView == 'cards'
                      ? _buildCardsView(screenWidth)
                      : _buildDataView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
