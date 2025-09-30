import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '/healthproffessional/patientdata.dart';

// doctor or midwife dashboard 
class DoctorHomePage extends StatefulWidget {
  const DoctorHomePage({super.key});

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  int _selectedIndex = 0;
  String? doctorName;
  String? doctorId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    if (doctorId == null) return;
    var snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(doctorId)
        .get();

    if (snap.exists) {
      setState(() {
        doctorName = "${snap['firstname']} ${snap['surname']}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: Colors.grey.shade100,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white12,
                    child: Icon(Icons.person, color: Colors.black, size: 35),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    doctorName ?? "Doctor",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                  ),
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home, color: Colors.black),
                selectedIcon: Icon(Icons.home, color: Colors.pinkAccent),
                label: Text("Home", style: TextStyle(color: Colors.black)),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.medical_services, color: Colors.black),
                selectedIcon: Icon(Icons.medical_services, color: Colors.pinkAccent),
                label: Text("Consultation", style: TextStyle(color: Colors.black)),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people, color: Colors.black),
                selectedIcon: Icon(Icons.people, color: Colors.pinkAccent),
                label: Text("Patient Data", style: TextStyle(color: Colors.black)),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.logout, color: Colors.black),
                selectedIcon: Icon(Icons.logout, color: Colors.red),
                label: Text("Logout", style: TextStyle(color: Colors.black)),
              ),
            ],
          ),

      //content
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue.shade50,
                  width: double.infinity,
                  child: Text(
                    _selectedIndex == 0
                        ? "Doctor Home"
                        : _selectedIndex == 1
                            ? "Consultation"
                            : _selectedIndex == 2
                                ? "Patient Data"
                                : "Logout",
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _getPageForIndex(_selectedIndex),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getPageForIndex(int index) {
    switch (index) {
      case 0:
        return _HomePage(doctorName: doctorName, doctorId: doctorId);
      case 1:
        return  ConsultationPage(doctorUid: doctorId??'');
      case 2:
        return const PatientDataPage( );
      case 3:
        FirebaseAuth.instance.signOut();
        Future.microtask(() =>
            Navigator.pushReplacementNamed(context, "/login"));
        return const Center(child: CircularProgressIndicator());
      default:
        return const Center(child: Text("Page not found"));
    }
  }
}

class _HomePage extends StatelessWidget {
  final String? doctorName;
  final String? doctorId;
  const _HomePage({this.doctorName, this.doctorId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Welcome Dr. ${doctorName ?? ''}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text("Your Scheduled Appointments:",
              style: TextStyle(fontSize: 18)),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('scheduled_appointment')
                  .where('doctor_uid', isEqualTo: doctorId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text("No appointments yet."));
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    var data = docs[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.event),
                        title: Text("Patient: ${data['patient_name']}"),
                        subtitle: Text(
                          "Date: ${DateFormat.yMMMd().format(data['scheduled_datetime'].toDate())}",
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

// consultation page
class ConsultationPage extends StatefulWidget {
  final String doctorUid;
  const ConsultationPage({super.key, required this.doctorUid});

  @override
  State<ConsultationPage> createState() => _ConsultationPageState();
}

class _ConsultationPageState extends State<ConsultationPage> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedPatientName;
  String? _selectedPatientRegNo;
  DateTime? _selectedVisitDate;

  final _symptomsController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _remarksController = TextEditingController();

  Future<List<Map<String, dynamic>>> _fetchPatients() async {
    final snapshot = await FirebaseFirestore.instance.collection('patients').get();
    return snapshot.docs.map((doc) => {
          'name': "${doc['firstname']} ${doc['surname']}",
          'registration_number': doc['registration_number'],
        }).toList();
  }

  Future<void> _saveConsultation() async {
    if (!_formKey.currentState!.validate() ||
        _selectedPatientName == null ||
        _selectedPatientRegNo == null ||
        _selectedVisitDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('consultation_data').add({
      'doctor_uid': widget.doctorUid,
      'patient_name': _selectedPatientName,
      'registration_number': _selectedPatientRegNo,
      'visit_date': _selectedVisitDate,
      'symptoms': _symptomsController.text,
      'medications': _medicationsController.text,
      'remarks': _remarksController.text,
      'created_at': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Consultation saved")),
    );

    setState(() {
      _selectedPatientName = null;
      _selectedPatientRegNo = null;
      _selectedVisitDate = null;
      _symptomsController.clear();
      _medicationsController.clear();
      _remarksController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchPatients(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final patients = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const Text("New Consultation", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                      return patients
                          .map((p) => p['name'] as String)
                          .where((name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (selection) {
                      setState(() {
                        _selectedPatientName = selection;
                        _selectedPatientRegNo = patients.firstWhere((p) => p['name'] == selection)['registration_number'];
                      });
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: "Patient Name",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                        ),
                        validator: (val) => val!.isEmpty ? "Enter patient name" : null,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Registration Number",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                    controller: TextEditingController(text: _selectedPatientRegNo ?? ""),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(

                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Visit Date",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _selectedVisitDate = picked);
                      }
                    },
                    controller: TextEditingController(
                      text: _selectedVisitDate != null
                          ? "${_selectedVisitDate!.year}-${_selectedVisitDate!.month}-${_selectedVisitDate!.day}"
                          : "",
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _symptomsController,
                    decoration: InputDecoration(
                      labelText: "Symptoms",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _medicationsController,
                    decoration: InputDecoration(
                      labelText: "Medications",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _remarksController,
                    decoration: InputDecoration(
                      labelText: "Remarks",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _saveConsultation,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                    child: const Text("Save Consultation", style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}



