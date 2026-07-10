import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Soft decorative accent, kept subtle on purpose.
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Image.asset('assets/images/logo.png', height: 160)),
                  const SizedBox(height: 32),
                  Text(
                    "Tanauan Educational\nAssistance",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade800, fontSize: 24, fontWeight: FontWeight.w900, height: 1.3),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Apply, track, and manage your scholarship\nassistance — all in one place.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade800,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("Log In", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage())),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade800),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text("Create Account", style: TextStyle(color: Colors.red.shade800, fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}