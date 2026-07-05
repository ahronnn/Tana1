import 'dart:async'; // Added for the background Timer task
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for checking backend status

class EmailConfirmationPage extends StatefulWidget {
  final String email;

  const EmailConfirmationPage({super.key, required this.email});

  @override
  State<EmailConfirmationPage> createState() => _EmailConfirmationPageState();
}

class _EmailConfirmationPageState extends State<EmailConfirmationPage> {
  Timer? _timer;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;

    // Start a background timer ticking every 3 seconds to auto-detect verification status
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkEmailVerified();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the ticking timer to avoid memory leaks when leaving the view
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    _user = FirebaseAuth.instance.currentUser;
    
    // Force Firebase local profile cache to refresh straight from the live server
    await _user?.reload();

    // Check if the verification flag turned true on the server
    if (_user != null && _user!.emailVerified) {
      _timer?.cancel(); // Kill the loop instantly

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email successfully verified! Welcome.'),
            backgroundColor: Colors.green,
          ),
        );

        // Snap them cleanly back to the Welcome/Login interface root automatically
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Standard mail icon matching your theme colors
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 100,
                color: Colors.red,
              ),
              
              const SizedBox(height: 32),
              
              const Text(
                'Confirm your Email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'We have sent a verification link to:\n${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 8),
              const Text(
                'Please check your inbox and follow the instructions to activate your account.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              
              const SizedBox(height: 24),
              // Subtle loader indicator letting them know the app is checking for the click live
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.red,
                  strokeWidth: 2.5,
                ),
              ),
              
              const Spacer(),
              
              // Button to take them back to login manually if needed
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    _timer?.cancel(); // Safely kill background timer on intentional fallback pop
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}