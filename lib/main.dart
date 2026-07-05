import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Added Firebase import
import 'login_page.dart'; // 1. Added import for your new login page workflow!
import 'splash_page.dart';

void main() async {
  // Ensures native components are completely ready before initializing Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Boots up Firebase with the native configurations we added
  await Firebase.initializeApp();

  runApp(const Tana1App());
}

class Tana1App extends StatelessWidget {
  const Tana1App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TANA 1',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: SplashPage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // 3-second delay on the logo
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        // Smooth Custom Fade Transition Builder
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            // 2. Swapped destination target here to load LoginPage instead of AuthWelcomePage
            pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 800), // Controls the fade speed
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            child: Image(
              image: AssetImage('assets/images/logo.png'),
              width: 220,
              height: 220,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}