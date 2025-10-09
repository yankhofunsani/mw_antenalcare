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
  bool _obscurePassword = true;

  Future<void> loginUser() async {
    setState(() {
      errorMessage = '';
      isLoading = true;
    });

    try {
      String identifier = identifierController.text.trim();
      String password = passwordController.text.trim();
      String email = identifier;

      // Convert username -> email if needed
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

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
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
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  //forgot password dialog
  Future<void> _showForgotPasswordDialog() async {
    final TextEditingController identifierCtrl = TextEditingController();
    String message = '';
    bool isSending = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Reset Password'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Enter your username or email to reset your password. A reset link will be sent to your registered email address.",
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: identifierCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Username or Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (message.isNotEmpty)
                    Text(
                      message,
                      style: TextStyle(
                        color: message.contains('sent')
                            ? Colors.green
                            : Colors.red,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: isSending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Submit'),
                onPressed: () async {
                  final id = identifierCtrl.text.trim();

                  if (id.isEmpty) {
                    setState(() => message = 'Please enter your username or email.');
                    return;
                  }

                  setState(() {
                    isSending = true;
                    message = '';
                  });

                  try {
                    String email = id;

                    // Check Firestore if username was provided
                    if (!id.contains('@')) {
                      final query = await FirebaseFirestore.instance
                          .collection('users')
                          .where('username', isEqualTo: id)
                          .limit(1)
                          .get();

                      if (query.docs.isEmpty) {
                        setState(() {
                          message = 'User not found.';
                          isSending = false;
                        });
                        return;
                      }

                      email = query.docs.first['email'];
                    }

                    //  password reset email
                    await FirebaseAuth.instance
                        .sendPasswordResetEmail(email: email);

                    setState(() {
                      message =
                          'Password reset email has been sent to $email. Please check your inbox.';
                      isSending = false;
                    });

                    await Future.delayed(const Duration(seconds: 3));
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    setState(() {
                      message = 'Error: ${e.toString().split('] ').last}';
                      isSending = false;
                    });
                  }
                },
              ),
            ],
          );
        });
      },
    );
  }

  Widget buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool obscure = false,
    VoidCallback? toggleObscure,
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
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey.shade700,
                ),
                onPressed: toggleObscure,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 700;

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Stack(
                  children: [
                    SizedBox.expand(
                      child: Image.asset(
                        'assets/images/background.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWide ? 40 : 24,
                              vertical: isWide ? 40 : 28,
                            ),
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 500),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/ministry.jpg',
                                    width: 200,
                                    height: 100,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "QTECH ANTENATAL CARE SYSTEM",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 25),
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
                                    obscure: _obscurePassword,
                                    toggleObscure: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  if (errorMessage.isNotEmpty)
                                    Text(
                                      errorMessage,
                                      style: const TextStyle(
                                          color: Colors.red, fontSize: 14),
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
                                          borderRadius:
                                              BorderRadius.circular(12),
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
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  GestureDetector(
                                    onTap: _showForgotPasswordDialog,
                                    child: const Text(
                                      "Forgot Password?",
                                      style: TextStyle(
                                        color: Colors.blueAccent,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/login');
                                    },
                                    child: const Text(
                                      "Not yet registered? Visit the hospital to register",
                                      style: TextStyle(
                                        color: Colors.blueAccent,
                                        decoration: TextDecoration.underline,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
