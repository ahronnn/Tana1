import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Replace this with the actual user's name from your Auth/Database provider
  final String userName = "Ahron John"; 

  final List<NewsItem> newsItems = [
    NewsItem(title: "Batch 2 Payout Schedule", description: "Scheduled for July 15, 2026. Please check your emails."),
    NewsItem(title: "New Requirements", description: "Check the updated list for 2026 Academic Aid."),
    NewsItem(title: "Scholarship Portal Open", description: "Tanauan City Scholarship Portal is now accepting applications."),
    NewsItem(title: "Tanauan City Little League Baseball!", description: "Opisyal nang nagtapos ang 2026 Little League Asia-Pacific."),
    NewsItem(title: "Mga Bagong Pasilidad", description: "Bago at Mas pinagandang Bahay Pag-asa at Bahay Kanlungan!"),
    NewsItem(title: "Paalala sa Tag-Ulan", description: "Magdala ng payong o kapote, mag-ingat sa pagmamaneho."),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Tanauan Assistance', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.red.shade800,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.notifications_none, color: Colors.white), onPressed: () {})],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(userName), // Pass the dynamic name here
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
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
                      _buildActionTile(BootstrapIcons.upload, "Upload Files", Colors.blue),
                      _buildActionTile(BootstrapIcons.file_earmark_text, "Requirements", Colors.orange),
                      _buildActionTile(BootstrapIcons.graph_up, "Track Status", Colors.green),
                      _buildActionTile(BootstrapIcons.question_circle, "Support", Colors.purple),
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

  Widget _buildHeroSection(String name) {
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
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
            child: const Text("Status: Processing Application", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCarousel() {
    return CarouselSlider.builder(
      itemCount: newsItems.length,
      options: CarouselOptions(
        height: 100, 
        autoPlay: true, 
        autoPlayInterval: const Duration(seconds: 6), // Updated to 6 seconds
        viewportFraction: 0.95, 
        enlargeCenterPage: true
      ),
      itemBuilder: (context, index, realIdx) {
        final item = newsItems[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red), textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(item.description, style: const TextStyle(fontSize: 11, color: Colors.black87), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionTile(IconData icon, String title, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
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