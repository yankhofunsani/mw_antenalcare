import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;

  // Personal info
  String? firstName;
  String? age;
  String? email;
  String? regNumber;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  // Obstetric history 
  Map<String, dynamic> obstetricHistory = {};

  @override
  void initState() {
    super.initState();
    _fetchPatientData();
  }

  Future<void> _fetchPatientData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final emailAddress = currentUser.email;

    if (emailAddress != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('patients')
          .where('email', isEqualTo: emailAddress)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final patientData = snapshot.docs.first.data();
        setState(() {
          firstName = patientData['firstname'];
          age = patientData['age']?.toString();
          email = patientData['email'];
          regNumber = patientData['registration_number'];

          _phoneController.text = patientData['phone'] ?? '';
          _villageController.text = patientData['village'] ?? '';
          _usernameController.text = patientData['username'] ?? '';
        });

        if (regNumber != null) {
          final obstetricSnap = await FirebaseFirestore.instance
              .collection('anc_registers')
              .where('registration_number', isEqualTo: regNumber)
              .limit(1)
              .get();

          if (obstetricSnap.docs.isNotEmpty) {
            final data = obstetricSnap.docs.first.data();
            final obstetric_history = data["obstetric_history"] as Map<String, dynamic>;

            setState(() {
              obstetricHistory = {
                'Abortion': obstetric_history['abortion'].toString(),
                'C-Section': obstetric_history['c_section'].toString(),
                'Delivery': obstetric_history['delivery'].toString(),
                'Haemorrhage': obstetric_history['haemorrhage'].toString(),
                'Pre-eclampsia': obstetric_history['pre_eclampsia'].toString(),
                'Symphyisiotomy': obstetric_history['symphyisiotomy'].toString(),
                'Vacuum Extraction': obstetric_history['vacuum_extraction'].toString(),
              };
            });
          }
        }
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updatePatientData() async {
    if (email == null) return;

    final patientQuery = await FirebaseFirestore.instance
        .collection('patients')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (patientQuery.docs.isNotEmpty) {
      final patientDoc = patientQuery.docs.first.reference;

      await patientDoc.update({
        'phone': _phoneController.text,
        'village': _villageController.text,
        'username': _usernameController.text,
      });
    }

    final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (userQuery.docs.isNotEmpty) {
      final userDoc = userQuery.docs.first.reference;

      await userDoc.update({
        'username': _usernameController.text,
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My profile'),
        backgroundColor: Colors.grey.shade200,
        leading: const Icon(Icons.person, color: Colors.black)
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Personal Information",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          _buildReadOnlyField(Icons.person, "First Name",
                              firstName ?? "N/A"),
                          _buildReadOnlyField(Icons.cake, "Age", age ?? "N/A"),
                          _buildReadOnlyField(
                              Icons.email, "Email", email ?? "N/A"),
                          _buildReadOnlyField(Icons.badge,
                              "Registration No.", regNumber ?? "N/A"),
                          _buildEditableField(
                              Icons.phone, "Phone Number", _phoneController),
                          _buildEditableField(
                              Icons.home, "Village", _villageController),
                          _buildEditableField(
                              Icons.account_circle, "Username", _usernameController),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _updatePatientData,
                            icon: const Icon(Icons.save),
                            label: const Text("Save Changes"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pinkAccent,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Obstetric History
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Obstetric History",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          isWide
                              ? GridView.count(
                                  shrinkWrap: true,
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 4,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: obstetricHistory.entries
                                      .map((e) => _buildHistoryField(e.key, e.value))
                                      .toList(),
                                )
                              : Column(
                                  children: obstetricHistory.entries
                                      .map((e) => _buildHistoryField(e.key, e.value))
                                      .toList(),
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildReadOnlyField(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.pinkAccent),
      title: Text(label),
      subtitle: Text(value),
    );
  }

  Widget _buildEditableField(
      IconData icon, String label, TextEditingController controller) {
    return ListTile(
      leading: Icon(icon, color: Colors.pinkAccent),
      title: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _buildHistoryField(String label, dynamic value) {
    final Map<String, IconData> historyIcons = {
      'Abortion': Icons.block,
      'C-Section': Icons.medical_services,
      'Delivery': Icons.pregnant_woman,
      'Haemorrhage': Icons.bloodtype,
      'Pre-eclampsia': Icons.warning,
      'Symphyisiotomy': Icons.healing,
      'Vacuum Extraction': Icons.local_hospital,
    };

    return ListTile(
      leading: Icon(historyIcons[label] ?? Icons.info,
          color: Colors.pinkAccent),
      title: Text(label),
      subtitle: Text(value?.toString() ?? "N/A"),
    );
  }
}
