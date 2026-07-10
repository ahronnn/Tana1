import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  final List<Map<String, String>> _faqs = const [
    {
      "q": "How do I apply for educational assistance?",
      "a": "Go to the Application Hub from the home screen and select 'New Application' if this is your first time, or 'Submit Requirements' if you're a returning availer."
    },
    {
      "q": "How do I check my application status?",
      "a": "Tap 'Track Status' on the home screen to see the current status, remarks, and claim status of your application."
    },
    {
      "q": "Where do I claim my assistance?",
      "a": "Tap 'Stub' on the home screen to view and print your official assistance stub, which shows your assigned claiming location and date."
    },
    {
      "q": "What if my ticket number hasn't been issued yet?",
      "a": "Ticket numbers are issued once your application has been reviewed and approved. Please check back later or contact support if it has been an unusually long wait."
    },
  ];

  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@tanauanassistance.gov.ph',
      query: 'subject=Assistance App Support',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchPhone() async {
    final uri = Uri(scheme: 'tel', path: '+63000000000');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Support",
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        backgroundColor: Colors.red.shade900,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
                Icon(BootstrapIcons.headset, size: 36, color: Colors.red.shade900),
                const SizedBox(height: 10),
                const Text("Need help?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  "Reach out to the Tanauan Educational Assistance office directly.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _launchEmail,
                        icon: const Icon(BootstrapIcons.envelope, size: 16),
                        label: const Text("Email"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _launchPhone,
                        icon: const Icon(BootstrapIcons.telephone, size: 16, color: Colors.white),
                        label: const Text("Call", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade900,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text("Frequently Asked Questions",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._faqs.map((faq) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ExpansionTile(
                  title: Text(faq["q"]!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(faq["a"]!, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}