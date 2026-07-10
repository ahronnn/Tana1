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

class _HomePageState extends State<HomePage> {
  UserModel currentUser = UserModel(
    name: "Student",
    email: "",
    applicationStatus: "No active application",
  );
  bool _loadingUser = true;

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

  final List<NotificationItem> notifications = [
    NotificationItem(
      title: "Application Received",
      message: "Your application has been received and is awaiting review.",
      time: "2h ago",
    ),
    NotificationItem(
      title: "Document Reminder",
      message: "Please upload your Certificate of Registration to complete your requirements.",
      time: "1d ago",
    ),
    NotificationItem(
      title: "Payout Schedule Posted",
      message: "Batch 2 payout schedule has been posted. Check the Announcements section.",
      time: "3d ago",
      read: true,
    ),
  ];

  int _currentNewsIndex = 0;

  int get _unreadCount => notifications.where((n) => !n.read).length;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Pulls the logged-in student's real name from the profiles table
  // (the first_name/last_name captured at registration) so the hero
  // card greets the actual account, not a hardcoded placeholder.
  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loadingUser = false);
      return;
    }

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('first_name, last_name')
          .eq('firebase_uid', user.uid)
          .maybeSingle();

      final firstName = (data?['first_name'] as String?)?.trim() ?? '';
      final lastName = (data?['last_name'] as String?)?.trim() ?? '';
      final fullName = '$firstName $lastName'.trim();

      if (mounted) {
        setState(() {
          currentUser = UserModel(
            name: fullName.isNotEmpty ? fullName : (user.email ?? "Student"),
            email: user.email ?? '',
            applicationStatus: currentUser.applicationStatus,
          );
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
              _buildHeroCard(currentUser),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
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
                    const SizedBox(height: 24),
                    const Text(
                      'Quick Actions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.3,
                      children: [
                        _buildActionTile(
                          BootstrapIcons.file_earmark_text,
                          "Application Hub",
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SubmissionHubPage()),
                          ),
                        ),
                        _buildActionTile(
                          BootstrapIcons.receipt,
                          "Stub",
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const StubPage()),
                          ),
                        ),
                        _buildActionTile(
                          BootstrapIcons.graph_up,
                          "Track Status",
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TrackStatusPage()),
                          ),
                        ),
                        _buildActionTile(
                          BootstrapIcons.question_circle,
                          "Support",
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SupportPage()),
                          ),
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
                          ? const Center(child: Text('No notifications yet'))
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
  // Hero card — profile button now sits top-right, inside the card.
  // ---------------------------------------------------------------------
  Widget _buildHeroCard(UserModel user) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade800,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome back,",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 2),
                _loadingUser
                    ? Container(
                        width: 140,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      )
                    : Text(
                        user.name,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                const SizedBox(height: 14),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(BootstrapIcons.info_circle, color: Colors.white70, size: 14),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        "Status: ${user.applicationStatus}",
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StudentInfoPage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
              child: const Icon(BootstrapIcons.person_circle, color: Colors.white, size: 30),
            ),
          ),
        ],
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

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.red.shade800),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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