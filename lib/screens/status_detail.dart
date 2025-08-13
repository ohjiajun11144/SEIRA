import 'package:flutter/material.dart';
import 'full_screen_image.dart';

class StatusDetailPage extends StatelessWidget {
  final String reportId;
  final String type;
  final String status;
  final String location;
  final String date;
  final String time;
  final String handledBy;
  final String description;
  final String image;

  const StatusDetailPage({
    super.key,
    required this.reportId,
    required this.type,
    required this.status,
    required this.location,
    required this.date,
    required this.time,
    required this.handledBy,
    required this.description,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    switch (status.toLowerCase()) {
      case 'pending':
        borderColor = Colors.orange;
        break;
      case 'received':
        borderColor = Colors.blue;
        break;
      case 'completed':
        borderColor = Colors.green;
        break;
      default:
        borderColor = Colors.grey;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Report Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (image.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImagePage(imageUrl: image),
                    ),
                  );
                },
                child: Hero(
                  tag: image,
                  child: Image.network(
                    image,
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 80),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text("Report ID: $reportId", style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 10),
            Text("Type: $type", style: const TextStyle(fontSize: 22)), // updated from Category to Type
            const SizedBox(height: 10),
            Text(
              "Status: $status",
              style: TextStyle(
                fontSize: 22,
                color: borderColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text("Location: $location", style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            Text("Date: $date", style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            Text("Time: $time", style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            Text("Handled By: $handledBy", style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            Text(
              "Description:",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(description, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
