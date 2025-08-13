import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'status.dart';
import 'package:android_intent_plus/android_intent.dart';

class DepartmentSelectionPage extends StatefulWidget {
  final List<String> aiSuggestedDepartments;
  final String reportId;

  const DepartmentSelectionPage({
    super.key,
    required this.aiSuggestedDepartments,
    required this.reportId,
  });

  @override
  State<DepartmentSelectionPage> createState() => _DepartmentSelectionPageState();
}

class _DepartmentSelectionPageState extends State<DepartmentSelectionPage> {
  bool isHospitalSelected = false;
  bool isFireStationSelected = false;
  bool isPoliceSelected = false;
  final TextEditingController _commentController = TextEditingController();

  String? reportLocation;
  String? reportDate;
  String? reportTime;
  String? imageDownloadUrl;
  String? reportType;

  @override
  void initState() {
    super.initState();

    final mappedDepartments = <String>{};

    // AI label mapping for fire, accident, and snake
    for (var type in widget.aiSuggestedDepartments) {
      switch (type.toLowerCase()) {
        case 'fire':
        case 'snake':
          mappedDepartments.add('Fire Station');
          break;
        case 'accident':
          mappedDepartments.add('Hospital');
          mappedDepartments.add('Police');
          break;
        default:
          break;
      }
    }

    isHospitalSelected = mappedDepartments.contains('Hospital');
    isFireStationSelected = mappedDepartments.contains('Fire Station');
    isPoliceSelected = mappedDepartments.contains('Police');

    _loadReportDetails();
  }

  Future<void> _loadReportDetails() async {
    final doc = await FirebaseFirestore.instance.collection('reports').doc(widget.reportId).get();
    if (doc.exists) {
      setState(() {
        reportLocation = doc['location'] ?? 'Unknown';
        reportDate = doc['date'] ?? '';
        reportTime = doc['time'] ?? '';
        imageDownloadUrl = doc['image_url'] ?? '';
        reportType = doc['type'] ?? 'Incident';
      });
    }
  }

  Future<void> sendToWhatsApp({
    required String phoneNumber,
    required String type,
    required String location,
    required String date,
    required String time,
    required String imageUrl,
  }) async {
    final message = Uri.encodeComponent(
      "📣 New Report Received!\n"
          "Type: $type\n"
          "Location: $location\n"
          "Date: $date\n"
          "Time: $time\n"
          "View Image: $imageUrl",
    );

    final url = "https://wa.me/$phoneNumber?text=$message";

    final intent = AndroidIntent(
      action: 'action_view',
      data: url,
      package: "com.whatsapp",
    );

    try {
      await intent.launch();
    } catch (e) {
      debugPrint("⚠️ WhatsApp launch error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Can't Open WhatsApp"), backgroundColor: Colors.red),
      );
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  const Text(
                    "Which Departments Do You Need?",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Based on your photo, we suggest contacting:",
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: widget.aiSuggestedDepartments.map((dept) {
                      return Chip(
                        label: Text(dept),
                        avatar: const Icon(Icons.recommend, color: Colors.black87),
                        backgroundColor: Colors.orange[200],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  _buildDeptTile('Hospital', Icons.local_hospital, isHospitalSelected, () {
                    setState(() => isHospitalSelected = !isHospitalSelected);
                  }),
                  _buildDeptTile('Fire Station', Icons.local_fire_department, isFireStationSelected, () {
                    setState(() => isFireStationSelected = !isFireStationSelected);
                  }),
                  _buildDeptTile('Police', Icons.local_police, isPoliceSelected, () {
                    setState(() => isPoliceSelected = !isPoliceSelected);
                  }),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Any comments you’d like to add? (Optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: (isHospitalSelected || isFireStationSelected || isPoliceSelected)
                        ? _submitReport
                        : null,
                    child: const Text(
                      "SEND REPORT",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeptTile(String label, IconData icon, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: selected ? Colors.green[100] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Icon(icon, color: Colors.black87),
          title: Text(label, style: const TextStyle(fontSize: 18)),
          trailing: Icon(
            selected ? Icons.check_circle : Icons.circle_outlined,
            color: selected ? Colors.green : Colors.grey,
          ),
        ),
      ),
    );
  }

  void _submitReport() async {
    List<String> selected = [];
    if (isHospitalSelected) selected.add('Hospital');
    if (isFireStationSelected) selected.add('Fire Station');
    if (isPoliceSelected) selected.add('Police');

    final String selectedString = selected.join(', ');

    try {
      await FirebaseFirestore.instance.collection('reports').doc(widget.reportId).update({
        'assigned_to': selected,
        'handledBy': selectedString,
        'description': _commentController.text,
        'status': 'received',
      });

      if (reportType != null &&
          reportLocation != null &&
          reportDate != null &&
          reportTime != null &&
          imageDownloadUrl != null) {
        await sendToWhatsApp(
          phoneNumber: '601158517692',
          type: reportType!,
          location: reportLocation!,
          date: reportDate!,
          time: reportTime!,
          imageUrl: imageDownloadUrl!,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Report submitted successfully"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const StatusPage()),
              (route) => false,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to submit report: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
