import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'submission_form.dart'; // Ensure this file is created in your lib folder

class SubmissionHubPage extends StatelessWidget {
  const SubmissionHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Application Hub", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        backgroundColor: Colors.red.shade900,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Welcome!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 10),
            Text("Please select your application type to proceed.", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
            const SizedBox(height: 50),
            
            // New Applicant Button
            _buildOptionCard(
              context,
              "New Application",
              "For first-time applicants",
              BootstrapIcons.person_plus_fill,
              Colors.red.shade900,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubmissionFormPage(isNewApplicant: true),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 25),
            
            // Repeat Availer Button
            _buildOptionCard(
              context,
              "Submit Requirements",
              "For returning availers",
              BootstrapIcons.file_earmark_text_fill,
              Colors.blue.shade800,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubmissionFormPage(isNewApplicant: false),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                ],
              ),
            ),
            Icon(BootstrapIcons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}