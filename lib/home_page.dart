import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_info_page.dart';
import 'submission_hub.dart'; // Ensure this file exists
import 'stub_page.dart';
import 'track_status_page.dart';
import 'support_page.dart';
import 'login_page.dart';

class UserModel {
  final String name;
  final String email;
  final String applicationStatus;

  UserModel({required this.name, required this.email, required this.applicationStatus});
}

class NotificationItem {
  final String title;
  final String message;
  final String time;
  bool read;

  NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    this.read = false,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  UserModel currentUser = UserModel(
    name: "Student",
    email: "",
    applicationStatus: "No active application",
  );
  bool _loadingUser = true;
  String? _profileImageUrl;
  late final AnimationController _pulseController =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  // Expanding "live alert" ring — separate from the opacity pulse above,
  // this one runs one-directional and loops, like a radar ping.
  late final AnimationController _pingController =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  // ---------------------------------------------------------------------
  // Entrance animation — one-shot controller that drives a staggered
  // fade + gentle rise for the hero card, then announcements, then the
  // quick action tiles (each tile slightly offset from the last so they
  // "cascade" in rather than popping together).
  // ---------------------------------------------------------------------
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  final List<NewsItem> newsItems = [
    NewsItem(
      title: "New Requirements",
      description: "The requirements list for 2026 Academic Aid has been updated. Please review before applying.",
    ),
    NewsItem(
      title: "Scholarship Portal Open",
      description: "Applications for the new scholarship cycle are now open. Submit early to avoid delays.",
    ),
    NewsItem(
      title: "Free Wheelchair for Senior Citizen",
      description: "Mayor Collantes personally gave a free wheelchair to a senior citizen from Brgy. Janopol Occidental to support his mobility.",
    ),
    NewsItem(
      title: "DSWD AICS Assistance Ongoing",
      description: "The City Government and Cong. Collantes continue providing medical, hospitalization, and mortuary assistance to Batangueños.",
    ),
    NewsItem(
      title: "Tanauan Joins RPVARA Forum",
      description: "City officials joined the DOF-BLGF National Forum on the Real Property Valuation and Assessment Reform Act in Taguig City.",
    ),
    NewsItem(
      title: "Pizza Hut Opens in Tanauan",
      description: "Congrats to Pizza Hut Tanauan on their first branch along J.P. Laurel Highway, Poblacion 4 — a boost to our local economy!",
    ),
    NewsItem(
      title: "Nutri-Infomercial Contest 2026",
      description: "JHS & SHS students: join this Nutrition Month video contest with the theme 'Nutrisyon at Kalikasan, Ating Pangalagaan!'",
    ),
    NewsItem(
      title: "Eco Nutri Walk & Tree Planting",
      description: "Join the Nutrition Month walk and tree planting on July 25, 2026, 5:00 AM at Brgy. Gonzales-Bañadero Baywalk.",
    ),
    NewsItem(
      title: "Free Skills Training: Nail Care",
      description: "CCLEDO Tanauan offers free Beauty Care: Nail Care skills training for Tanaueños, a City Government initiative.",
    ),
  ];

  // Empty for now — populate this (or wire it up to a real notifications
  // source) whenever we're ready to actually notify students.
  final List<NotificationItem> notifications = [];

  int _currentNewsIndex = 0;

  int get _unreadCount => notifications.where((n) => !n.read).length;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _entranceController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pingController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  // Wraps [child] in a fade + subtle upward-rise reveal, timed to a slice
  // of the shared _entranceController's 0..1 timeline. Call with
  // increasing (start, end) pairs in build order to get a cascading,
  // "each section/icon appears after the last" effect.
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

