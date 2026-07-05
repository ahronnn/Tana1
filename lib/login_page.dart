import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_page.dart';
// import 'home_page.dart'; // Uncomment this once you have your main/home page ready!

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Firebase Login Logic
  Future<void> _loginUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackbar('Please enter both email and password.', Colors.redAccent);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Attempt sign in with Firebase
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      // 2. Security Check: Force reload to see if they've verified their email
      await user?.reload();
      user = FirebaseAuth.instance.currentUser; 

      if (user != null && user.emailVerified) {
        // SUCCESS! Navigate to your main landing dashboard page
        _showSnackbar('Welcome back!', Colors.green);
        
        if (mounted) {
          // Navigator.of(context).pushReplacement(
          //   MaterialPageRoute(builder: (context) => const HomePage()),
          // );
        }
      } else {
        // User has NOT clicked the email link yet! Sign them out and lock them out.
        await FirebaseAuth.instance.signOut();
        _showSnackbar('Please verify your email address before logging in.', Colors.orangeAccent);
      }

    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Invalid email or password match.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is poorly formatted.';
      } else if (e.code == 'user-disabled') {
        message = 'This user account has been deactivated.';
      }
      _showSnackbar(message, Colors.redAccent);
    } catch (e) {
      _showSnackbar(e.toString(), Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Firebase Password Reset Logic
  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackbar('Please type your email address in the field first to reset password.', Colors.orangeAccent);
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showSnackbar('Password reset link sent! Check your inbox.', Colors.green);
    } catch (e) {
      _showSnackbar('Failed to send reset link. Verify email spelling.', Colors.redAccent);
    }
  }

  void _showSnackbar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: bgColor),
    );
  }

  // Input Field Component built to match your design system perfectly
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0EAE9), // The subtle gray/pink background from image_a0d95d.png
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.black54,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              
              // Back Button Row
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.red, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              // Tanauan App Logo from image_a0d95d.png
              Center(
                child: Image.asset(
                  'assets/images/logo.png', // Ensure this matches your asset path name!
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 24),

              // Headline Title Text
              const Text(
                'Log in to your Account',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 28),

              // Email/Username Input (Using email for Firebase Auth setup)
              _buildInputField(controller: _emailController, hintText: 'Username:'),
              
              const SizedBox(height: 16),
              
              // Password Input
              _buildInputField(controller: _passwordController, hintText: 'Password:', isPassword: true),

              const SizedBox(height: 36),

              // Log In Text Button Trigger
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.red)
                  : GestureDetector(
                      onTap: _loginUser,
                      child: const Text(
                        'Log in',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic, // Fixes the compilation error cleanly!
                          color: Colors.black,
                        ),
                      ),
                    ),

              const SizedBox(height: 28),

              // Forgot Password Trigger Action
              TextButton(
                onPressed: _forgotPassword,
                child: const Text(
                  'Forgot Password',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Bottom Red Navigation Toggle Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't you have an account? ",
                    style: TextStyle(color: Colors.red, fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const RegisterPage()),
                      );
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}