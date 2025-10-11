import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mw_antenatalcare/healthproffessional/doctorhome.dart';
import 'healthproffessional/registrationpage.dart';
import 'auth/login.dart';
import 'patient/homepage.dart';
import 'patient/session.dart';
import 'patient/tracker.dart';
import 'healthproffessional/admindashboard.dart';
import 'patient/profile.dart';
import 'patient/analytics.dart';
import 'session_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MaterialApp(
      title: 'Antenatal Care App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/register': (context) => _wrap(const RegistrationPage()),
        '/login': (context) => const LoginPage(),
        '/home': (context) => _wrap(const HomePage()),
        '/session': (context) => _wrap(const SessionsPage()),
        '/tracker': (context) => _wrap(const Tracker()),
        '/admindashboard': (context) => _wrap(const DashboardScreen()),
        '/profile': (context) => _wrap(const ProfilePage()),
        '/analytics': (context) => _wrap(const Analytics()),
        '/doctorhome': (context) => _wrap(const DoctorHomePage()),
      },
      home: const LoginPage(),
    ),
  );
}

Widget _wrap(Widget child) {
  return SessionWrapper(
    timeoutDuration: const Duration(minutes: 1),
    warningDuration: const Duration(seconds: 30),
    child: child,
  );
}
