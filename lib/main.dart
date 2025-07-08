import 'package:flutter/material.dart';
import '/registrationpage.dart';
import '/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'homepage.dart';

void main() async {
   WidgetsFlutterBinding.ensureInitialized();      
   await Firebase.initializeApp(); 
  runApp(
     MaterialApp(
     title: 'antenatal care app',
      theme: ThemeData(  
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
      initialRoute: '/login',
      routes: {
      '/register': (context) => RegistrationPage(),
      '/login': (context) => LoginPage(),
      '/home':(context)=>HomePage()
  },
  debugShowCheckedModeBanner: false,
  )
  );
}
