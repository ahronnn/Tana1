import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'submission_form.dart';

class SubmissionHubPage extends StatefulWidget {
  const SubmissionHubPage({super.key});

  @override
  State<SubmissionHubPage> createState() => _SubmissionHubPageState();
}

class _SubmissionHubPageState extends State<SubmissionHubPage> {
  bool _loading = true;
  Map<String, dynamic>? _latestApplication;

  @override
  void initState() {
    super.initState();
    _loadLatestApplication();
  }

  Future<void> _loadLatestApplication() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return;

      final supabase = Supabase.instance.client;

      final profile = await supabase
          .from('profiles')
          .select('id')
          .eq('firebase_uid', firebaseUser.uid)
          .maybeSingle();

      final profileId = profile?['id'] as String?;
      if (profileId == null) return;

      final application = await supabase
          .from('applications')
          .select('status, ticket_number, applied_at, claim_status')
          .eq('student_id', profileId)
          .order('applied_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (mounted) setState(() => _latestApplication = application);
    } catch (e) {
      debugPrint("Error loading latest application: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('approve') || s.contains('claim')) return Colors.green.shade700;
    if (s.contains('reject') || s.contains('denied')) return Colors.red.shade700;
    if (s.contains('pending')) return Colors.amber.shade800;
    return Colors.grey.shade700;
  }

  IconData _statusIcon(String status) {
    final s = status.toLowerCase();
    if (s.contains('approve') || s.contains('claim')) return BootstrapIcons.check_circle_fill;
    if (s.contains('reject') || s.contains('denied')) return BootstrapIcons.x_circle_fill;
    if (s.contains('pending')) return BootstrapIcons.hourglass_split;
    return BootstrapIcons.info_circle_fill;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Application Hub",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.red.shade800,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_loading && _latestApplication != null) ...[
              _buildStatusBanner(_latestApplication!),
              const SizedBox(height: 20),
            ],

            const Text(
              "What would you like to do?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              "Select the option that matches your situation.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 18),

            _buildOptionCard(
              context,
              title: "New Application",
              subtitle: "For first-time applicants",
              docCount: 3,
              icon: BootstrapIcons.person_plus_fill,
              accent: Colors.red.shade800,
              accentSoft: Colors.red.shade50,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubmissionFormPage(isNewApplicant: true),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            _buildOptionCard(
              context,
              title: "Repeat Availers",
              subtitle: "For returning availers",
              docCount: 2,
              icon: BootstrapIcons.file_earmark_arrow_up_fill,
              accent: Colors.red.shade800,
              accentSoft: Colors.red.shade50,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubmissionFormPage(isNewApplicant: false),
                  ),
                );
              },
            ),

            const SizedBox(height: 28),
            _buildHowItWorks(),

            const SizedBox(height: 24),
            _buildEligibilityTips(),

            const SizedBox(height: 24),
            _buildSupportShortcut(),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade700),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildHowItWorks() {
    final steps = [
      (
        icon: BootstrapIcons.pencil_square,
        title: "Fill out the form",
        desc: "Complete your application with accurate details.",
      ),
      (
        icon: BootstrapIcons.file_earmark_arrow_up_fill,
        title: "Upload requirements",
        desc: "Attach the documents needed for your track.",
      ),
      (
        icon: BootstrapIcons.hourglass_split,
        title: "Wait for review",
        desc: "Our team checks your submission for completeness.",
      ),
      (
        icon: BootstrapIcons.check_circle_fill,
        title: "Get notified",
        desc: "You'll see your status update right here in the hub.",
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("How it Works", BootstrapIcons.signpost_split_fill),
          const SizedBox(height: 16),
          for (int i = 0; i < steps.length; i++)
            _buildTimelineStep(
              stepNumber: i + 1,
              icon: steps[i].icon,
              title: steps[i].title,
              desc: steps[i].desc,
              isLast: i == steps.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required int stepNumber,
    required IconData icon,
    required String title,
    required String desc,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Icon(icon, size: 14, color: Colors.red.shade800),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.grey.shade200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$stepNumber. $title",
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEligibilityTips() {
    final tips = [
      "Make sure your name matches your school records exactly.",
      "Documents should be clear, complete, and under the file size limit.",
      "Only one active application is allowed per school year.",
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(BootstrapIcons.lightbulb_fill, size: 16, color: Colors.amber.shade800),
              const SizedBox(width: 6),
              Text(
                "Quick Eligibility Tips",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final tip in tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(BootstrapIcons.dot, size: 18, color: Colors.amber.shade800),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(fontSize: 12.5, color: Colors.amber.shade900, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSupportShortcut() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: wire up to your actual support/contact page or chat.
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(BootstrapIcons.headset, color: Colors.blue.shade700, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Need help?",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Contact support for questions about your application.",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(BootstrapIcons.chevron_right, color: Colors.grey.shade400, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(Map<String, dynamic> app) {
    final status = (app['status'] as String?) ?? 'Pending';
    final ticket = app['ticket_number'] as String?;
    final appliedAt = app['applied_at'] as String?;
    final color = _statusColor(status);

    String? formattedDate;
    if (appliedAt != null) {
      try {
        formattedDate = DateFormat('MMM d, yyyy').format(DateTime.parse(appliedAt).toLocal());
      } catch (_) {}
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 46,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 12),
          Icon(_statusIcon(status), color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Application Status: $status",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (ticket != null && ticket.isNotEmpty) "Ticket #$ticket",
                    if (formattedDate != null) "Applied $formattedDate",
                  ].join(" · "),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required int docCount,
    required IconData icon,
    required Color accent,
    required Color accentSoft,
    required VoidCallback onTap,
    Color? subtitleColor,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: accent.withOpacity(0.08),
        highlightColor: accent.withOpacity(0.04),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withOpacity(0.25), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.14),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent, Color.lerp(accent, Colors.black, 0.15)!],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: Colors.black87)),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(color: subtitleColor ?? Colors.grey.shade600, fontSize: 12.5),
                    ),
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentSoft,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accent.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(BootstrapIcons.file_earmark_text_fill, size: 11, color: accent),
                          const SizedBox(width: 5),
                          Text(
                            "$docCount document${docCount == 1 ? '' : 's'} needed",
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: accent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(BootstrapIcons.chevron_right, color: accent, size: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}