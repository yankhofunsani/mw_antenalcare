import 'package:flutter/material.dart';
import '/registrationpage.dart';
import '/homepage.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
   WidgetsFlutterBinding.ensureInitialized();      
   await Firebase.initializeApp(); 
  runApp(
     MaterialApp(
     title: 'antenatal care app',
      theme: ThemeData(  
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
      initialRoute: '/home',
      routes: {
      '/register': (context) => RegistrationPage(),
      '/home': (context) => HomePage(),
  },
  debugShowCheckedModeBanner: false,
  )
  );
}
