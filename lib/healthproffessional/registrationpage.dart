import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  String? sex;
  final List<String> sexOptions = ['Male', 'Female'];

  final firstnameController = TextEditingController();
  final surnameController = TextEditingController();
  final ageController = TextEditingController();
  final roleController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController = TextEditingController();
  final villageController = TextEditingController();
  final phoneController = TextEditingController();

  Future<void> _sendEmail(String email, String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse("http://10.1.24.35:3000/send-credentials"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        print("Email sent successfully");
      } else {
        print("Email failed: ${response.body}");
      }
    } catch (e) {
      print("Email error: $e");
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final existing = await FirebaseFirestore.instance
            .collection('patients')
            .where('email', isEqualTo: emailController.text.trim())
            .get();

        if (existing.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Patient with this email already exists')),
          );
          return;
        }

        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        String uid = userCredential.user!.uid;

        // Registration number
        final patientSnap =
            await FirebaseFirestore.instance.collection('patients').get();
        int nextNumber = patientSnap.docs.length + 1;
        String regNo = nextNumber.toString().padLeft(3, '0');

        // Save user in Firestore users collection
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'firstname': firstnameController.text.trim(),
          'surname': surnameController.text.trim(),
          'age': ageController.text.trim(),
          'role': roleController.text.trim(),
          'sex': sex,
          'email': emailController.text.trim(),
          'username': usernameController.text.trim(),
          'village': villageController.text.trim(),
          'phone': phoneController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Save in patients collection
        if (roleController.text.trim().toLowerCase() == "patient") {
          await FirebaseFirestore.instance.collection('patients').doc(uid).set({
            'registration_number': regNo,
            'firstname': firstnameController.text.trim(),
            'surname': surnameController.text.trim(),
            'age': ageController.text.trim(),
            'sex': sex,
            'email': emailController.text.trim(),
            'username': usernameController.text.trim(),
            'village': villageController.text.trim(),
            'phone': phoneController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // Send credentials email
        if (emailController.text.isNotEmpty) {
          await _sendEmail(
            emailController.text.trim(),
            usernameController.text.trim(),
            passwordController.text.trim(),
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration Successful - Reg No: $regNo')),
        );

        Navigator.pushReplacementNamed(context, '/admindashboard');
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Auth Error: ${e.message}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          labelText: label,
        ),
        validator: (value) =>
            value == null || value.isEmpty ? 'Please enter $label' : null,
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
            width: 250,
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DrawerHeader(
                  child: Text(
                    "QUEEN ELIZABETH HOSPITAL",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text("Dashboard"),
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/admindashboard');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_add),
                  title: const Text("Register User"),
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/register');
                  },
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Register User",
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            buildTextField("Firstname", firstnameController),
                            buildTextField("Surname", surnameController),
                            buildTextField("Age", ageController,
                                keyboardType: TextInputType.number),
                            buildTextField("Role", roleController),
                            DropdownButtonFormField<String>(
                              value: sex,
                              items: sexOptions
                                  .map((option) => DropdownMenuItem(
                                        value: option,
                                        child: Text(option),
                                      ))
                                  .toList(),
                              onChanged: (value) => setState(() => sex = value),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                labelText: 'Sex',
                              ),
                              validator: (value) =>
                                  value == null ? 'Please select sex' : null,
                            ),
                            buildTextField("Email", emailController,
                                keyboardType: TextInputType.emailAddress),
                            TextFormField(
                              controller: passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                labelText: "Password",
                              ),
                              validator: (value) => value == null || value.length < 6
                                  ? 'Password must be at least 6 characters'
                                  : null,
                            ),
                            buildTextField("Username", usernameController),
                            buildTextField("Home Village", villageController),
                            buildTextField("Phone Number", phoneController,
                                keyboardType: TextInputType.phone),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade600,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 14),
                              ),
                              child: const Text("Register",
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
