import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 1. Data List using the NewsItem model
  final List<NewsItem> newsItems = [
    NewsItem(
      title: "Batch 2 Payout Schedule",
      description: "Scheduled for July 15, 2026. Please check your emails.",
    ),
    NewsItem(
      title: "New Requirements",
      description: "Check the updated list for 2026 Academic Aid.",
    ),
    NewsItem(
      title: "Scholarship Portal Open",
      description: "Tanauan City Scholarship Portal is now accepting applications.",
    ),
    NewsItem(
      title: "Tanauan City Little League Baseball!",
      description: "Opisyal nang nagtapos ang 2026 Little League Asia-Pacific and Middle East Regional Tournament.",
    ),
    NewsItem(
      title: "Mga Bagong Pasilidad sa Lungsod ng Tanauan",
      description: "Bago at Mas pinagandang Bahay Pag-asa, Bahay Kanlungan at City Government Warehouse!.",
    ),
    NewsItem(
      title: "Paalala sa Tag-Ulan",
      description: "Magdala ng payong o kapote, mag-ingat sa pagmamaneho.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Tanauan Assistance', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {})
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 20),
            const Text('Announcements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildNewsCarousel(),
            const SizedBox(height: 25),
            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.2,
              children: [
                _buildActionTile(BootstrapIcons.upload, "Upload Files", Colors.blue),
                _buildActionTile(BootstrapIcons.file_earmark_text, "Requirements", Colors.orange),
                _buildActionTile(BootstrapIcons.graph_up, "Track Status", Colors.green),
                _buildActionTile(BootstrapIcons.question_circle, "Support", Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: const ListTile(
        leading: Icon(Icons.info_outline, color: Colors.grey),
        title: Text("Application Status"),
        subtitle: Text("No active application found.",
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
      ),
    );
  }

  // 2. Updated Carousel to read from the Model
  Widget _buildNewsCarousel() {
    return CarouselSlider.builder(
      itemCount: newsItems.length,
      options: CarouselOptions(
        height: 90,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 4),
        viewportFraction: 0.9,
        enlargeCenterPage: true,
      ),
      itemBuilder: (context, index, realIdx) {
        final item = newsItems[index];
        return Card(
          color: Colors.red[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  Text(item.description,
                      style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionTile(IconData icon, String title, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// 3. News Model remains at the bottom
class NewsItem {
  final String title;
  final String description;

  NewsItem({required this.title, required this.description});
}