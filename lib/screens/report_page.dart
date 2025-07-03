import 'package:flutter/material.dart';
import 'home.dart';
import 'status.dart';
import 'profile.dart';
import 'package:intl/intl.dart';
import 'department_selection.dart'; // adjust path if needed


class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  int _currentIndex = 2;
  String? _imagePath;
  final TextEditingController _commentController = TextEditingController();

  String getCurrentDateTime() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd – HH:mm:ss').format(now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          SizedBox.expand(
            child: Image.asset(
              'assets/image/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Container(color: Colors.black.withOpacity(0.3)),

          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  const Text(
                    'Report',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Map Placeholder
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Center(
                      child: Text(
                        'Map will appear here',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Date/Time
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Date/Time: ${getCurrentDateTime()}',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Camera
                  GestureDetector(
                    onTap: () {
                      // You will implement camera functionality here
                    },
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black87),
                      ),
                      child: _imagePath == null
                          ? const Center(
                        child: Icon(Icons.camera_alt, size: 40, color: Colors.black45),
                      )
                          : Image.asset(_imagePath!, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Comment Input
                  TextField(
                    controller: _commentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Report Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      // Example AI suggestion - replace with real logic later
                      List<String> aiSuggestions = ['Fire Station']; // This can come from your AI result

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DepartmentSelectionPage(
                            aiSuggestedDepartments: aiSuggestions,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'REPORT',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),

                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) return; // Avoid reloading current page

          setState(() => _currentIndex = index);

          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainHomeScreen()));
          } else if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StatusPage()));
          } else if (index == 2) {
            // Already on ReportPage — do nothing or refresh if needed
          } else if (index == 3) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
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
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
      label: '',
    );
  }
}
