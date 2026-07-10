import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

class EmailConfirmationPage extends StatefulWidget {
  final String email;

  const EmailConfirmationPage({super.key, required this.email});

  @override
  State<EmailConfirmationPage> createState() => _EmailConfirmationPageState();
}

class _EmailConfirmationPageState extends State<EmailConfirmationPage> {
  Timer? _pollTimer;
  Timer? _cooldownTimer;
  User? _user;
  int _cooldown = 0;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;

    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkEmailVerified();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    _user = FirebaseAuth.instance.currentUser;
    await _user?.reload();

    if (_user != null && _user!.emailVerified) {
      _pollTimer?.cancel();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Email successfully verified! Welcome.'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  Future<void> _resendEmail() async {
    if (_cooldown > 0 || _resending) return;

    setState(() => _resending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text("Verification email sent again."),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        _startCooldown();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message ?? "Couldn't resend right now. Please try again shortly."),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _startCooldown() {
    setState(() => _cooldown = 30);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldown <= 1) {
        timer.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                child: Icon(BootstrapIcons.envelope_paper, size: 42, color: Colors.red.shade800),
              ),
              const SizedBox(height: 28),
              Text("Confirm Your Email", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.red.shade800)),
              const SizedBox(height: 14),
              Text(
                "We've sent a verification link to",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              Text(
                "Check your inbox (and spam folder) and tap the link to continue.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.5),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.red.shade800, strokeWidth: 2.2)),
                  const SizedBox(width: 10),
                  Text("Waiting for verification…", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: _cooldown > 0 || _resending ? null : _resendEmail,
                child: _resending
                    ? SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red.shade800),
                      )
                    : Text(
                        _cooldown > 0 ? "Resend available in ${_cooldown}s" : "Didn't get the email? Resend",
                        style: TextStyle(
                          color: _cooldown > 0 ? Colors.grey.shade400 : Colors.red.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    _pollTimer?.cancel();
                    _cooldownTimer?.cancel();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade800),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text("Back to Login", style: TextStyle(color: Colors.red.shade800, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}