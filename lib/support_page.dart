import 'package:flutter/material.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> with TickerProviderStateMixin {
  final List<Map<String, String>> _faqs = const [
    {
      "q": "How do I apply for educational assistance?",
      "a": "Go to the Application Hub from the home screen and select 'New Application' if this is your first time, or 'Repeat Availers' if you're a returning availer."
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

  // One-shot controller that staggers the hero header, contact cards,
  // and FAQ section into view — same cascading fade-in language used on
  // the Home page, so navigating here doesn't feel like a different app.
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );

  @override
  void initState() {
    super.initState();
    _entranceController.forward();
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

  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Future<void> _launchEmail() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final studentEmail = (firebaseUser?.email?.trim().isNotEmpty ?? false)
        ? firebaseUser!.email!
        : 'Not logged in';

    final subject = 'Support Request - Tanauan Assistance App';
    final body = '''
Hi Tanauan Educational Assistance Support Team,

I have a concern regarding my application. Details below:

Student Email: $studentEmail
Concern:
(Please describe your issue here)

Thank you.
''';

    final uri = Uri(
      scheme: 'mailto',
      path: 'tana1educational@gmail.com',
      query: _encodeQueryParameters({
        'subject': subject,
        'body': body,
      }),
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            backgroundColor: Colors.red.shade900,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              "Support",
              style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
            ),
            centerTitle: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _fadeIn(_buildHeroHeader(), start: 0.0, end: 0.45),
                const SizedBox(height: 20),
                _fadeIn(_buildContactRow(), start: 0.18, end: 0.6),
                const SizedBox(height: 28),
                _fadeIn(_buildFaqHeader(), start: 0.32, end: 0.68),
                const SizedBox(height: 14),
                ..._buildFaqList(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Hero header — shaped like an actual ticket stub: perforated notch
  // cutouts on the top/bottom edge, a dashed tear-line, and a vertical
  // "SUPPORT" stub on the right. Ties into the app's own Stub/ticket
  // language instead of reusing the Home page's ring watermark.
  // ---------------------------------------------------------------------
  Widget _buildHeroHeader() {
    const double stubWidth = 84;
    const double cardHeight = 168;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final dashX = width - stubWidth;

        return SizedBox(
          height: cardHeight,
          width: width,
          child: Stack(
            children: [
              // Painted ticket body: gradient fill, rounded corners, and
              // the two semicircle "punch" notches cut out of the edges.
              Positioned.fill(
                child: CustomPaint(
                  painter: _TicketCardPainter(
                    dashX: dashX,
                    notchColor: const Color(0xFFF8F9FA), // matches Scaffold bg so it reads as cut out
                    gradientColors: [
                      Colors.red.shade800,
                      Color.lerp(Colors.red.shade800, Colors.black, 0.24)!,
                    ],
                  ),
                ),
              ),
              // Main content — left of the tear-line.
              Positioned(
                left: 22,
                right: stubWidth + 6,
                top: 0,
                bottom: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "We're here to help",
                      style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold, height: 1.15),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Reach the office directly, or check the FAQs below.",
                      style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(BootstrapIcons.clock_history, color: Colors.white, size: 11),
                          const SizedBox(width: 5),
                          Text(
                            "Avg. reply within 24 hrs",
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 10.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Stub — right of the tear-line, like a ticket you'd tear off.
              Positioned(
                left: dashX,
                top: 0,
                bottom: 0,
                width: stubWidth,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(BootstrapIcons.headset, color: Colors.white, size: 20),
                      const SizedBox(height: 10),
                      RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          "SUPPORT",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
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
  // Contact cards — gradient icon badges matching the Quick Action tile
  // language from Home, instead of plain outlined/filled buttons.
  // ---------------------------------------------------------------------
  Widget _buildContactRow() {
    return Row(
      children: [
        Expanded(
          child: _buildContactCard(
            icon: BootstrapIcons.envelope_fill,
            title: "Email",
            subtitle: "tana1educational@gmail.com",
            accent: Colors.blue.shade700,
            onTap: _launchEmail,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildContactCard(
            icon: BootstrapIcons.telephone_fill,
            title: "Call",
            subtitle: "Office hotline",
            accent: Colors.green.shade700,
            onTap: _launchPhone,
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        splashColor: accent.withOpacity(0.08),
        highlightColor: accent.withOpacity(0.04),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.10),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent, Color.lerp(accent, Colors.black, 0.15)!],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.black87),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // FAQ section — animated expandable cards with a colored accent bar
  // and a rotating chevron, replacing the default ExpansionTile.
  // ---------------------------------------------------------------------
  Widget _buildFaqHeader() {
    return Row(
      children: [
        Icon(BootstrapIcons.question_circle_fill, size: 16, color: Colors.grey.shade700),
        const SizedBox(width: 6),
        const Text(
          "Frequently Asked Questions",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  List<Widget> _buildFaqList() {
    return [
      for (final faq in _faqs)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _FaqTile(question: faq["q"]!, answer: faq["a"]!),
        ),
    ];
  }
}

// ---------------------------------------------------------------------
// Paints the ticket-stub hero: a rounded gradient card with two
// semicircle "notches" punched out of the top/bottom edges (via
// Path.combine difference) plus a dashed line, so it reads as an actual
// tear-off ticket rather than a plain gradient rectangle.
// ---------------------------------------------------------------------
class _TicketCardPainter extends CustomPainter {
  final double dashX;
  final Color notchColor;
  final List<Color> gradientColors;

  _TicketCardPainter({
    required this.dashX,
    required this.notchColor,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cardRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(22),
    );
    final cardPath = Path()..addRRect(cardRRect);

    const notchRadius = 13.0;
    final notchesPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(dashX, 0), radius: notchRadius))
      ..addOval(Rect.fromCircle(center: Offset(dashX, size.height), radius: notchRadius));

    final ticketPath = Path.combine(PathOperation.difference, cardPath, notchesPath);

    canvas.drawShadow(ticketPath, Colors.red.shade900.withOpacity(0.5), 14, false);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(ticketPath, fillPaint);

    // Dashed tear-line running down from notch to notch.
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
  bool shouldRepaint(covariant _TicketCardPainter oldDelegate) {
    return oldDelegate.dashX != dashX ||
        oldDelegate.notchColor != notchColor ||
        oldDelegate.gradientColors != gradientColors;
  }
}

// ---------------------------------------------------------------------
// Custom FAQ tile — accent bar + rotating chevron + AnimatedSize reveal,
// swapped in for the default ExpansionTile for a more deliberate feel.
// ---------------------------------------------------------------------
class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _expanded ? Colors.red.shade200 : Colors.grey.shade200,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 4,
                margin: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _expanded ? Colors.red.shade800 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                constraints: const BoxConstraints(minHeight: 20),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.question,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                                color: _expanded ? Colors.red.shade900 : Colors.black87,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: _expanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: Icon(
                              BootstrapIcons.chevron_down,
                              size: 15,
                              color: _expanded ? Colors.red.shade800 : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        child: _expanded
                            ? Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  widget.answer,
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5, height: 1.4),
                                ),
                              )
                            : const SizedBox(width: double.infinity),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}