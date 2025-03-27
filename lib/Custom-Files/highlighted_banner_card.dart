import 'package:flutter/material.dart';

class HighlightedBannerCard extends StatelessWidget {
  final String bannerText;
  final Widget cardContent;

  const HighlightedBannerCard({
    super.key,
    required this.bannerText,
    required this.cardContent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4, // Shadow for the card
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Rounded corners
      ),
      child: Stack(
        children: [
          // Main card content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: cardContent,
          ),
          // Highlighted banner at top-left
          Positioned(
            top: 0,
            left: 0,
            child: _buildBanner(),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.orange,
      child: Transform.rotate(
        angle: -45 * 3.14159 / 180,
        child: Text(
          bannerText,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// Custom clipper for triangular banner shape
class BannerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0) // Top-left
      ..lineTo(size.width, 0) // Top-right
      ..lineTo(0, size.height) // Bottom-left
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// Example usage
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Card with 45° Banner')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: HighlightedBannerCard(
            bannerText: "New",
            cardContent: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20), // Space to avoid overlap
                const Text(
                  "Product Name",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text("This is a description of the product."),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text("View Details"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
