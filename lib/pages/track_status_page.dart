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

  // ---------------------------------------------------------------------
  // Raw DB status ('Pending', 'Under Review', 'Approved', 'Rejected') →
  // what's actually shown to the applicant. A freshly-submitted
  // application is stored as 'Pending' (nothing has looked at it yet),
  // but from the applicant's point of view that's indistinguishable from
  // "somebody is reviewing it" — so both display as "Under Review" until
  // it's actually Approved or Rejected. Only the display label changes;
  // the raw status keeps flowing everywhere else (_progress, filtering,
  // admin side) exactly as stored.
  // ---------------------------------------------------------------------
  String _statusLabel(String? status) {
    final s = (status ?? '').toLowerCase();
    if (s.contains('pending') || s.contains('review')) return "Under Review";
    if (s.contains('approve')) return "Approved";
    if (s.contains('reject') || s.contains('denied')) return "Rejected";
    return status ?? 'Under Review';
  }

  // ---------------------------------------------------------------------
  // Status → color/icon, same red/amber/green language used across the
  // app (home page status badge, submission hub).
  // ---------------------------------------------------------------------
  ({Color color, IconData icon}) _statusStyle(String? status) {
    final s = (status ?? '').toLowerCase();
    if (s.contains('approve')) {
      return (color: Colors.green.shade600, icon: BootstrapIcons.check_circle_fill);
    }
    if (s.contains('reject') || s.contains('denied')) {
      return (color: Colors.red.shade600, icon: BootstrapIcons.x_circle_fill);
    }
    if (s.contains('pending') || s.contains('review')) {
      return (color: Colors.amber.shade700, icon: BootstrapIcons.hourglass_split);
    }
    return (color: Colors.grey.shade600, icon: BootstrapIcons.info_circle_fill);
  }

  // ---------------------------------------------------------------------
  // Turns status + claim fields into a step index (0=Submitted,
  // 1=Under Review, 2=Approved, 3=Claimed) plus whether it was rejected —
  // rejection halts the stepper rather than faking further progress.
  // ---------------------------------------------------------------------
  ({int step, bool rejected}) _progress(Map<String, dynamic> app) {
    final status = (app['status'] as String? ?? '').toLowerCase();
    final claimStatus = (app['claim_status'] as String? ?? '').toLowerCase();
    final claimedAt = app['claimed_at'];

    if (status.contains('reject') || status.contains('denied')) {
      return (step: 1, rejected: true);
    }
    // Exact match on 'claimed' here (not a loose .contains('claim')) —
    // the default/unset value for this field is the string 'Unclaimed',
    // and "unclaimed".contains('claim') is true, which was previously
    // sending every fresh application straight to step 3.
    final isClaimed = claimStatus == 'claimed' || claimedAt != null;
    if (isClaimed) {
      return (step: 3, rejected: false);
    }
    if (status.contains('approve')) {
      return (step: 2, rejected: false);
    }
    // Submitted, but not yet reviewed/approved — sit at "Under Review".
    return (step: 1, rejected: false);
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
        backgroundColor: Colors.red.shade800,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildMessageState(icon: BootstrapIcons.exclamation_triangle, text: _error!)
              : _applications.isEmpty
                  ? _buildMessageState(
                      icon: BootstrapIcons.inbox,
                      text: "You have no applications yet.",
                      subtext: "Once you submit one from the Application Hub, you'll be able to track it here.",
                    )
                  : RefreshIndicator(
                      onRefresh: _loadApplications,
                      color: Colors.red.shade800,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                        children: [
                          Text(
                            "Current Application",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                          ),
                          const SizedBox(height: 12),
                          _buildCurrentApplication(_applications.first),
                          if (_applications.length > 1) ...[
                            const SizedBox(height: 28),
                            Text(
                              "Previous Applications",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                            ),
                            const SizedBox(height: 12),
                            for (final app in _applications.skip(1)) ...[
                              _buildHistoryCard(app),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildMessageState({required IconData icon, required String text, String? subtext}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(icon, size: 26, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700, fontSize: 14.5, fontWeight: FontWeight.w600)),
            if (subtext != null) ...[
              const SizedBox(height: 6),
              Text(subtext, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5, height: 1.4)),
            ],
          ],
        ),
      ),
    );
  }

  // =======================================================================
  // Current application — ticket-stub header (colored by status) directly
  // above a card with the progress stepper, remarks, and claim info.
  // =======================================================================
  Widget _buildCurrentApplication(Map<String, dynamic> app) {
    final style = _statusStyle(app['status']);
    final progress = _progress(app);
    final remarks = app['remarks']?.toString();
    final hasRemarks = remarks != null && remarks.isNotEmpty;

    return Column(
      children: [
        _buildTicketHeader(app, style),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepper(progress.step, progress.rejected),
              if (hasRemarks) ...[
                const SizedBox(height: 18),
                _buildRemarksBox(remarks, isRejection: progress.rejected),
              ],
              if (app['claim_status'] != null || app['claimed_at'] != null) ...[
                SizedBox(height: hasRemarks ? 12 : 18),
                _buildClaimInfo(app),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Torn-ticket header, recolored to match the application's status
  // instead of always being brand red — the color itself is information.
  Widget _buildTicketHeader(Map<String, dynamic> app, ({Color color, IconData icon}) style) {
    const double stubWidth = 78;
    const double cardHeight = 132;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final dashX = width - stubWidth;

        return SizedBox(
          height: cardHeight,
          width: width,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _StatusTicketPainter(
                    dashX: dashX,
                    gradientColors: [style.color, Color.lerp(style.color, Colors.black, 0.22)!],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: stubWidth + 6,
                top: 0,
                bottom: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      app['ticket_number']?.toString() ?? 'No ticket # yet',
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Applied ${_formatDate(app['applied_at'])}",
                      style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11.5),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(style.icon, color: Colors.white, size: 12),
                          const SizedBox(width: 5),
                          Text(
                            _statusLabel(app['status']?.toString()),
                            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: dashX,
                top: 0,
                bottom: 0,
                width: stubWidth,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(BootstrapIcons.ticket_perforated_fill, color: Colors.white, size: 18),
                      const SizedBox(height: 8),
                      RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          "STATUS",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // Vertical progress stepper: Submitted → Under Review → Approved →
  // Claimed. Rejection freezes the stepper at the step it broke on
  // instead of pretending progress continued.
  // ---------------------------------------------------------------------
  Widget _buildStepper(int currentStep, bool rejected) {
    final steps = [
      (title: "Submitted", icon: BootstrapIcons.file_earmark_arrow_up_fill),
      (title: "Under Review", icon: BootstrapIcons.hourglass_split),
      (title: "Approved", icon: BootstrapIcons.check_circle_fill),
      (title: "Claimed", icon: BootstrapIcons.box_seam_fill),
    ];

    return Column(
      children: [
        for (int i = 0; i < steps.length; i++)
          _buildStepRow(
            title: steps[i].title,
            icon: steps[i].icon,
            isLast: i == steps.length - 1,
            state: i < currentStep
                ? _StepState.done
                : i == currentStep
                    ? (rejected ? _StepState.rejected : _StepState.active)
                    : _StepState.pending,
          ),
      ],
    );
  }

  Widget _buildStepRow({
    required String title,
    required IconData icon,
    required bool isLast,
    required _StepState state,
  }) {
    Color color;
    IconData displayIcon;
    switch (state) {
      case _StepState.done:
        color = Colors.green.shade600;
        displayIcon = BootstrapIcons.check_circle_fill;
        break;
      case _StepState.active:
        color = Colors.amber.shade700;
        displayIcon = icon;
        break;
      case _StepState.rejected:
        color = Colors.red.shade600;
        displayIcon = BootstrapIcons.x_circle_fill;
        break;
      case _StepState.pending:
        color = Colors.grey.shade300;
        displayIcon = icon;
        break;
    }
    final isFilled = state != _StepState.pending;

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
                  color: isFilled ? color.withOpacity(0.14) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: isFilled ? color.withOpacity(0.4) : Colors.grey.shade300),
                ),
                child: Icon(displayIcon, size: 14, color: isFilled ? color : Colors.grey.shade400),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: state == _StepState.done ? Colors.green.shade200 : Colors.grey.shade200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 22, top: 4),
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: state == _StepState.pending ? FontWeight.w500 : FontWeight.w700,
                  fontSize: 13.5,
                  color: state == _StepState.pending ? Colors.grey.shade500 : Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemarksBox(String remarks, {required bool isRejection}) {
    final color = isRejection ? Colors.red.shade600 : Colors.grey.shade700;
    final bg = isRejection ? Colors.red.shade50 : Colors.grey.shade50;
    final border = isRejection ? Colors.red.shade100 : Colors.grey.shade200;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isRejection ? BootstrapIcons.exclamation_circle_fill : BootstrapIcons.chat_left_text_fill, size: 15, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRejection ? "Reason" : "Remarks",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                ),
                const SizedBox(height: 3),
                Text(remarks, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimInfo(Map<String, dynamic> app) {
    final claimStatus = app['claim_status']?.toString();
    final claimedAt = app['claimed_at'] as String?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          Icon(BootstrapIcons.box_seam_fill, size: 15, color: Colors.green.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  claimStatus ?? "Claimed",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.green.shade800),
                ),
                if (claimedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    "Claimed on ${_formatDate(claimedAt)}",
                    style: TextStyle(fontSize: 11.5, color: Colors.green.shade700),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =======================================================================
  // History cards — compact, flat cards for older applications so the
  // current one keeps the visual spotlight.
  // =======================================================================
  Widget _buildHistoryCard(Map<String, dynamic> app) {
    final style = _statusStyle(app['status']);
    final remarks = app['remarks']?.toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  app['ticket_number']?.toString() ?? 'No ticket #',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: style.color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(style.icon, size: 11, color: style.color),
                    const SizedBox(width: 5),
                    Text(
                      _statusLabel(app['status']?.toString()),
                      style: TextStyle(color: style.color, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(BootstrapIcons.calendar_event, size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text("Applied ${_formatDate(app['applied_at'])}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
            ],
          ),
          if (remarks != null && remarks.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
              child: Text(remarks, style: const TextStyle(fontSize: 12.5, height: 1.35)),
            ),
          ],
        ],
      ),
    );
  }
}

enum _StepState { done, active, rejected, pending }

// ---------------------------------------------------------------------
// Same torn-ticket painter concept used on the Support page header,
// but parameterized entirely by gradientColors so it can be recolored
// per-status here instead of always being brand red.
// ---------------------------------------------------------------------
class _StatusTicketPainter extends CustomPainter {
  final double dashX;
  final List<Color> gradientColors;

  _StatusTicketPainter({required this.dashX, required this.gradientColors});

  @override
  void paint(Canvas canvas, Size size) {
    final cardRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );
    final cardPath = Path()..addRRect(cardRRect);

    const notchRadius = 12.0;
    final notchesPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(dashX, 0), radius: notchRadius))
      ..addOval(Rect.fromCircle(center: Offset(dashX, size.height), radius: notchRadius));

    final ticketPath = Path.combine(PathOperation.difference, cardPath, notchesPath);

    canvas.drawShadow(ticketPath, gradientColors.last.withOpacity(0.5), 12, false);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(ticketPath, fillPaint);

    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1.4;
    const dashLen = 5.0;
    const gapLen = 4.0;
    double y = notchRadius + 6;
    final bottomLimit = size.height - notchRadius - 6;
    while (y < bottomLimit) {
      final segmentEnd = (y + dashLen).clamp(0.0, bottomLimit);
      canvas.drawLine(Offset(dashX, y), Offset(dashX, segmentEnd), dashPaint);
      y += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(covariant _StatusTicketPainter oldDelegate) {
    return oldDelegate.dashX != dashX || oldDelegate.gradientColors != gradientColors;
  }
}