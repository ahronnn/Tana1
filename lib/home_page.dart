import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'student_info_page.dart';
import 'submission_hub.dart'; // Ensure this file exists

class UserModel {
  final String name;
  final String email;
  final String applicationStatus;

  UserModel({required this.name, required this.email, required this.applicationStatus});
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final UserModel currentUser = UserModel(
    name: "Ahron John",
    email: "ahron@tana1app.com",
    applicationStatus: "No active application",
  );

  final List<NewsItem> newsItems = [
    NewsItem(title: "Batch 2 Payout Schedule", description: "Scheduled for July 15, 2026."),
    NewsItem(title: "New Requirements", description: "Check the updated list for 2026 Academic Aid."),
    NewsItem(title: "Scholarship Portal Open", description: "Accepting applications now."),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Tanauan Assistance', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.red.shade800,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(BootstrapIcons.person_circle, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StudentInfoPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(currentUser),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Announcements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildNewsCarousel(),
                  const SizedBox(height: 25),
                  const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.3,
                    children: [
                      _buildActionTile(BootstrapIcons.file_earmark_text, "Application Hub", Colors.red.shade900, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SubmissionHubPage()));
                      }),
                      _buildActionTile(BootstrapIcons.upload, "Upload Files", Colors.blue, () {}),
                      _buildActionTile(BootstrapIcons.graph_up, "Track Status", Colors.green, () {}),
                      _buildActionTile(BootstrapIcons.question_circle, "Support", Colors.purple, () {}),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(UserModel user) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade900, Colors.red.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Welcome back,", style: TextStyle(color: Colors.white70, fontSize: 16)),
          Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
            child: Text("Status: ${user.applicationStatus}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCarousel() {
    return CarouselSlider.builder(
      itemCount: newsItems.length,
      options: CarouselOptions(height: 100, autoPlay: true, autoPlayInterval: const Duration(seconds: 6), viewportFraction: 0.95, enlargeCenterPage: true),
      itemBuilder: (context, index, realIdx) {
        final item = newsItems[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red), textAlign: TextAlign.center),
                Text(item.description, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 35, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
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