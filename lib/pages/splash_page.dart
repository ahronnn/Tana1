import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'welcome_page.dart';
import 'student_info_page.dart';

// 1. THIS CLASS DEFINITION WAS LIKELY MISSING IN YOUR FILE
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

// 2. THIS IS THE LOGIC YOU PROVIDED
class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Wait for at least 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Check if a user is already logged in
    final session = Supabase.instance.client.auth.currentSession;
    
    if (session != null) {
      // User is logged in, send them directly to the profile page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const StudentInfoPage()),
      );
    } else {
      // No user, send to Welcome/Login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset('assets/images/logo.png', width: 150),
      ),
    );
  }
}