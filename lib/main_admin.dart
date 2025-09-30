import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mw_antenatalcare/healthproffessional/anc_register.dart';
import 'package:mw_antenatalcare/healthproffessional/anc_session.dart';
import 'package:mw_antenatalcare/healthproffessional/appointment.dart';
import 'firebase_options.dart'; 
import 'auth/login.dart'; 
import 'healthproffessional/registrationpage.dart';
import 'patient/homepage.dart';
import 'patient/session.dart';
import 'patient/tracker.dart';
import 'healthproffessional/admindashboard.dart';
import 'package:mw_antenatalcare/healthproffessional/patientdata.dart';
import  'healthproffessional/doctorhome.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //  Initialize Firebase for web & mobile
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ANC Admin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: const LoginPage(), // first page for admin web
      routes: {
      '/register': (context) => RegistrationPage(),
      '/login': (context) => LoginPage(),
      '/home':(context)=>HomePage(),
      '/session':(context)=>SessionsPage(),
      '/tracker':(context)=>Tracker(),
      '/admindashboard':(context)=>DashboardScreen(), 
      '/anc_register':(context)=>ANCRegisterPage(),
      '/anc_session':(context)=>ANCSessionPage(), 
      '/patientdata':(context)=>PatientHomePage(),
      '/appointment':(context)=>AppointmentPage(),
      '/doctorhome':(context)=>DoctorHomePage()

      },
    );
  }
}
