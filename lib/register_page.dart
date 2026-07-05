import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'email_confirmation_page.dart';

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

    if (email.isEmpty || password.isEmpty || _firstNameController.text.trim().isEmpty || _lastNameController.text.trim().isEmpty) {
      _showErrorSnackbar('Please fill in all the input fields.');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackbar('Passwords do not match!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        await userCredential.user!.sendEmailVerification();
        if (mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => EmailConfirmationPage(email: email)));
        }
      }
    } on FirebaseAuthException catch (e) {
      _showErrorSnackbar(e.message ?? 'An error occurred.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  Widget _buildInputField({required TextEditingController controller, required String hintText, bool isPassword = false, bool isConfirmField = false}) {
    bool hideText = isPassword ? (isConfirmField ? _obscureConfirmPassword : _obscurePassword) : false;
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF0EAE9), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black12)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: hideText,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          suffixIcon: isPassword ? IconButton(icon: Icon((isConfirmField ? _obscureConfirmPassword : _obscurePassword) ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => isConfirmField ? _obscureConfirmPassword = !_obscureConfirmPassword : _obscurePassword = !_obscurePassword)) : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.of(context).pop())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              Image.asset('assets/images/logo.png', width: 140, height: 140),
              const Text('Create an Account', style: TextStyle(color: Colors.red, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildInputField(controller: _firstNameController, hintText: 'First Name'),
              const SizedBox(height: 14),
              _buildInputField(controller: _lastNameController, hintText: 'Last Name'),
              const SizedBox(height: 14),
              _buildInputField(controller: _emailController, hintText: 'Email'),
              const SizedBox(height: 14),
              _buildInputField(controller: _passwordController, hintText: 'Password', isPassword: true),
              const SizedBox(height: 14),
              _buildInputField(controller: _confirmPasswordController, hintText: 'Confirm Password', isPassword: true, isConfirmField: true),
              const SizedBox(height: 36),
              SizedBox(width: 160, height: 50, child: _isLoading ? const Center(child: CircularProgressIndicator(color: Colors.red)) : ElevatedButton(onPressed: _registerUserWithFirebase, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))), child: const Text('Sign Up', style: TextStyle(color: Colors.white)))),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? ", style: TextStyle(color: Colors.red, fontSize: 13)),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text('Log In', style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
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