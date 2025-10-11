import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/auth/login.dart';

class SessionWrapper extends StatefulWidget {
  final Widget child;
  final Duration warningDuration;
  final Duration timeoutDuration;

  const SessionWrapper({
    Key? key,
    required this.child,
    this.warningDuration = const Duration(minutes: 4, seconds: 30),
    this.timeoutDuration = const Duration(minutes: 5),
  }) : super(key: key);

  @override
  State<SessionWrapper> createState() => _SessionWrapperState();
}

class _SessionWrapperState extends State<SessionWrapper> {
  Timer? _warningTimer;
  Timer? _logoutTimer;

  @override
  void initState() {
    super.initState();
    _startTimers();
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  void _cancelTimers() {
    _warningTimer?.cancel();
    _logoutTimer?.cancel();
  }

  void _startTimers() {
    _cancelTimers();
    _warningTimer = Timer(widget.warningDuration, _showWarning);
    _logoutTimer = Timer(widget.timeoutDuration, _logoutUser);
  }

  void _resetTimers() {
    _startTimers();
  }

  void _showWarning() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Session Timeout Warning"),
        content: const Text(
          "You’ve been inactive. You will be logged out in 30 seconds unless you continue.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetTimers();
            },
            child: const Text("Continue Session"),
          ),
        ],
      ),
    );
  }

  Future<void> _logoutUser() async {
    _cancelTimers();
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _resetTimers(), 
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
