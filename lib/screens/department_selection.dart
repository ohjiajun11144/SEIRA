import 'package:flutter/material.dart';
import 'status.dart'; // Make sure this is your actual status page

class DepartmentSelectionPage extends StatefulWidget {
  final List<String> aiSuggestedDepartments;

  const DepartmentSelectionPage({super.key, required this.aiSuggestedDepartments});

  @override
  State<DepartmentSelectionPage> createState() => _DepartmentSelectionPageState();
}

class _DepartmentSelectionPageState extends State<DepartmentSelectionPage> {
  bool isHospitalSelected = false;
  bool isFireStationSelected = false;
  bool isPoliceSelected = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Preselect AI-suggested departments
    if (widget.aiSuggestedDepartments.contains('Hospital')) {
      isHospitalSelected = true;
    }
    if (widget.aiSuggestedDepartments.contains('Fire Station')) {
      isFireStationSelected = true;
    }
    if (widget.aiSuggestedDepartments.contains('Police')) {
      isPoliceSelected = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          SizedBox.expand(
            child: Image.asset('assets/image/background.png', fit: BoxFit.cover),
          ),
          Container(color: Colors.black.withOpacity(0.3)),

          // Content
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

  void _submitReport() {
    List<String> selected = [];
    if (isHospitalSelected) selected.add('Hospital');
    if (isFireStationSelected) selected.add('Fire Station');
    if (isPoliceSelected) selected.add('Police');

    String comment = _commentController.text;

    // TODO: Save data to backend or Firebase here

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Report submitted successfully"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Delay and redirect to Status Page
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const StatusPage()),
            (route) => false, // Clear all previous pages
      );
    });
  }
}
