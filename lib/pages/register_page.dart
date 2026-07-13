import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'email_confirmation_page.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerUserWithFirebase() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (email.isEmpty || password.isEmpty || firstName.isEmpty || lastName.isEmpty) {
      _showErrorSnackbar('Please fill in all the input fields.');
      return;
    }
    if (password.length < 6) {
      _showErrorSnackbar('Password must be at least 6 characters.');
      return;
    }
    if (password != _confirmPasswordController.text.trim()) {
      _showErrorSnackbar('Passwords do not match!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Gumawa ng Firebase account
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        // 2. I-insert ang profile info papunta sa Supabase
        //    Ang Firebase UID ay gagamitin natin bilang link sa profiles table
        try {
          await Supabase.instance.client.from('profiles').insert({
            'firebase_uid': userCredential.user!.uid,
            'first_name': firstName,
            'last_name': lastName,
            'role': 'student', // default role — valid values: student, evaluator, admin
          });
        } catch (e) {
          debugPrint('❌ Supabase insert error: $e');
          // Registration continues even if this fails — student_info_page.dart
          // has a fallback that creates the profile row on-the-fly if missing.
        }

        // 3. Magpadala ng verification email at pumunta sa confirmation page
        if (!userCredential.user!.emailVerified) {
          await userCredential.user!.sendEmailVerification();
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => EmailConfirmationPage(email: email)),
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      _showErrorSnackbar(_friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return "That email is already registered. Try logging in instead.";
      case 'invalid-email':
        return "That email address looks invalid.";
      case 'weak-password':
        return "Please choose a stronger password.";
      default:
        return e.message ?? "An error occurred. Please try again.";
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red.shade700,
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
              const SizedBox(height: 8),
              Center(child: Image.asset('assets/images/logo.png', width: 90, height: 90)),
              const SizedBox(height: 16),
              Text("Create an Account", style: TextStyle(color: Colors.red.shade800, fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text("Fill in your details to get started.", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(child: _AuthField(controller: _firstNameController, hint: "First Name", icon: BootstrapIcons.person)),
                  const SizedBox(width: 12),
                  Expanded(child: _AuthField(controller: _lastNameController, hint: "Last Name", icon: BootstrapIcons.person)),
                ],
              ),
              const SizedBox(height: 16),
              _AuthField(controller: _emailController, hint: "Email address", icon: BootstrapIcons.envelope, keyboardType: TextInputType.emailAddress),
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
              const SizedBox(height: 16),
              _AuthField(
                controller: _confirmPasswordController,
                hint: "Confirm Password",
                icon: BootstrapIcons.lock_fill,
                obscure: _obscureConfirmPassword,
                suffix: IconButton(
                  icon: Icon(_obscureConfirmPassword ? BootstrapIcons.eye_slash : BootstrapIcons.eye, size: 18, color: Colors.grey.shade500),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registerUserWithFirebase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text("Sign Up", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account? ", style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const LoginPage())),
                      child: Text("Log In", style: TextStyle(color: Colors.red.shade800, fontSize: 13, fontWeight: FontWeight.w800)),
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