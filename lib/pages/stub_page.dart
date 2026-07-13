import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class StubPage extends StatefulWidget {
  const StubPage({super.key});

  @override
  State<StubPage> createState() => _StubPageState();
}

class _StubPageState extends State<StubPage> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  bool _loading = true;
  String? _error;

  // Student info
  String _fullName = "";
  String _yearLevel = "";
  String _barangayName = "";
  String _claimLocation = "Not yet assigned";

  // Application info
  String? _ticketNumber;
  String? _status;
  String? _claimStatus;
  DateTime? _claimedAt;

  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _loadStub();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Widget _fadeIn(Widget child, {required double start, required double end}) {
    final curved = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (context, child) {
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(0, (1 - curved.value) * 16),
            child: child,
          ),
        );
      },
    );
  }

  void _finishLoading({String? error}) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
    });
    _entranceController.forward(from: 0);
  }

  Future<void> _loadStub() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        _finishLoading(error: "No user session found. Please log in again.");
        return;
      }

      final student = await supabase
          .from('student_details')
          .select('id, first_name, last_name, middle_name, year_level, barangay_id')
          .eq('firebase_uid', firebaseUser.uid)
          .maybeSingle();

      if (student == null) {
        _finishLoading(error: "Student profile not found. Please complete your profile first.");
        return;
      }

      final studentId = student['id'];
      final barangayName = (student['barangay_id'] ?? '').toString();

      setState(() {
        _fullName = [
          student['first_name'] ?? '',
          student['middle_name'] ?? '',
          student['last_name'] ?? '',
        ].where((s) => s.toString().trim().isNotEmpty).join(' ');
        _yearLevel = (student['year_level'] ?? '').toString();
        _barangayName = barangayName;
      });

      if (barangayName.isNotEmpty) {
        final barangay = await supabase
            .from('barangays')
            .select('claim_location')
            .eq('name', barangayName)
            .maybeSingle();

        if (barangay != null && barangay['claim_location'] != null) {
          setState(() {
            _claimLocation = barangay['claim_location'];
          });
        }
      }

      final application = await supabase
          .from('applications')
          .select('ticket_number, status, claim_status, claimed_at')
          .eq('student_id', studentId)
          .order('applied_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (application != null) {
        setState(() {
          _ticketNumber = application['ticket_number'];
          _status = application['status'];
          _claimStatus = application['claim_status'];
          _claimedAt = application['claimed_at'] != null
              ? DateTime.tryParse(application['claimed_at'])
              : null;
        });
      }

      _finishLoading();
    } catch (e) {
      _finishLoading(error: "Something went wrong loading your stub: $e");
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Not yet claimed";
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  Future<void> _printStub() async {
    final pdf = pw.Document();

    // Load the official city seal for the letterhead.
    final sealBytes = await rootBundle.load('assets/images/tanauan_seal.png');
    final sealImage = pw.MemoryImage(sealBytes.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Letterhead: seal + city/program name
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 54,
                      height: 54,
                      child: pw.Image(sealImage),
                    ),
                    pw.SizedBox(width: 14),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "CITY GOVERNMENT OF TANAUAN",
                            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            "Tanauan Educational Assistance Program",
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            "Official Assistance Stub",
                            style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.SizedBox(height: 12),
                _pdfRow("Student Name", _fullName),
                _pdfRow("Year Level", _yearLevel),
                _pdfRow("Barangay", _barangayName),
                pw.SizedBox(height: 12),
                pw.Divider(),
                pw.SizedBox(height: 12),
                _pdfRow("Ticket Number", _ticketNumber ?? "N/A"),
                _pdfRow("Application Status", _status ?? "N/A"),
                _pdfRow("Claim Status", _claimStatus ?? "N/A"),
                _pdfRow("Date Claimed", _formatDate(_claimedAt)),
                pw.SizedBox(height: 12),
                pw.Divider(),
                pw.SizedBox(height: 12),
                _pdfRow("Place to Claim", _claimLocation),
                pw.SizedBox(height: 24),
                pw.Text(
                  "Please present this stub together with a valid ID when claiming your assistance.",
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Assistance Stub",
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        backgroundColor: Colors.red.shade900,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: _fadeIn(
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(_error!, textAlign: TextAlign.center),
                    ),
                    start: 0.0,
                    end: 0.6,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _fadeIn(
                        Container(
                          width: double.infinity,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(BootstrapIcons.receipt, color: Colors.red.shade900, size: 30),
                                  const SizedBox(width: 10),
                                  const Text("Official Assistance Stub",
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const Divider(height: 30),
                              _infoRow("Student Name", _fullName.isEmpty ? "N/A" : _fullName),
                              _infoRow("Year Level", _yearLevel.isEmpty ? "N/A" : _yearLevel),
                              _infoRow("Barangay", _barangayName.isEmpty ? "N/A" : _barangayName),
                              const Divider(height: 30),
                              _infoRow("Ticket Number", _ticketNumber ?? "N/A"),
                              _infoRow("Application Status", _status ?? "N/A"),
                              _infoRow("Claim Status", _claimStatus ?? "N/A"),
                              _infoRow("Date Claimed", _formatDate(_claimedAt)),
                              const Divider(height: 30),
                              _infoRow("Place to Claim", _claimLocation),
                            ],
                          ),
                        ),
                        start: 0.0,
                        end: 0.5,
                      ),
                      const SizedBox(height: 24),
                      _fadeIn(
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton.icon(
                                onPressed: (_ticketNumber == null) ? null : _printStub,
                                icon: const Icon(BootstrapIcons.printer, color: Colors.white),
                                label: const Text("PRINT / EXPORT PDF",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade900,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            if (_ticketNumber == null)
                              const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: Text(
                                  "No active application found to generate a stub for.",
                                  style: TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                        start: 0.3,
                        end: 0.8,
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}