import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'status.dart';
import 'report_page.dart';
import 'profile.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;

  // Safety tips list
  final List<Map<String, String>> _safetyTips = [
    {'title': 'Fire Safety', 'tip': 'In case of fire, stay low to avoid smoke and exit quickly. Do not use elevators.', 'icon': '🔥'},
    {'title': 'Emergency Numbers', 'tip': 'Keep emergency numbers handy: Fire (999), Police (999), Ambulance (999).', 'icon': '📞'},
    {'title': 'First Aid Kit', 'tip': 'Always keep a well-stocked first aid kit at home and in your car.', 'icon': '🏥'},
    {'title': 'Smoke Detectors', 'tip': 'Test your smoke detectors monthly and replace batteries every 6 months.', 'icon': '🚨'},
    {'title': 'Electrical Safety', 'tip': 'Never overload electrical outlets and unplug appliances when not in use.', 'icon': '⚡'},
    {'title': 'Kitchen Safety', 'tip': 'Never leave cooking unattended and keep flammable items away from the stove.', 'icon': '👨‍🍳'},
    {'title': 'Carbon Monoxide', 'tip': 'Install CO detectors and never run generators or grills indoors.', 'icon': '☠️'},
    {'title': 'Weather Emergencies', 'tip': 'During storms, stay indoors and away from windows. Have a weather radio.', 'icon': '⛈️'},
    {'title': 'Home Security', 'tip': 'Lock doors and windows, use motion-sensor lights, and consider a security system.', 'icon': '🔒'},
    {'title': 'Child Safety', 'tip': 'Keep cleaning products, medicines, and sharp objects out of children\'s reach.', 'icon': '👶'},
    {'title': 'Pet Safety', 'tip': 'Keep pets away from toxic plants and secure hazardous items.', 'icon': '🐕'},
    {'title': 'Water Safety', 'tip': 'Never leave children unattended near water, even shallow pools.', 'icon': '💧'},
    {'title': 'Road Safety', 'tip': 'Always wear seatbelts, follow speed limits, and never drive under the influence.', 'icon': '🚗'},
    {'title': 'Cybersecurity', 'tip': 'Use strong passwords, enable two-factor authentication, and beware of phishing.', 'icon': '💻'},
    {'title': 'Natural Disasters', 'tip': 'Have an emergency kit with food, water, flashlight, and important documents.', 'icon': '🌪️'}
  ];

  late Map<String, String> _currentTip;

  @override
  void initState() {
    super.initState();
    _currentTip = _getRandomTip();
  }

  Map<String, String> _getRandomTip() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return _safetyTips[random % _safetyTips.length];
  }

  void _refreshTip() {
    setState(() {
      _currentTip = _getRandomTip();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset('assets/image/background.jpg', fit: BoxFit.cover),
          ),
          Container(color: Colors.black.withOpacity(0.3)),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Home', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
                    ],
                  ),
                ),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade400, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(_currentTip['icon'] ?? '💡', style: const TextStyle(fontSize: 32)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(_currentTip['title'] ?? 'Safety Tip', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(_currentTip['tip'] ?? '', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                Container(margin: const EdgeInsets.symmetric(horizontal: 16), height: 2, color: Colors.black),
                const SizedBox(height: 10),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Latest Report', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('reports')
                        .orderBy('date', descending: true)
                        .limit(4)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No reports found.'));
                      }

                      final reports = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: reports.length,
                        itemBuilder: (context, index) {
                          final report = reports[index].data() as Map<String, dynamic>;
                          String type = (report['type'] ?? 'Unknown').toString().trim();
                          String imageUrl = report['image_url'] ?? '';
                          String status = report['status'] ?? 'pending';
                          Color color;

                          switch (type.toLowerCase()) {
                            case 'fire':
                              color = Colors.red;
                              break;
                            case 'car accident':
                            case 'accident':
                              color = Colors.orange;
                              break;
                            default:
                              color = Colors.blueGrey;
                          }

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                              border: Border.all(color: _getBorderColor(status), width: 3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (imageUrl.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: imageUrl.startsWith('http')
                                        ? Image.network(imageUrl, height: 180, width: double.infinity, fit: BoxFit.cover)
                                        : Image.asset(imageUrl, height: 180, width: double.infinity, fit: BoxFit.cover),
                                  ),
                                const SizedBox(height: 8),
                                Text("Type: $type", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text("Status: $status", style: TextStyle(fontSize: 16, color: _getBorderColor(status))),
                                Text("Location: ${report['location'] ?? 'Unknown'}", style: const TextStyle(fontSize: 16)),
                                Text("Date: ${report['date'] ?? ''}", style: const TextStyle(fontSize: 16)),
                                Text("Time: ${report['time'] ?? ''}", style: const TextStyle(fontSize: 16)),
                                const SizedBox(height: 4),
                                Text("Description: ${report['description'] ?? ''}", style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const StatusPage()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportPage()));
          } else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
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
