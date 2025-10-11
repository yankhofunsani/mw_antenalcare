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
import 'package:mw_antenatalcare/session_wrapper.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      home:const LoginPage(),
      routes: {
      '/register': (context) => _wrap(const RegistrationPage()),
      '/login': (context) => LoginPage(),
      '/home':(context)=>_wrap(const HomePage()),
      '/session':(context)=>_wrap (const SessionsPage(),),
      '/tracker':(context)=>_wrap (const Tracker(),),
      '/admindashboard':(context)=>_wrap (const DashboardScreen()), 
      '/anc_register':(context)=>_wrap (const ANCRegisterPage()),
      '/anc_session':(context)=>_wrap (const ANCSessionPage()), 
      '/patientdata':(context)=>_wrap (const PatientHomePage()),
      '/appointment':(context)=>_wrap (const AppointmentPage()),
      '/doctorhome':(context)=> _wrap (const DoctorHomePage())

      },
    );
  }

 static Widget _wrap(Widget child) {
    return SessionWrapper(
      timeoutDuration: const Duration(minutes: 1),
      warningDuration: const Duration(seconds: 30),
      child: child,
    );
  }




}
