import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TrackStatusPage extends StatefulWidget {
  const TrackStatusPage({super.key});

  @override
  State<TrackStatusPage> createState() => _TrackStatusPageState();
}

class _TrackStatusPageState extends State<TrackStatusPage> {
  final supabase = Supabase.instance.client;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _applications = [];

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        setState(() {
          _error = "No user session found. Please log in again.";
          _loading = false;
        });
        return;
      }

      final student = await supabase
          .from('student_details')
          .select('id')
          .eq('firebase_uid', firebaseUser.uid)
          .maybeSingle();

      if (student == null) {
        setState(() {
          _error = "Student profile not found. Please complete your profile first.";
          _loading = false;
        });
        return;
      }

      final apps = await supabase
          .from('applications')
          .select('id, status, remarks, applied_at, ticket_number, claim_status, claimed_at')
          .eq('student_id', student['id'])
          .order('applied_at', ascending: false);

      setState(() {
        _applications = List<Map<String, dynamic>>.from(apps);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Something went wrong loading your applications: $e";
        _loading = false;
      });
    }
  }

  Color _statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
      case 'denied':
        return Colors.red;
      case 'pending':
      case 'under review':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return "N/A";
    final date = DateTime.tryParse(iso);
    if (date == null) return "N/A";
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Track Status",
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        backgroundColor: Colors.red.shade900,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : _applications.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          "You have no applications yet.",
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadApplications,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _applications.length,
                        itemBuilder: (context, index) {
                          final app = _applications[index];
                          final status = app['status'] ?? 'Pending';
                          final color = _statusColor(status);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      app['ticket_number'] ?? 'No ticket #',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(BootstrapIcons.calendar_event, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 6),
                                    Text("Applied: ${_formatDate(app['applied_at'])}",
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                  ],
                                ),
                                if (app['claim_status'] != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(BootstrapIcons.box_seam, size: 14, color: Colors.grey.shade600),
                                      const SizedBox(width: 6),
                                      Text("Claim status: ${app['claim_status']}",
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                    ],
                                  ),
                                ],
                                if (app['remarks'] != null && app['remarks'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      app['remarks'],
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}