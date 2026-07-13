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
    {
      "q": "What documents do I need to apply?",
      "a": "New applicants need an Application Letter, Birth Certificate, and Proof of Enrollment. Returning availers just need an updated Report Card/Transcript and Proof of Enrollment."
    },
    {
      "q": "Can I apply again if I've already received assistance before?",
      "a": "Yes — select 'Repeat Availers' in the Application Hub and submit your updated Report Card/Transcript and Proof of Enrollment."
    },
    {
      "q": "How many times can I avail of the assistance?",
      "a": "Only one active application is allowed per school year. You can apply again as a Repeat Availer once a new school year starts."
    },
    {
      "q": "My name doesn't match my school records — what should I do?",
      "a": "Make sure the name on your application matches your school records exactly before submitting — mismatches are a common reason for delays or rejection."
    },
    {
      "q": "How do I update my personal information or profile photo?",
      "a": "Tap your profile photo in the top-right of the Home screen to open your Student Profile. You can edit your details or photo there, then tap Save Changes."
    },
    {
      "q": "I forgot my password — how do I log back in?",
      "a": "Tap 'Forgot Password' on the login screen and follow the instructions sent to your registered email to reset it."
    },
    {
      "q": "What happens if my application is rejected?",
      "a": "You'll see the reason under Track Status. Review your documents and, once the issue is fixed, you're welcome to submit a new application in the next application period."
    },
    {
      "q": "How long does it take to review my application?",
      "a": "Review times can vary depending on volume, but you can always check the latest status under Track Status. Contact support if it's been an unusually long wait."
    },
  ];

  // One-shot controller that staggers the hero header, contact cards,
  // and cards into view — same cascading fade-in language used on
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

  void _openChat({String? initialQuery}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChatWithJuanSheet(
        faqs: _faqs,
        onEmailSupport: _launchEmail,
        initialQuery: initialQuery,
      ),
    );
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _fadeIn(_buildHeroHeader(), start: 0.0, end: 0.45),
                const SizedBox(height: 20),
                _fadeIn(_buildContactRow(), start: 0.18, end: 0.6),
                const SizedBox(height: 20),
                _fadeIn(_buildAskJuanCard(), start: 0.32, end: 0.68),
                const SizedBox(height: 20),
                _fadeIn(_buildOfficeInfoCard(), start: 0.46, end: 0.82),
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
  // Ask Juan — the main promo card pointing people at the chatbot, now
  // that the FAQ answers live there instead of a static list on this
  // page. Includes a couple of example questions people can tap to
  // jump straight into the chat with that question already sent.
  // ---------------------------------------------------------------------
  Widget _buildAskJuanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red.shade800, Color.lerp(Colors.red.shade800, Colors.black, 0.22)!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade800.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(BootstrapIcons.chat_dots_fill, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Have a question? Ask Juan",
                  style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.bold, height: 1.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Our assistant can answer common questions about applying, tracking your status, and claiming assistance — instantly.",
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12.5, height: 1.45),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _openChat(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: Icon(BootstrapIcons.chat_dots_fill, size: 16, color: Colors.red.shade800),
              label: Text(
                "Chat with Juan",
                style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Office info — practical details that belong on a support page and
  // give this space real purpose instead of leaving it empty after the
  // FAQ list moved into the chat. Replace the placeholder text with your
  // office's real address and hours.
  // ---------------------------------------------------------------------
  Widget _buildOfficeInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(BootstrapIcons.building, size: 16, color: Colors.grey.shade700),
              const SizedBox(width: 6),
              const Text(
                "Visit the Office",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            icon: BootstrapIcons.geo_alt_fill,
            label: "Address",
            value: "Tanauan City Hall, J.P. Laurel Highway, Tanauan City, Batangas",
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: BootstrapIcons.clock_fill,
            label: "Office Hours",
            value: "Monday – Friday, 8:00 AM – 5:00 PM",
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 15, color: Colors.red.shade800),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.35)),
            ],
          ),
        ),
      ],
    );
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

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

class ChatWithJuanSheet extends StatefulWidget {
  final List<Map<String, String>> faqs;
  final VoidCallback onEmailSupport;
  final String? initialQuery;

  const ChatWithJuanSheet({super.key, required this.faqs, required this.onEmailSupport, this.initialQuery});

  @override
  State<ChatWithJuanSheet> createState() => _ChatWithJuanSheetState();
}

