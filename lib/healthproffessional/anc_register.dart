import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ANCRegisterPage extends StatefulWidget {
  const ANCRegisterPage({super.key});

  @override
  _ANCRegisterPageState createState() => _ANCRegisterPageState();
}

class _ANCRegisterPageState extends State<ANCRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _deliveryController = TextEditingController();
  final _abortionController = TextEditingController();
  final _hemorrhageController = TextEditingController();
  final _ageRiskController = TextEditingController();
  final _heightController = TextEditingController();
  final _syphilisController = TextEditingController();
  final _hb1Controller = TextEditingController();
  final _hb2Controller = TextEditingController();
  final _cd4Controller = TextEditingController();
  final _hepBController = TextEditingController();

  DateTime? _lmpDate;
  DateTime? _eddDate;

  // Dropdown Y/N selections
  String? _cSection;
  String? _vacuumExtraction;
  String? _symphyisiotomy;
  String? _preEclampsia;

  String? _asthma;
  String? _hypertension;
  String? _diabetes;
  String? _epilepsy;
  String? _renalDisease;
  String? _fistulaRepair;
  String? _legSpineDeform;
  String? _multiplePregnancy;

  final List<String> yesNoOptions = ['Y', 'N'];

  // Registration dropdown
  String? _selectedRegNumber;
  String? _patientName;
  List<String> _availableRegNumbers = [];

  @override
  void initState() {
    super.initState();
    _fetchRegistrationNumbers();
  }

  Future<void> _fetchRegistrationNumbers() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('patients').get();
      final numbers = snapshot.docs
          .map((doc) => doc['registration_number'].toString())
          .toList();
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

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1980),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _lmpDate = picked;
        _eddDate = DateTime(picked.year, picked.month + 9, picked.day);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedRegNumber != null) {
      try {
        await FirebaseFirestore.instance.collection('anc_registers').add({
          "facility_name": "QUEEN ELIZABETH CENTRAL HOSPITAL",
          "registration_number": _selectedRegNumber,
          "patient_name": _patientName,
          "lmp": _lmpDate?.toIso8601String(),
          "edd": _eddDate?.toIso8601String(),
          "obstetric_history": {
            "delivery": _deliveryController.text,
            "abortion": _abortionController.text,
            "c_section": _cSection,
            "vacuum_extraction": _vacuumExtraction,
            "symphyisiotomy": _symphyisiotomy,
            "haemorrhage": _hemorrhageController.text,
            "pre_eclampsia": _preEclampsia,
          },
          "medical_history": {
            "asthma": _asthma,
            "hypertension": _hypertension,
            "diabetes": _diabetes,
            "epilepsy": _epilepsy,
            "renal_disease": _renalDisease,
            "fistula_repair": _fistulaRepair,
            "leg_spine_deform": _legSpineDeform,
            "age_risk": _ageRiskController.text,
          },
          "examination": {
            "height": _heightController.text,
            "multiple_pregnancy": _multiplePregnancy,
            "syphilis": _syphilisController.text,
            "hb1": _hb1Controller.text,
            "hb2": _hb2Controller.text,
            "cd4": _cd4Controller.text,
            "hep_b": _hepBController.text,
          },
          "createdAt": FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Form submitted successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving form: $e')),
        );
      }
    }
  }

  Widget _buildDropdown(
      String label, String? value, Function(String?) onChanged) {
    return SizedBox(
      width: 250,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
        value: value,
        items: yesNoOptions
            .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
            .toList(),
        onChanged: onChanged,
        validator: (val) => val == null ? "Required" : null,
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return SizedBox(
      width: 250,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
        validator: (val) => val!.isEmpty ? "Required" : null,
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
                SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_hospital, color: Colors.blue, size: 40),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        "QUEEN ELIZABETH HOSPITAL",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 50),
                ListTile(
                  leading: Icon(Icons.dashboard, color: Colors.black),
                  title: Text("Dashboard", style: TextStyle(color: Colors.black)),
                  onTap: () {
                    Navigator.pushReplacementNamed(context, "/admindashboard");
                  },
                ),
                ListTile(
                  leading: Icon(Icons.assignment, color: Colors.black),
                  title: Text("ANC Register", style: TextStyle(color: Colors.black)),
                  onTap: () {},
                ),
              ],
            ),
          ),
          // Main Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    Text("ANC REGISTER DETAILS FORM",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    SizedBox(
                      width: 250,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: "Registration Number",
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedRegNumber,
                        items: _availableRegNumbers
                            .map((num) => DropdownMenuItem(
                                  value: num,
                                  child: Text(num),
                                ))
                            .toList(),
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
                      Text(
                        "Patient: $_patientName",
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),

                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: Text(
                                "LMP: ${_lmpDate != null ? _lmpDate!.toLocal().toString().split(' ')[0] : 'Select'}"),
                            trailing: Icon(Icons.date_range),
                            onTap: () => _pickDate(context),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: Text(
                                "EDD: ${_eddDate != null ? _eddDate!.toLocal().toString().split(' ')[0] : 'Auto'}"),
                          ),
                        ),
                      ],
                    ),

                    Divider(thickness: 2),
                    Text("Obstetric History",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    _buildTextField("Delivery", _deliveryController),
                    _buildTextField("Abortion", _abortionController),
                    _buildDropdown("C-Section", _cSection, (val) => setState(() => _cSection = val)),
                    _buildDropdown("Vacuum Extraction", _vacuumExtraction, (val) => setState(() => _vacuumExtraction = val)),
                    _buildDropdown("Symphyisiotomy", _symphyisiotomy, (val) => setState(() => _symphyisiotomy = val)),
                    _buildTextField("Haemorrhage", _hemorrhageController),
                    _buildDropdown("Pre-Eclampsia", _preEclampsia, (val) => setState(() => _preEclampsia = val)),

                    Divider(thickness: 2),
                    Text("Medical History", style: TextStyle(fontWeight: FontWeight.bold)),
                    _buildDropdown("Asthma", _asthma, (val) => setState(() => _asthma = val)),
                    _buildDropdown("Hypertension", _hypertension, (val) => setState(() => _hypertension = val)),
                    _buildDropdown("Diabetes", _diabetes, (val) => setState(() => _diabetes = val)),
                    _buildDropdown("Epilepsy", _epilepsy, (val) => setState(() => _epilepsy = val)),
                    _buildDropdown("Renal Disease", _renalDisease, (val) => setState(() => _renalDisease = val)),
                    _buildDropdown("Fistula Repair", _fistulaRepair, (val) => setState(() => _fistulaRepair = val)),
                    _buildDropdown("Leg/Spine Deformity", _legSpineDeform, (val) => setState(() => _legSpineDeform = val)),
                    _buildTextField("Age Risk", _ageRiskController),

                    Divider(thickness: 2),
                    Text("Examination", style: TextStyle(fontWeight: FontWeight.bold)),
                    _buildTextField("Height", _heightController),
                    _buildDropdown("Multiple Pregnancy", _multiplePregnancy, (val) => setState(() => _multiplePregnancy = val)),
                    _buildTextField("Syphilis", _syphilisController),
                    _buildTextField("HB1", _hb1Controller),
                    _buildTextField("HB2", _hb2Controller),
                    _buildTextField("CD4", _cd4Controller),
                    _buildTextField("HEP B", _hepBController),

                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: Text("Submit"),
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
