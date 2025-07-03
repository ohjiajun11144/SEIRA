import 'package:flutter/material.dart';
import 'status.dart';
import 'report_page.dart';
import 'profile.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  String currentWeather = 'Sunny';
  int _currentIndex = 0;

  void _changeWeather() {
    setState(() {
      if (currentWeather == 'Sunny') {
        currentWeather = 'Cloudy';
      } else if (currentWeather == 'Cloudy') {
        currentWeather = 'Rainy';
      } else {
        currentWeather = 'Sunny';
      }
    });
  }

  Color getWeatherPanelColor(String weather) {
    switch (weather.toLowerCase()) {
      case 'sunny':
        return Colors.lightBlue.shade200;
      case 'cloudy':
        return Colors.grey.shade300;
      case 'rainy':
        return Colors.blueGrey.shade300;
      default:
        return Colors.white;
    }
  }

  IconData getWeatherIcon(String weather) {
    switch (weather.toLowerCase()) {
      case 'sunny':
        return Icons.wb_sunny;
      case 'cloudy':
        return Icons.cloud;
      case 'rainy':
        return Icons.beach_access;
      default:
        return Icons.wb_cloudy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          SizedBox.expand(
            child: Image.asset(
              'assets/image/background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Black overlay
          Container(color: Colors.black.withOpacity(0.3)),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top title bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Home',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                // Weather Panel (click to test weather change)
                GestureDetector(
                  onTap: _changeWeather,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: getWeatherPanelColor(currentWeather),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade400, width: 2),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Weather',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(getWeatherIcon(currentWeather), size: 42),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '$currentWeather, 29°C',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Black separator line
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 2,
                  color: Colors.black,
                ),
                const SizedBox(height: 10),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Report Near You',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Reports list
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildReportCard(
                        type: 'Fire',
                        color: Colors.red,
                        image: 'assets/image/Giat.jpg',
                        location: 'Jalan Bukit Bintang, KL',
                        time: '3:45 PM',
                        date: 'June 12, 2025',
                      ),
                      _buildReportCard(
                        type: 'Fire',
                        color: Colors.red,
                        image: 'assets/image/Giat.jpg',
                        location: 'Taman Connaught, KL',
                        time: '5:15 PM',
                        date: 'June 11, 2025',
                      ),
                      _buildReportCard(
                        type: 'Car Accident',
                        color: Colors.orange,
                        image: 'assets/image/Giat.jpg',
                        location: 'Setapak, KL',
                        time: '2:20 PM',
                        date: 'June 10, 2025',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar
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

  // Report Card Builder
  Widget _buildReportCard({
    required String type,
    required Color color,
    required String image,
    required String location,
    required String time,
    required String date,
  }) {
    return IntrinsicHeight(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black87, width: 2.0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        type,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('Location:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Center(
                      child: Text(location, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(height: 6),
                    const Text('Time:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(time, style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 6),
                    const Text('Date:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(date, style: const TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: SizedBox(
                  height: double.infinity,
                  child: Image.asset(image, fit: BoxFit.cover),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
