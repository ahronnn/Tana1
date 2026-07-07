import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

class SubmissionFormPage extends StatelessWidget {
  final bool isNewApplicant;

  const SubmissionFormPage({super.key, required this.isNewApplicant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(isNewApplicant ? "New Application" : "Requirement Submission",
            style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        backgroundColor: Colors.red.shade900,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    isNewApplicant ? BootstrapIcons.person_plus_fill : BootstrapIcons.file_earmark_text_fill,
                    size: 40,
                    color: isNewApplicant ? Colors.red.shade900 : Colors.blue.shade800,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    isNewApplicant ? "New Applicant Requirements" : "Returning Availer Update",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    isNewApplicant 
                        ? "Please fill out the details for your initial application." 
                        : "Please upload your latest documents to renew your status.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // Dynamic Form Fields
            _buildFormSection(
              isNewApplicant 
                  ? ["Application Letter", "Birth Certificate", "Proof of Enrollment"]
                  : ["Report Card / Transcript", "Updated Proof of Enrollment"]
            ),

            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Add Supabase File Upload Logic here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Application submitted successfully!")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isNewApplicant ? Colors.red.shade900 : Colors.blue.shade800,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("SUBMIT DOCUMENTS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection(List<String> fields) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: fields.map((label) => Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: TextFormField(
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: const Icon(BootstrapIcons.upload, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
        )).toList(),
      ),
    );
  }
}