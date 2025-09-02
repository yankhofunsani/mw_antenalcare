import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mw_antenatalcare/patient/mainpage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String errorMessage = '';
  bool isLoading = false;

  Future<void> loginUser() async {
    setState(() {
      errorMessage = '';
      isLoading = true;
    });

    try {
      String identifier = identifierController.text.trim();
      String password = passwordController.text.trim();
      String email = identifier;

      // Convert username → email if needed
      if (!identifier.contains('@')) {
        final result = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: identifier)
            .limit(1)
            .get();

        if (result.docs.isEmpty) {
          throw FirebaseAuthException(
              code: 'user-not-found', message: 'Username not found.');
        }

        email = result.docs.first['email'];
      }

      // Firebase sign in
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        // fetch role from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        String role = userDoc['role'] ?? 'patient';

        if (role == 'patient') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => MainPage()),
          );
        } else if (role == 'clerk') {
          Navigator.pushReplacementNamed(context, '/admindashboard');
        } else if (role == 'doctor' || role == 'midwife') {
          Navigator.pushReplacementNamed(context, '/doctorhome');
        } else {
          setState(() {
            errorMessage = 'Role not recognized. Contact admin.';
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? 'Login failed';
      });
    } catch (e) {
      setState(() {
        errorMessage = 'An unexpected error occurred. $e';
      });
      //print('Login error: $e');
      //print(stack);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey.shade700),
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 6,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_hospital,
                      size: 60, color: Colors.blueAccent),
                  const SizedBox(height: 12),
                  const Text(
                    " QTECH Antenatal Care System",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  buildTextField(
                    label: "Username or Email",
                    icon: Icons.person,
                    controller: identifierController,
                  ),
                  const SizedBox(height: 16),
                  buildTextField(
                    label: "Password",
                    icon: Icons.lock,
                    controller: passwordController,
                    obscure: true,
                  ),
                  const SizedBox(height: 16),
                  if (errorMessage.isNotEmpty)
                    Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : loginUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 24),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              "Login",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text(
                      "Not yet registered? Visit the hospital to register",
                      style: TextStyle(
                        color: Colors.blueAccent,
                        decoration: TextDecoration.underline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

