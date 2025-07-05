import 'package:flutter/material.dart';
// LANDING PAGE CODE
class HomePage extends StatelessWidget{
  const HomePage({Key? key}): super(key: key);

@override
Widget build(BuildContext context) {
  final List<Widget> formItems = [
    TextField(
      decoration: InputDecoration(
        labelText: 'Username or Email',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person, color: Colors.blue),
        labelStyle: TextStyle(fontSize: 16, color: Colors.black, fontFamily: 'Roboto'),
      ),
    ),
    TextField(
      obscureText: true,
      decoration: InputDecoration(
        labelText: "Password",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.lock, color: Colors.blue),
        labelStyle: TextStyle(fontSize: 16, color: Colors.black, fontFamily: 'Roboto'),
      ),
    ),
    TextButton(
      onPressed: () async {
        // login logic
      },
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric( vertical: 12),
        backgroundColor: Colors.blueAccent,
      ),
      child: Text(
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
        Navigator.pushNamed(
      context, '/register'
     // MaterialPageRoute(builder: (context) => RegisterPage()),
    );
      },
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        foregroundColor: Colors.blueAccent,
        minimumSize: Size(0, 0), 
        tapTargetSize: MaterialTapTargetSize.shrinkWrap
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
 