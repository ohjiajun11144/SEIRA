import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home.dart';
import 'report_page.dart';
import 'profile.dart';
import 'status_detail.dart';

class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  User? _currentUser;
  int _selectedIndex = 1; // Changed from 2 to 1 (Status is at index 1)

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUser = user;
    }

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted && _currentUser == null && user != null) {
        setState(() {
          _currentUser = user;
        });
      }
    });
  }

  Color _getBorderColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'received':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusCard({
    required String reportId,
    required String type,
    required String status,
    required String location,
    required String date,
    required String time,
    required String handledBy,
    required String description,
    required String image,
  }) {
    final borderColor = _getBorderColor(status);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StatusDetailPage(
              reportId: reportId,
              type: type,
              status: status,
              location: location,
              date: date,
              time: time,
              handledBy: handledBy,
              description: description,
              image: image,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
          border: Border.all(color: borderColor, width: 3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (image.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(image, height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 8),
            Text("Type: $type", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("Status: $status", style: TextStyle(fontSize: 16, color: borderColor)),
            Text("Location: $location", style: const TextStyle(fontSize: 16)),
            Text("Date: $date", style: const TextStyle(fontSize: 16)),
            Text("Time: $time", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text("Description: $description", style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  // Custom nav item with border
  BottomNavigationBarItem _buildNavItem(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black45),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      label: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/image/background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Status',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('reports')
                          .where('userId', isEqualTo: _currentUser!.uid)
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(child: Text("No reports found.", style: TextStyle(color: Theme.of(context).colorScheme.onBackground)));
                        }

                        return ListView(
                          children: snapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;

                            return _buildStatusCard(
                              reportId: doc.id,
                              type: (data['type'] != null && data['type'].toString().trim().isNotEmpty)
                                  ? data['type'].toString()
                                  : 'Unknown',
                              status: data['status']?.toString() ?? 'Unknown',
                              location: data['location']?.toString() ?? 'Not provided',
                              date: data['date']?.toString() ?? 'Unknown',
                              time: data['time']?.toString() ?? 'Unknown',
                              handledBy: data['handledBy']?.toString() ?? 'Not assigned',
                              description: data['description']?.toString() ?? '',
                              image: data['image_url']?.toString() ?? '',
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == _selectedIndex) return;
          setState(() {
            _selectedIndex = index;
          });

          switch (index) {
            case 0:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainHomeScreen()));
              break;
            case 1:
            // Current page, no navigation needed
              break;
            case 2:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ReportPage()));
              break;
            case 3:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
              break;
          }
        },
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey[700],
        type: BottomNavigationBarType.fixed,
        items: [
          _buildNavItem(Icons.home, 'Home'),
          _buildNavItem(Icons.info, 'Status'),
          _buildNavItem(Icons.report, 'Report'),
          _buildNavItem(Icons.person, 'Profile'),
        ],
      ),
    );
  }
}
