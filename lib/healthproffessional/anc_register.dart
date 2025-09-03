import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ANCRegisterPage extends StatefulWidget {
  @override
  _ANCRegisterPageState createState() => _ANCRegisterPageState();
}

class _ANCRegisterPageState extends State<ANCRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _registrationNumberController = TextEditingController();
  DateTime? _lmpDate;
  DateTime? _eddDate;
  
  // Dropdown Y/N selections
  String? _cSection;
  String? _vacuumExtraction;
  String? _symphyisiotomy;
  String? _preEclampsia;
  String? _delivery;
  String? _abortion;
  String? _haemorrhage;
  String? _ageRisk;
  String? _heightRisk;


  String? _asthma;
  String? _hypertension;
  String? _diabetes;
  String? _epilepsy;
  String? _renalDisease;
  String? _fistulaRepair;
  String? _legSpineDeform;
  
  String? _multiplePregnancy;
  String? _syphilis;
  String? _hb1;
  String? _hb2;
  String? _cd4;
  String? _hepB;

  // Dropdown items
  final List<String> yesNoOptions = ['Y', 'N'];

  Future<void> _pickDate(BuildContext context, bool isLmp) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1980),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isLmp) {
          _lmpDate = picked;
        } else {
          _eddDate = picked;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('anc_registers').add({
          "facility_name": "QUEEN ELIZABETH CENTRAL HOSPITAL",
          "registration_number": _registrationNumberController.text,
          "lmp": _lmpDate?.toIso8601String(),
          "edd": _eddDate?.toIso8601String(),
          "obstetric_history": {
            "delivery": _delivery,
            "abortion": _abortion,
            "c_section": _cSection,
            "vacuum_extraction": _vacuumExtraction,
            "symphyisiotomy": _symphyisiotomy,
            "haemorrhage": _haemorrhage,
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
            "age_risk": _ageRisk,
          },
          "examination": {
            "height_risk": _heightRisk,
            "multiple_pregnancy": _multiplePregnancy,
            "syphilis": _syphilis,
            "hb1": _hb1,
            "hb2": _hb2,
            "cd4": _cd4,
            "hep_b": _hepB,
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

  Widget _buildDropdown(String label, String? value, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
      value: value,
      items: yesNoOptions.map((opt) {
        return DropdownMenuItem(value: opt, child: Text(opt));
      }).toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? "Required" : null,
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
            color: Colors.blue,
            child: Column(
              children: [
                SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_hospital, color: Colors.white, size: 40),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        "QUEEN ELIZABETH HOSPITAL",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 50),
                ListTile(
                  leading: Icon(Icons.dashboard, color: Colors.white),
                  title: Text("Dashboard", style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pushReplacementNamed(context, "/admindashboard");
                  },
                ),
                ListTile(
                  leading: Icon(Icons.assignment, color: Colors.white),
                  title: Text("ANC Register", style: TextStyle(color: Colors.white)),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Facility: QUEEN ELIZABETH CENTRAL HOSPITAL",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _registrationNumberController,
                      decoration: InputDecoration(
                          labelText: "Registration Number", border: OutlineInputBorder()),
                      validator: (val) => val!.isEmpty ? "Required" : null,
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: Text(
                                "LMP: ${_lmpDate != null ? _lmpDate!.toLocal().toString().split(' ')[0] : 'Select'}"),
                            trailing: Icon(Icons.date_range),
                            onTap: () => _pickDate(context, true),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: Text(
                                "EDD: ${_eddDate != null ? _eddDate!.toLocal().toString().split(' ')[0] : 'Select'}"),
                            trailing: Icon(Icons.date_range),
                            onTap: () => _pickDate(context, false),
                          ),
                        ),
                      ],
                    ),
                    Divider(thickness: 2),
                    Text("Obstetric History", style: TextStyle(fontWeight: FontWeight.bold)),
                    _buildDropdown("Delivery", _delivery, (val) => setState(() => _delivery = val)),
                    _buildDropdown("Abortion", _abortion, (val) => setState(() => _abortion = val)),
                    _buildDropdown("C-Section", _cSection, (val) => setState(() => _cSection = val)),
                    _buildDropdown("Vacuum Extraction", _vacuumExtraction, (val) => setState(() => _vacuumExtraction = val)),
                    _buildDropdown("Symphyisiotomy", _symphyisiotomy, (val) => setState(() => _symphyisiotomy = val)),
                    _buildDropdown("Haemorrhage", _haemorrhage, (val) => setState(() => _haemorrhage = val)),
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
                    _buildDropdown("Age Risk", _ageRisk, (val) => setState(() => _ageRisk = val)),
                    Divider(thickness: 2),
                    Text("Examination", style: TextStyle(fontWeight: FontWeight.bold)),
                    _buildDropdown("Height Risk", _heightRisk, (val) => setState(() => _heightRisk = val)),
                    _buildDropdown("Multiple Pregnancy", _multiplePregnancy, (val) => setState(() => _multiplePregnancy = val)),
                    _buildDropdown("Syphilis", _syphilis, (val) => setState(() => _syphilis = val)),
                    _buildDropdown("Hb1", _hb1, (val) => setState(() => _hb1 = val)),
                    _buildDropdown("Hb2", _hb2, (val) => setState(() => _hb2 = val)),
                    _buildDropdown("CD4", _cd4, (val) => setState(() => _cd4 = val)),
                    _buildDropdown("Hep B", _hepB, (val) => setState(() => _hepB = val)),
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
