import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'homepage.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

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

      // If input is username, convert to email via Firestore
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
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? 'Login failed';
      });
    } catch (e) {
      setState(() {
        errorMessage = 'An unexpected error occurred.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> formItems = [
      TextField(
        controller: identifierController,
        decoration: InputDecoration(
          labelText: 'Username or Email',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.person, color: Colors.blue),
          labelStyle: TextStyle(
            fontSize: 16,
            color: Colors.black,
            fontFamily: 'Roboto',
          ),
        ),
      ),
      TextField(
        controller: passwordController,
        obscureText: true,
        decoration: InputDecoration(
          labelText: "Password",
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.lock, color: Colors.blue),
          labelStyle: TextStyle(
            fontSize: 16,
            color: Colors.black,
            fontFamily: 'Roboto',
          ),
        ),
      ),
      if (errorMessage.isNotEmpty)
        Text(
          errorMessage,
          style: TextStyle(color: Colors.red, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      TextButton(
        onPressed: isLoading ? null : loginUser,
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12),
          backgroundColor: Colors.blueAccent,
        ),
        child: isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Text(
                'Login',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Roboto',
                ),
              ),
      ),
      TextButton(
        onPressed: () {
          Navigator.pushNamed(context, '/register');
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: Colors.blueAccent,
          minimumSize: Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Not yet registered ? click here to register',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.normal,
            color: Colors.black,
            fontFamily: 'Roboto',
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Malawi Antenatal Care App'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          itemCount: formItems.length,
          separatorBuilder: (context, index) => SizedBox(height: 16),
          itemBuilder: (context, index) => formItems[index],
        ),
      ),
    );
  }
}
