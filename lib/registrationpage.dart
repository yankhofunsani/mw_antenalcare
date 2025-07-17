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
        'sex': sex,
        'email': emailController.text.trim(),
        'username': usernameController.text.trim(),
        'village': villageController.text.trim(),
        'phone': phoneController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration Successful')),
      );
      Navigator.pushReplacementNamed(context, '/home');
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
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
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
      appBar: AppBar(title: Text("Registration Page"),
      backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              buildTextField("Firstname", firstnameController),
              buildTextField("Surname", surnameController),
              buildTextField("Age", ageController,
                  keyboardType: TextInputType.number),
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
                  border: OutlineInputBorder(),
                  labelText: 'Sex',
                ),
                validator: (value) =>
                    value == null ? 'Please select sex' : null,
              ),
              SizedBox(height: 8),
              buildTextField("Email", emailController,
                  keyboardType: TextInputType.emailAddress),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Password",
                ),
                validator: (value) =>
                    value == null || value.length < 6
                        ? 'Password must be at least 6 characters'
                        : null,
),SizedBox(height: 8),
             buildTextField("Username", usernameController),
              buildTextField("Home Village", villageController),
              buildTextField("Phone Number", phoneController,
                  keyboardType: TextInputType.phone),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                style:ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan                ),
                child: Text("Register")
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/home');
                },
                style:TextButton.styleFrom(
                  backgroundColor:Colors.cyan
                ),
                child: Text("Already have an account? Login"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