class _ChatWithJuanSheetState extends State<ChatWithJuanSheet> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  static const _stopWords = {
    'the', 'a', 'an', 'is', 'my', 'do', 'does', 'how', 'what', 'where',
    'i', 'to', 'for', 'of', 'in', 'on', 'it', 'can', 'will', 'am', 'be',
  };

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(
      text: "Hi, I'm Juan! 👋 I can help with questions about applying, tracking your status, or claiming your assistance. What do you need help with?",
      isUser: false,
    ));

    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(widget.initialQuery!));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _findAnswer(String input) {
    final queryWords = input
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((w) => w.isNotEmpty && !_stopWords.contains(w))
        .toSet();

    if (queryWords.isEmpty) {
      return "Could you tell me a bit more about what you need? You can ask about applying, your status, claiming, or ticket numbers.";
    }

    String? bestAnswer;
    int bestScore = 0;

    for (final faq in widget.faqs) {
      final haystack = ('${faq['q']} ${faq['a']}').toLowerCase();
      int score = 0;
      for (final w in queryWords) {
        if (haystack.contains(w)) score++;
      }
      if (score > bestScore) {
        bestScore = score;
        bestAnswer = faq['a'];
      }
    }

    if (bestScore == 0 || bestAnswer == null) {
      return "Hmm, I'm not totally sure about that one 🤔 Tap the Email button below and our support team will help you directly.";
    }
    return bestAnswer;
  }

  void _send(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: trimmed, isUser: true));
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Small simulated delay so replies feel conversational rather than instant.
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(text: _findAnswer(trimmed), isUser: false));
        _isTyping = false;
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // Suggestions that refresh after every reply — excludes questions the
  // user already asked (matched by exact text, since chip taps send the
  // FAQ's question verbatim) so tapping through chips keeps surfacing new
  // ones instead of repeating the same set forever. Once everything's
  // been asked, it just cycles back through the full list again.
  List<String> get _suggestedQuestions {
    final asked = _messages
        .where((m) => m.isUser)
        .map((m) => m.text.trim().toLowerCase())
        .toSet();

    final unused = widget.faqs
        .map((f) => f['q']!)
        .where((q) => !asked.contains(q.trim().toLowerCase()))
        .toList();

    final pool = unused.isNotEmpty ? unused : widget.faqs.map((f) => f['q']!).toList();
    return pool.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.red.shade700, Color.lerp(Colors.red.shade800, Colors.black, 0.2)!],
                        ),
                      ),
                      child: const Icon(BootstrapIcons.chat_dots_fill, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Juan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5)),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(color: Colors.green.shade500, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 5),
                              Text("Assistant \u00b7 auto-replies from FAQs",
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(BootstrapIcons.x_lg, size: 18, color: Colors.grey.shade500),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Messages
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  children: [
                    for (final m in _messages) _buildBubble(m),
                    if (_isTyping) _buildTypingBubble(),
                    if (!_isTyping) ...[
                      const SizedBox(height: 10),
                      Text(
                        "You can also ask:",
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final q in _suggestedQuestions)
                            ActionChip(
                              label: Text(q, style: const TextStyle(fontSize: 12)),
                              backgroundColor: Colors.red.shade50,
                              side: BorderSide(color: Colors.red.shade100),
                              onPressed: () => _send(q),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Input bar
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _controller,
                            onSubmitted: _send,
                            textInputAction: TextInputAction.send,
                            decoration: const InputDecoration(
                              hintText: "Ask Juan a question...",
                              hintStyle: TextStyle(fontSize: 13.5),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            ),
                            style: const TextStyle(fontSize: 13.5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.red.shade800,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _send(_controller.text),
                          child: const Padding(
                            padding: EdgeInsets.all(11),
                            child: Icon(BootstrapIcons.send_fill, color: Colors.white, size: 17),
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

  Widget _buildBubble(_ChatMessage m) {
    return Align(
      alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: m.isUser ? Colors.red.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(m.isUser ? 16 : 4),
            bottomRight: Radius.circular(m.isUser ? 4 : 16),
          ),
        ),
        child: Text(
          m.text,
          style: TextStyle(
            color: m.isUser ? Colors.white : Colors.black87,
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: SizedBox(
          width: 30,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle),
              ),
            )),
          ),
        ),
      ),
    );
  }
}