  // Pulls the logged-in student's real name from the profiles table
  // (the first_name/last_name captured at registration), plus their
  // uploaded photo from student_details.image_url (same row the
  // Student Profile page writes to), so the hero card greets the
  // actual account — name AND face — not a hardcoded placeholder.
  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loadingUser = false);
      return;
    }

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('id, first_name, last_name')
          .eq('firebase_uid', user.uid)
          .maybeSingle();

      final firstName = (profile?['first_name'] as String?)?.trim() ?? '';
      final lastName = (profile?['last_name'] as String?)?.trim() ?? '';
      final fullName = '$firstName $lastName'.trim();

      // student_details.id is the same id as profiles.id (1:1 FK), and
      // that's where the profile picture uploaded on the Student Profile
      // page actually lives.
      String? imageUrl;
      final profileId = profile?['id'] as String?;
      if (profileId != null) {
        final details = await Supabase.instance.client
            .from('student_details')
            .select('image_url')
            .eq('id', profileId)
            .maybeSingle();
        imageUrl = details?['image_url'] as String?;
      }

      // Pull the latest application's status too, same source the
      // Application Hub reads from, so the hero card reflects reality
      // instead of the hardcoded placeholder.
      String applicationStatus = "No active application";
      if (profileId != null) {
        final application = await Supabase.instance.client
            .from('applications')
            .select('status')
            .eq('student_id', profileId)
            .order('applied_at', ascending: false)
            .limit(1)
            .maybeSingle();
        final status = (application?['status'] as String?)?.trim();
        if (status != null && status.isNotEmpty) {
          applicationStatus = status;
        }
      }

      if (mounted) {
        setState(() {
          currentUser = UserModel(
            name: fullName.isNotEmpty ? fullName : (user.email ?? "Student"),
            email: user.email ?? '',
            applicationStatus: applicationStatus,
          );
          _profileImageUrl = imageUrl;
        });
      }
    } catch (e) {
      debugPrint("Error loading user profile: $e");
    } finally {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  // ---------------------------------------------------------------------
  // Back button: confirm, then log out and return to Login (not Welcome).
  // ---------------------------------------------------------------------
  Future<bool> _confirmLogoutAndExit() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Log Out?", style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text("You'll need to log in again to access your account."),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: TextStyle(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Log Out", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        // Clears the entire navigation stack so there's nothing left to
        // "back" into — the next back press from Login exits the app.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    }
    return false; // We handle navigation ourselves either way.
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _confirmLogoutAndExit();
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text(
            'Tanauan Assistance',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: Colors.red.shade800,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            _buildNotificationBell(),
            const SizedBox(width: 6),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero card — first to appear.
              _fadeIn(_buildHeroCard(currentUser), start: 0.0, end: 0.45),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Announcements — fades in next, slightly overlapping
                    // the tail end of the hero card's reveal.
                    _fadeIn(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Announcements',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          _buildNewsCarousel(),
                          const SizedBox(height: 10),
                          _buildNewsDots(),
                        ],
                      ),
                      start: 0.18,
                      end: 0.58,
                    ),
                    const SizedBox(height: 26),
                    // Quick Actions header — fades in after announcements.
                    _fadeIn(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Actions',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Jump straight to what you need.',
                            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      start: 0.38,
                      end: 0.68,
                    ),
                    const SizedBox(height: 14),
                    // Each quick-action tile cascades in one after another.
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.98,
                      children: [
                        _fadeIn(
                          _buildActionTile(
                            icon: BootstrapIcons.file_earmark_text_fill,
                            title: "Application Hub",
                            subtitle: "Apply or manage",
                            accent: Colors.red.shade800,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SubmissionHubPage()),
                              );
                              // Status may have changed (new submission, etc.) —
                              // refresh so the hero card reflects it right away.
                              _loadUserProfile();
                            },
                          ),
                          start: 0.48,
                          end: 0.85,
                        ),
                        _fadeIn(
                          _buildActionTile(
                            icon: BootstrapIcons.receipt,
                            title: "Stub",
                            subtitle: "View your payout",
                            accent: Colors.teal.shade600,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const StubPage()),
                            ),
                          ),
                          start: 0.56,
                          end: 0.90,
                        ),
                        _fadeIn(
                          _buildActionTile(
                            icon: BootstrapIcons.graph_up_arrow,
                            title: "Track Status",
                            subtitle: "Check progress",
                            accent: Colors.blue.shade700,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const TrackStatusPage()),
                            ),
                          ),
                          start: 0.64,
                          end: 0.95,
                        ),
                        _fadeIn(
                          _buildActionTile(
                            icon: BootstrapIcons.headset,
                            title: "Support",
                            subtitle: "Get help",
                            accent: Colors.amber.shade800,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SupportPage()),
                            ),
                          ),
                          start: 0.72,
                          end: 1.0,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Notification bell with unread badge + bottom sheet list.
  // ---------------------------------------------------------------------
  Widget _buildNotificationBell() {
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(BootstrapIcons.bell, color: Colors.white),
          if (_unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  '$_unreadCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      onPressed: _showNotifications,
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Notifications',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          if (_unreadCount > 0)
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  setState(() {
                                    for (final n in notifications) {
                                      n.read = true;
                                    }
                                  });
                                });
                              },
                              child: const Text('Mark all read', style: TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: notifications.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(BootstrapIcons.bell_slash, size: 22, color: Colors.grey.shade400),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    "No notifications yet",
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey.shade700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "We'll let you know when there's an update.",
                                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              itemCount: notifications.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final n = notifications[index];
                                return ListTile(
                                  onTap: () {
                                    setModalState(() {
                                      setState(() => n.read = true);
                                    });
                                  },
                                  leading: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: n.read ? Colors.grey.shade100 : Colors.red.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      BootstrapIcons.bell_fill,
                                      size: 16,
                                      color: n.read ? Colors.grey.shade400 : Colors.red.shade800,
                                    ),
                                  ),
                                  title: Text(
                                    n.title,
                                    style: TextStyle(
                                      fontWeight: n.read ? FontWeight.w500 : FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(
                                      n.message,
                                      style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                                    ),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(n.time, style: const TextStyle(fontSize: 11, color: Colors.black38)),
                                      if (!n.read) ...[
                                        const SizedBox(height: 6),
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade800,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // Hero card — deep red-to-maroon gradient with a quiet watermark of
  // concentric rings (civic/seal motif, fitting a city assistance app),
  // an eyebrow + name hierarchy, and a gradient-ring avatar. The one bold
  // move on the card is the status badge's live ping when nothing is on
  // file — everything else stays deliberately quiet around it.
  // ---------------------------------------------------------------------
  // Status badge — color-coded by application status. "No active
  // application" gets a genuine live-alert treatment: a small dot that
  // pings outward on loop, the way a recording or live indicator would,
  // so it actually reads as "this needs attention" rather than a
  // barely-there fade.
  // ---------------------------------------------------------------------
  ({Color color, IconData icon, bool pulse}) _statusStyle(String status) {
    final s = status.toLowerCase();
    if (s.contains('no active') || s.contains('none')) {
      return (color: Colors.red.shade400, icon: BootstrapIcons.exclamation_triangle_fill, pulse: true);
    }
    if (s.contains('reject') || s.contains('denied')) {
      return (color: Colors.red.shade400, icon: BootstrapIcons.x_circle_fill, pulse: false);
    }
    if (s.contains('pending') || s.contains('review') || s.contains('process')) {
      return (color: Colors.amber.shade400, icon: BootstrapIcons.hourglass_split, pulse: false);
    }
    if (s.contains('approve') || s.contains('active') || s.contains('claim')) {
      return (color: Colors.green.shade400, icon: BootstrapIcons.check_circle_fill, pulse: false);
    }
    return (color: Colors.white70, icon: BootstrapIcons.info_circle, pulse: false);
  }

  // Small "live" dot with an expanding, fading ring behind it — the
  // signature attention-grabber for the warning state.
  Widget _buildPingDot(Color color) {
    return SizedBox(
      width: 10,
      height: 10,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _pingController,
            builder: (context, child) {
              final t = _pingController.value;
              return Opacity(
                opacity: (1 - t).clamp(0.0, 1.0) * 0.65,
                child: Transform.scale(
                  scale: 1 + t * 2.4,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                ),
              );
            },
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.7), blurRadius: 5)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final style = _statusStyle(status);

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: style.color.withOpacity(0.20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.color.withOpacity(0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (style.pulse) ...[
            _buildPingDot(style.color),
            const SizedBox(width: 7),
          ] else ...[
            Icon(style.icon, color: style.color, size: 13),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              "Status: $status",
              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (!style.pulse) return badge;

    // Subtle breathing glow around the whole pill, layered on top of the
    // ping dot, so the warning reads clearly without feeling frantic.
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glow = _pulseController.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: style.color.withOpacity(0.12 + glow * 0.22),
                blurRadius: 6 + glow * 10,
                spreadRadius: glow * 1.5,
              ),
            ],
          ),
          child: child,
        );
      },
      child: badge,
    );
  }

  // Faint concentric rings bleeding off the corner — a quiet civic-seal
  // watermark rather than a flat block of color.
  Widget _buildHeroWatermark() {
    Widget ring(double size) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.06), width: 1.2),
          ),
        );

    return Positioned(
      top: -40,
      right: -40,
      child: IgnorePointer(
        child: Stack(
          alignment: Alignment.center,
          children: [ring(170), ring(120), ring(70)],
        ),
      ),
    );
  }

  Widget _buildHeroCard(UserModel user) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red.shade800, Color.lerp(Colors.red.shade800, Colors.black, 0.24)!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade800.withOpacity(0.30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            _buildHeroWatermark(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "WELCOME BACK",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _loadingUser
                            ? Container(
                                width: 140,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              )
                            : Text(
                                user.name,
                                style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold, height: 1.15),
                              ),
                        const SizedBox(height: 14),
                        _buildStatusBadge(user.applicationStatus),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(27),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const StudentInfoPage()),
                      );
                      // Photo (or name) may have changed while on the profile page —
                      // refresh so the hero card reflects it right away.
                      _loadUserProfile();
                    },
                    child: Container(
                      width: 54,
                      height: 54,
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.25)],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 24.5, // fills the 54px ring (minus 2.5px padding each side)
                        backgroundColor: Colors.red.shade900,
                        backgroundImage: (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                            ? NetworkImage(_profileImageUrl!)
                            : null,
                        child: (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                            ? const Icon(BootstrapIcons.person_circle, color: Colors.white, size: 30)
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Announcements — bigger type, clearer hierarchy, smooth auto-play.
  // ---------------------------------------------------------------------
  Widget _buildNewsCarousel() {
    return CarouselSlider.builder(
      itemCount: newsItems.length,
      options: CarouselOptions(
        height: 130,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 5),
        autoPlayAnimationDuration: const Duration(milliseconds: 700),
        autoPlayCurve: Curves.easeInOutCubic,
        viewportFraction: 0.92,
        enlargeCenterPage: true,
        enlargeFactor: 0.12,
        onPageChanged: (index, reason) {
          setState(() => _currentNewsIndex = index);
        },
      ),
      itemBuilder: (context, index, realIdx) {
        final item = newsItems[index];
        final isFirst = index == 0;
        return AnimatedScale(
          scale: _currentNewsIndex == index ? 1.0 : 0.96,
          duration: const Duration(milliseconds: 300),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(BootstrapIcons.megaphone_fill, size: 18, color: Colors.red.shade800),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade800,
                                fontSize: 15,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isFirst) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.description,
                        style: const TextStyle(fontSize: 12.5, color: Colors.black54, height: 1.4),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewsDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(newsItems.length, (index) {
        final isActive = _currentNewsIndex == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isActive ? Colors.red.shade800 : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------
  // Quick Action tile — gradient icon badge + subtitle + accent per action,
  // matching the option-card language used across the hub and forms.
  // ---------------------------------------------------------------------
  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        splashColor: accent.withOpacity(0.08),
        highlightColor: accent.withOpacity(0.04),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(BootstrapIcons.arrow_up_right, color: accent, size: 12),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.black87),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewsItem {
  final String title;
  final String description;
  NewsItem({required this.title, required this.description});
}