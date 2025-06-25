import 'package:flutter/material.dart';

class RegistrationPage extends StatefulWidget {
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
  final usernameController = TextEditingController();
  final villageController = TextEditingController();
  final phoneController = TextEditingController();

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Registration Successful')));
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
              buildTextField("Username", usernameController),
              buildTextField("Home Village", villageController),
              buildTextField("Phone Number", phoneController,
                  keyboardType: TextInputType.phone),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text("Register"),
                style:ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan                )
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
