import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Register the user with email and password
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        String uid = userCredential.user!.uid;
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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration Successful')),
        );
        Navigator.pushReplacementNamed(context, '/admindashboard');
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
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
                    "QTECH ANTENATAL CARE",
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
                    Navigator.pushReplacementNamed(context, '/registration');
                  },
                ),
              ],
            ),
          ),

          // CONTENT AREA
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Register User",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
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
                              onChanged: (value) =>
                                  setState(() => sex = value),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                labelText: 'Sex',
                              ),
                              validator: (value) =>
                                  value == null ? 'Please select sex' : null,
                            ),
                            const SizedBox(height: 8),
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
                              validator: (value) => value == null ||
                                      value.length < 6
                                  ? 'Password must be at least 6 characters'
                                  : null,
                            ),
                            const SizedBox(height: 8),
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
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                    context, '/admindashboard');
                              },
                              child: const Text(
                                "Already have an account? Login",
                                style: TextStyle(color: Colors.grey)
                              ),
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
