import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ScholarshipPage extends StatefulWidget {
  const ScholarshipPage({super.key});

  @override
  State<ScholarshipPage> createState() => _ScholarshipPageState();
}

class _ScholarshipPageState extends State<ScholarshipPage> {
  final _supabase = Supabase.instance.client;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _scholarships = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _supabase
          .from('scholarships')
          .select()
          .eq('is_active', true)
          .order('deadline', ascending: true, nullsFirst: false)
          .order('created_at', ascending: false);

      setState(() => _scholarships = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      setState(() => _error = "Couldn't load scholarships: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int? _daysLeft(String? deadline) {
    if (deadline == null) return null;
    final d = DateTime.tryParse(deadline);
    if (d == null) return null;
    final today = DateTime.now();
    final onlyDate = DateTime(d.year, d.month, d.day);
    final onlyToday = DateTime(today.year, today.month, today.day);
    return onlyDate.difference(onlyToday).inDays;
  }

  Future<void> _openLink(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Scholarships",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.red.shade800,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: Colors.red.shade800,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 100),
                      Center(child: Text(_error!, textAlign: TextAlign.center)),
                    ],
                  )
                : _scholarships.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 120),
                          Icon(BootstrapIcons.mortarboard, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              "No scholarships posted yet.\nCheck back soon!",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _scholarships.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) => _buildCard(_scholarships[index]),
                      ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> s) {
    final title = (s['title'] as String?) ?? 'Untitled';
    final org = s['organization'] as String?;
    final description = (s['description'] as String?) ?? '';
    final eligibility = s['eligibility'] as String?;
    final link = s['application_link'] as String?;
    final deadline = s['deadline'] as String?;
    final days = _daysLeft(deadline);

    String? deadlineLabel;
    Color deadlineColor = Colors.grey.shade600;
    if (deadline != null) {
      final parsed = DateTime.tryParse(deadline);
      final formatted = parsed != null ? DateFormat('MMM d, yyyy').format(parsed) : deadline;
      if (days != null) {
        if (days < 0) {
          deadlineLabel = "Deadline passed ($formatted)";
          deadlineColor = Colors.grey.shade500;
        } else if (days == 0) {
          deadlineLabel = "Deadline today!";
          deadlineColor = Colors.red.shade700;
        } else if (days <= 7) {
          deadlineLabel = "$days day${days == 1 ? '' : 's'} left \u2022 $formatted";
          deadlineColor = Colors.red.shade700;
        } else {
          deadlineLabel = "Deadline: $formatted";
          deadlineColor = Colors.amber.shade800;
        }
      }
    }

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(BootstrapIcons.mortarboard_fill, color: Colors.red.shade800, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5)),
                    if (org != null && org.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(org, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.45),
          ),
          if (eligibility != null && eligibility.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(BootstrapIcons.check2_circle, size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    eligibility,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                  ),
                ),
              ],
            ),
          ],
          if (deadlineLabel != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(BootstrapIcons.calendar_event, size: 13, color: deadlineColor),
                const SizedBox(width: 6),
                Text(
                  deadlineLabel,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: deadlineColor),
                ),
              ],
            ),
          ],
          if (link != null && link.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                onPressed: () => _openLink(link),
                icon: Icon(BootstrapIcons.box_arrow_up_right, size: 14, color: Colors.red.shade800),
                label: Text(
                  "Learn More / Apply",
                  style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w600, fontSize: 12.5),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.shade200),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}