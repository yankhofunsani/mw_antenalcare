import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ANCSessionPage extends StatefulWidget {
  const ANCSessionPage({super.key});

  @override
  _ANCSessionPageState createState() => _ANCSessionPageState();
}

class _ANCSessionPageState extends State<ANCSessionPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _gestAgeController = TextEditingController();
  final _fundalHeightController = TextEditingController();
  final _positionController = TextEditingController();
  final _fetalHeartController = TextEditingController();
  final _weightController = TextEditingController();
  final _bpController = TextEditingController();
  final _urineProtController = TextEditingController();
  final _remarksController = TextEditingController();
  final _signController = TextEditingController();
  final _spController = TextEditingController();
  final _fefcController = TextEditingController();
  final _nvpMotherController = TextEditingController();
  final _aztMotherController = TextEditingController();
  final _threeTcMotherController = TextEditingController();
  final _nvpBabyController = TextEditingController();

  // Dropdowns for Y/N
  String? _onCPT;
  String? _onART;

  final List<String> yesNoOptions = ['Y', 'N'];
  String? _selectedRegNumber;
  String? _patientName;
  List<String> _availableRegNumbers = [];

  // Dates
  late DateTime visitDate;
  late DateTime nextVisitDate;

  @override
  void initState() {
    super.initState();
    visitDate = DateTime.now();
    nextVisitDate = visitDate.add(const Duration(days: 28));
    _fetchRegistrationNumbers();
  }

  Future<void> _fetchRegistrationNumbers() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('patients').get();
      final numbers = snapshot.docs.map((doc) => doc['registration_number'].toString()).toList();
      setState(() {
        _availableRegNumbers = numbers;
      });
    } catch (e) {
      debugPrint("Error fetching registration numbers: $e");
    }
  }

  Future<void> _fetchPatientName(String regNumber) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('patients')
          .where('registration_number', isEqualTo: regNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        setState(() {
          _patientName = "${data['firstname']} ${data['surname']}";
        });
      } else {
        setState(() {
          _patientName = "Not found";
        });
      }
    } catch (e) {
      debugPrint("Error fetching patient name: $e");
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedRegNumber != null) {
      try {
        await FirebaseFirestore.instance.collection('session_data').add({
          "registration_number": _selectedRegNumber,
          "patient_name": _patientName,
          "visit": {
            "visit_date": visitDate.toIso8601String(),
            "gest_age": _gestAgeController.text,
            "fundal_height": _fundalHeightController.text,
            "position_presentation": _positionController.text,
            "fetal_heart": _fetalHeartController.text,
            "weight": _weightController.text,
            "bp": _bpController.text,
            "urine_prot": _urineProtController.text,
            "sp": _spController.text,
            "fefc": _fefcController.text,
            "nvp_mother": _nvpMotherController.text,
            "azt_mother": _aztMotherController.text,
            "3tc_mother": _threeTcMotherController.text,
            "nvp_baby": _nvpBabyController.text,
            "on_cpt": _onCPT,
            "on_art": _onART,
            "remarks": _remarksController.text,
            "next_visit_date": nextVisitDate.toIso8601String(),
            "sign": _signController.text,
          },
          "createdAt": FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session saved successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving session: $e')),
        );
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return SizedBox(
      width: 250,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (val) => val!.isEmpty ? "Required" : null,
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, Function(String?) onChanged) {
    return SizedBox(
      width: 250,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
        value: value,
        items: yesNoOptions.map((opt) {
          return DropdownMenuItem(value: opt, child: Text(opt));
        }).toList(),
        onChanged: onChanged,
        validator: (val) => val == null ? "Required" : null,
      ),
    );
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.local_hospital, color: Colors.blue, size: 40),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        "QUEEN ELIZABETH HOSPITAL",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                ListTile(
                  leading: const Icon(Icons.dashboard, color: Colors.black),
                  title: const Text("Dashboard", style: TextStyle(color: Colors.black)),
                  onTap: () {
                    Navigator.pushReplacementNamed(context, "/admindashboard");
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.assignment, color: Colors.black),
                  title: const Text("ANC Session Details", style: TextStyle(color: Colors.black)),
                  onTap: () {},
                ),
              ],
            ),
          ),
          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    const Text("ANC SESSION VISIT DETAILS",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(
                      "Visit Date: ${visitDate.day}/${visitDate.month}/${visitDate.year}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Next Visit Date: ${nextVisitDate.day}/${nextVisitDate.month}/${nextVisitDate.year}",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    SizedBox(
                      width: 250,
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Registration Number",
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedRegNumber,
                        items: _availableRegNumbers.map((num) {
                          return DropdownMenuItem(value: num, child: Text(num));
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedRegNumber = val;
                            _patientName = null;
                          });
                          if (val != null) {
                            _fetchPatientName(val);
                          }
                        },
                        validator: (val) => val == null ? "Required" : null,
                      ),
                    ),
                    if (_patientName != null)
                      Text("Patient: $_patientName",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),

                    _buildTextField("Gest. Age", _gestAgeController),
                    _buildTextField("Fundal Height", _fundalHeightController),
                    _buildTextField("Position & Presentation", _positionController),
                    _buildTextField("Fetal Heart", _fetalHeartController),
                    _buildTextField("Weight (kg)", _weightController),
                    _buildTextField("BP", _bpController),
                    _buildTextField("Urine Prot", _urineProtController),

                    const Divider(),
                    const Text("Medication & Supplements",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    _buildTextField("SP", _spController),
                    _buildTextField("Fe/Fc", _fefcController),
                    _buildTextField("NVP (Mother)", _nvpMotherController),
                    _buildTextField("AZT (Mother)", _aztMotherController),
                    _buildTextField("3TC (Mother)", _threeTcMotherController),
                    _buildTextField("NVP (Baby)", _nvpBabyController),

                    const Divider(),
                    const Text("Other Information",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    _buildDropdown("On CPT", _onCPT, (val) => setState(() => _onCPT = val)),
                    _buildDropdown("On ART", _onART, (val) => setState(() => _onART = val)),
                    _buildTextField("Remarks / Medications", _remarksController),
                    _buildTextField("Sign", _signController),

                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: const Text("Submit Session"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
