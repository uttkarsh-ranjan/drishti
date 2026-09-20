import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

List<CameraDescription> cameras = [];
String? jwtToken;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error in fetching the cameras: $e');
  }
  
  await DatabaseHelper.initDb();
  
  SharedPreferences prefs = await SharedPreferences.getInstance();
  jwtToken = prefs.getString('access_token');
  
  runApp(const DrishtiApp());
}

class DatabaseHelper {
  static late Database db;
  
  static Future<void> initDb() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final path = p.join(docsDir.path, 'drishti.db');
    db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE inspections (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            evidence_path TEXT,
            latitude REAL,
            longitude REAL,
            timestamp TEXT,
            synced INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }
  
  static Future<int> insertInspection(String path, double lat, double lng, String time) async {
    return await db.insert('inspections', {
      'evidence_path': path,
      'latitude': lat,
      'longitude': lng,
      'timestamp': time,
      'synced': 0,
    });
  }
  
  static Future<List<Map<String, dynamic>>> getUnsynced() async {
    return await db.query('inspections', where: 'synced = 0');
  }
  
  static Future<void> markSynced(int id) async {
    await db.update('inspections', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }
}

class DrishtiApp extends StatelessWidget {
  const DrishtiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drishti Inspection',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: jwtToken != null ? const InspectionScreen() : const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  
  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
        jwtToken = token;
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const InspectionScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login failed')));
        }
      }
    } catch (e) {
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Drishti Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 20),
            _loading 
              ? const CircularProgressIndicator()
              : ElevatedButton(onPressed: _login, child: const Text('Login')),
          ],
        ),
      ),
    );
  }
}  
  static Future<int> insertInspection(String path, double lat, double lng, String time) async {
    return await db.insert('inspections', {
      'evidence_path': path,
      'latitude': lat,
      'longitude': lng,
      'timestamp': time,
      'synced': 0,
    });
  }
  
  static Future<List<Map<String, dynamic>>> getUnsynced() async {
    return await db.query('inspections', where: 'synced = 0');
  }
  
  static Future<void> markSynced(int id) async {
    await db.update('inspections', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }
}



class InspectionScreen extends StatefulWidget {
  const InspectionScreen({super.key});

  @override
  State<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  CameraController? _controller;
  Position? _currentPosition;
  bool _isVerifying = false;
  String _status = "Ready to capture evidence";
  
  // Dummy target location for demo purposes (e.g., specific NGO location)
  final double targetLat = 28.6139; // New Delhi
  final double targetLng = 77.2090;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _getCurrentLocation();
  }
  
  Future<void> _initCamera() async {
    if (cameras.isEmpty) return;
    _controller = CameraController(cameras[0], ResolutionPreset.medium);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }
  
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    } 

    _currentPosition = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
    );
    setState(() {});
  }
  
  bool _checkGeofence(double lat, double lng) {
    // 200 meter geofence check
    double distance = Geolocator.distanceBetween(lat, lng, targetLat, targetLng);
    return distance <= 200.0;
  }

  Future<void> _captureAndSave() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_currentPosition == null) {
      setState(() => _status = "Error: GPS not acquired yet.");
      return;
    }
    
    setState(() {
      _isVerifying = true;
      _status = "Capturing & stamping evidence...";
    });
    
    try {
      final XFile file = await _controller!.takePicture();
      final String timestamp = DateTime.now().toUtc().toIso8601String();
      
      // Save locally to offline DB first
      await DatabaseHelper.insertInspection(file.path, _currentPosition!.latitude, _currentPosition!.longitude, timestamp);
      
      setState(() => _status = "Saved locally. Syncing...");
      
      // Try to sync
      await _syncWithBackend();
      
    } catch (e) {
      setState(() => _status = "Capture failed: \$e");
    } finally {
      setState(() => _isVerifying = false);
    }
  }
  
  Future<void> _syncWithBackend() async {
    final unsynced = await DatabaseHelper.getUnsynced();
    for (var record in unsynced) {
      try {
        var request = http.MultipartRequest('POST', Uri.parse('http://10.0.2.2:5000/api/evidence/submit')); // 10.0.2.2 is localhost for Android Emulator
        
        if (jwtToken != null) {
          request.headers['Authorization'] = 'Bearer $jwtToken';
        }
        
        // Calculate hash of file for zero-trust API
        final fileBytes = File(record['evidence_path']).readAsBytesSync();
        final digest = sha256.convert(fileBytes);
        
        request.fields['assignment_id'] = '1';
        request.fields['evidence_hash'] = digest.toString();
        request.fields['timestamp'] = record['timestamp'];
        request.fields['latitude'] = record['latitude'].toString();
        request.fields['longitude'] = record['longitude'].toString();
        request.files.add(await http.MultipartFile.fromPath('media', record['evidence_path']));
        
        var response = await request.send();
        if (response.statusCode == 200) {
          await DatabaseHelper.markSynced(record['id']);
          setState(() => _status = "Sync successful!");
        } else {
          var responseData = await response.stream.bytesToString();
          setState(() => _status = "Sync failed: \$responseData");
        }
      } catch (e) {
        setState(() => _status = "Offline mode: Will sync when connection is restored.");
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Evidence Capture'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: _controller != null && _controller!.value.isInitialized
                ? CameraPreview(_controller!)
                : const Center(child: CircularProgressIndicator()),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              children: [
                if (_currentPosition != null)
                  Text("GPS: \${_currentPosition!.latitude.toStringAsFixed(4)}, \${_currentPosition!.longitude.toStringAsFixed(4)}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_status, style: TextStyle(color: _status.contains("Error") || _status.contains("failed") ? Colors.red : Colors.green)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isVerifying ? null : _captureAndSave,
                  icon: const Icon(Icons.camera),
                  label: const Text('Capture Evidence'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _syncWithBackend,
                  icon: const Icon(Icons.sync),
                  label: const Text('Force Sync'),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
