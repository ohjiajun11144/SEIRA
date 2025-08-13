import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/screens/home.dart';
import 'package:project1/screens/status.dart';
import 'package:project1/screens/profile.dart';
import 'package:project1/screens/department_selection.dart';
import 'package:project1/services/report_service.dart';
import 'package:project1/services/ai_model_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> with WidgetsBindingObserver {
  int _currentIndex = 2;
  String? _imagePath;
  File? _imageFile;
  DocumentReference? _latestReportRef;
  bool _uploading = false;
  bool _isClassifying = false;
  LatLng? _currentLocation;
  String? _currentAddress;
  String? _detectedType;

  bool _serviceEnabled = false;
  LocationPermission _permission = LocationPermission.denied;

  final TextEditingController _descController = TextEditingController();

  String getCurrentDate() => DateFormat('yyyy-MM-dd').format(DateTime.now());
  String getCurrentTime() => DateFormat('HH:mm:ss').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkGpsAndPermission();
    AIModelService.loadModel();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AIModelService.disposeModel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkGpsAndPermission();
    }
  }

  Future<void> _checkGpsAndPermission() async {
    _serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!_serviceEnabled) {
      setState(() {
        _currentLocation = null;
        _currentAddress = null;
      });
      return;
    }

    _permission = await Geolocator.checkPermission();
    if (_permission == LocationPermission.denied) {
      _permission = await Geolocator.requestPermission();
    }

    if (_permission == LocationPermission.denied ||
        _permission == LocationPermission.deniedForever) {
      setState(() {
        _currentLocation = null;
        _currentAddress = null;
      });
      return;
    }

    await _getCurrentLocationAndAddress();
  }

  Future<void> _getCurrentLocationAndAddress() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _currentLocation = LatLng(position.latitude, position.longitude);

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      Placemark place = placemarks.first;
      _currentAddress =
      "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
    } catch (e) {
      _currentAddress = "Unknown location";
      _currentLocation = null;
    }

    setState(() {});
  }

  Future<void> _classifyImage(File image) async {
    setState(() {
      _isClassifying = true;
      _detectedType = null;
    });

    try {
      final results = await AIModelService.classifyImage(image.path);

      if (results != null && results.isNotEmpty) {
        final topResult = results.first;
        final confidence = topResult['confidence'] as double;
        final label = topResult['label'] as String;

        if (confidence > 0.1) {
          setState(() {
            _detectedType = label;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "✅ AI detected: $_detectedType (${(confidence * 100).toStringAsFixed(1)}%)")),
          );
        } else {
          setState(() {
            _detectedType = _getFallbackClassification(image.path);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "⚠️ Low confidence, using fallback: $_detectedType")),
          );
        }
      } else {
        setState(() {
          _detectedType = _getFallbackClassification(image.path);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ AI failed, using fallback: $_detectedType")),
        );
      }
    } catch (e) {
      setState(() {
        _detectedType = 'Unknown';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ AI classification failed: $e")),
      );
    } finally {
      setState(() => _isClassifying = false);
    }
  }

  String _getFallbackClassification(String imagePath) {
    if (imagePath.contains('fire') || imagePath.contains('smoke')) {
      return 'fire';
    } else if (imagePath.contains('car') || imagePath.contains('accident')) {
      return 'accident';
    } else if (imagePath.contains('snake') || imagePath.contains('reptile')) {
      return 'snake';
    } else {
      return 'Unknown';
    }
  }

  Future<void> _uploadImageAndProceed() async {
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please enable GPS and allow location before reporting')),
      );
      return;
    }

    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please take a photo first')),
      );
      return;
    }

    if (_detectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please wait for AI classification to complete')),
      );
      return;
    }

    setState(() => _uploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final reportService = ReportService();
      final now = DateTime.now();
      final currentDate = DateFormat('yyyy-MM-dd').format(now);
      final currentTime = DateFormat('HH:mm:ss').format(now);

      final imageUrl = await reportService.uploadImage(_imageFile!);
      if (imageUrl == null) throw Exception("Image upload failed");

      _latestReportRef =
      await FirebaseFirestore.instance.collection('reports').add({
        'reportId': '',
        'userId': user?.uid ?? '',
        'type': _detectedType ?? 'Unknown',
        'status': 'Pending',
        'location': _currentAddress ?? 'Unknown location',
        'date': currentDate,
        'time': currentTime,
        'handledBy': '',
        'description': _descController.text.trim(),
        'image_url': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _latestReportRef!.update({'reportId': _latestReportRef!.id});

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DepartmentSelectionPage(
            aiSuggestedDepartments: [_detectedType ?? 'Unknown'],
            reportId: _latestReportRef!.id,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Upload failed: $e")),
      );
    }

    setState(() => _uploading = false);
  }

  Widget _buildGpsDisabledPanel() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.gps_off, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            const Text(
              'GPS is turned OFF or permission denied.\nPlease enable location services.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('Open Location Settings'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                Geolocator.openLocationSettings();
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _checkGpsAndPermission();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
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
                  Center(
                    child: Text(
                      'Report',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (!_serviceEnabled ||
                      _permission == LocationPermission.denied ||
                      _permission == LocationPermission.deniedForever)
                    _buildGpsDisabledPanel()
                  else if (_currentLocation == null)
                    const Center(child: CircularProgressIndicator())
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: _currentLocation!,
                                initialZoom: 16.0,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.project1',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      width: 40,
                                      height: 40,
                                      point: _currentLocation!,
                                      child: const Icon(Icons.location_pin,
                                          color: Colors.red, size: 40),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentAddress ?? 'Fetching address...',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),

                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Date/Time: ${getCurrentDate()} ${getCurrentTime()}',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: (_currentLocation == null)
                        ? null
                        : () async {
                      final picker = ImagePicker();
                      final pickedFile =
                      await picker.pickImage(source: ImageSource.camera);
                      if (pickedFile != null) {
                        setState(() {
                          _imagePath = pickedFile.path;
                          _imageFile = File(pickedFile.path);
                          _detectedType = null;
                        });
                        await _classifyImage(_imageFile!);
                      }
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
                          child: Icon(Icons.camera_alt,
                              size: 40, color: Colors.black45))
                          : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(_imagePath!),
                            fit: BoxFit.cover, width: double.infinity),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isClassifying)
                    const Padding(
                      padding: EdgeInsets.all(10),
                      child: Center(
                        child: Text(
                          '🧠 AI analyzing...',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    )
                  else if (_detectedType != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "AI Detected: $_detectedType",
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_uploading) const Center(child: CircularProgressIndicator()),
                  if (_imageFile != null && _detectedType == null && !_isClassifying)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _classifyImage(_imageFile!),
                      child: const Text('🔍 Retry AI Classification',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: (_uploading || _detectedType == null || _currentLocation == null)
                        ? null
                        : _uploadImageAndProceed,
                    child: const Text('REPORT',
                        style: TextStyle(fontSize: 20, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) return;
          setState(() => _currentIndex = index);

          switch (index) {
            case 0:
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const MainHomeScreen()));
              break;
            case 1:
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const StatusPage()));
              break;
            case 2:
              break;
            case 3:
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const ProfilePage()));
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
