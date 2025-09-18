import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart';
import 'healthproffessional/registrationpage.dart';
import 'auth/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'patient/homepage.dart';
import 'patient/session.dart';
import 'patient/tracker.dart';
import 'healthproffessional/admindashboard.dart';
import 'patient/profile.dart';
import 'patient/analytics.dart';


void main() async {
   WidgetsFlutterBinding.ensureInitialized();      
   await Firebase.initializeApp(); 
  runApp(
     MaterialApp(
     title: 'antenatal care app',
      theme: ThemeData(  
        primarySwatch:Colors.blue,
      ),
      home: const LoginPage(),
      initialRoute: '/login',
      routes: {
      '/register': (context) => RegistrationPage(),
      '/login': (context) => LoginPage(),
      '/home':(context)=>HomePage(),
      '/session':(context)=>SessionsPage(),
      '/tracker':(context)=>Tracker(),
      '/admindashboard':(context)=>DashboardScreen(), 
      '/profile':(context)=>ProfilePage(),
      '/analytics':(context)=>Analytics(),
       },
  debugShowCheckedModeBanner: false,
  )
  );
}


