import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      _showSnack("Please fill in both fields.", isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      _showSnack(_friendlyError(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return "No account found with that email.";
      case 'wrong-password':
      case 'invalid-credential':
        return "Incorrect email or password.";
      case 'invalid-email':
        return "That email address looks invalid.";
      case 'too-many-requests':
        return "Too many attempts. Please wait a moment and try again.";
      default:
        return e.message ?? "Something went wrong. Please try again.";
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
                style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100, shape: const CircleBorder()),
              ),
              const SizedBox(height: 12),
              Center(child: Image.asset('assets/images/logo.png', width: 110, height: 110)),
              const SizedBox(height: 20),
              Text(
                "Welcome Back",
                style: TextStyle(color: Colors.red.shade800, fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                "Log in to continue your application.",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 32),
              _AuthField(
                controller: _emailController,
                hint: "Email address",
                icon: BootstrapIcons.envelope,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _AuthField(
                controller: _passwordController,
                hint: "Password",
                icon: BootstrapIcons.lock,
                obscure: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(_obscurePassword ? BootstrapIcons.eye_slash : BootstrapIcons.eye, size: 18, color: Colors.grey.shade500),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordPage())),
                  child: Text("Forgot Password?", style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text("Log In", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ", style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const RegisterPage())),
                      child: Text("Sign Up", style: TextStyle(color: Colors.red.shade800, fontSize: 13, fontWeight: FontWeight.w800)),
                    ),
                  ],
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

/// Shared styled input field used across the auth pages.
class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 4),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          prefixIcon: Icon(icon, size: 19, color: Colors.red.shade800),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}