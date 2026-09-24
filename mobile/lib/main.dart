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

const String kApiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://192.168.0.116:5000',
);

List<CameraDescription> cameras = [];
String? jwtToken;
String? userRole;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Error in fetching the cameras: $e');
  }
  
  await DatabaseHelper.initDb();
  
  SharedPreferences prefs = await SharedPreferences.getInstance();
  jwtToken = prefs.getString('access_token');
  userRole = prefs.getString('user_role');
  
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
      home: jwtToken != null ? const MainScreen() : const LoginScreen(),
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
        Uri.parse('$kApiBase/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        final role = data['role'];
        
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
        if (role != null) {
          await prefs.setString('user_role', role);
        }
        jwtToken = token;
        userRole = role;
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
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
      if (mounted) setState(() => _loading = false);
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

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (userRole == 'NGO_Admin') {
      return const NgoAdminScreen();
    }
    return const InspectorMainScreen();
  }
}

class NgoAdminScreen extends StatelessWidget {
  const NgoAdminScreen({super.key});
  
  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_role');
    jwtToken = null;
    userRole = null;
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NGO Admin Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context)),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.video_call, size: 100, color: Colors.blue),
            SizedBox(height: 20),
            Text('Ready to receive VC', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Connecting to LiveKit room...'),
          ],
        ),
      ),
    );
  }
}

class InspectorMainScreen extends StatefulWidget {
  const InspectorMainScreen({super.key});

  @override
  State<InspectorMainScreen> createState() => _InspectorMainScreenState();
}

class _InspectorMainScreenState extends State<InspectorMainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const DashboardTab(),
    const HistoryTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _assignment;

  @override
  void initState() {
    super.initState();
    _fetchAssignment();
  }

  Future<void> _fetchAssignment() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http.get(
        Uri.parse('$kApiBase/api/assignments/current'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
        },
      );
      
      if (response.statusCode == 200) {
        setState(() {
          _assignment = jsonDecode(response.body);
          _loading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _error = 'No assignments yet';
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to fetch assignment';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  Future<void> _verifyLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied.')));
      return;
    }

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acquiring location...')));
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
    );
    
    if (!mounted) return;
    
    double targetLat = _assignment?['ngo_lat'] ?? 0.0;
    double targetLng = _assignment?['ngo_lon'] ?? 0.0;
    
    double distance = Geolocator.distanceBetween(position.latitude, position.longitude, targetLat, targetLng);
    
    if (distance <= 200.0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CameraScreen(
          targetLat: targetLat,
          targetLng: targetLng,
          assignmentId: _assignment?['id']?.toString() ?? '1',
        )),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed. Distance: ${distance.toStringAsFixed(1)}m. Must be within 200m.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? Center(child: Text(_error!))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Assignment:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('NGO: ${_assignment?["ngo_name"] ?? "Unknown"}', style: const TextStyle(fontSize: 16)),
                  Text('Date: ${_assignment?["scheduled_date"] ?? "Unknown"}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _verifyLocation,
                    icon: const Icon(Icons.location_on),
                    label: const Text('Verify Location'),
                  ),
                ],
              ),
            ),
    );
  }
}

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  bool _loading = true;
  String? _error;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$kApiBase/api/evidence/history'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _history = jsonDecode(response.body);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to fetch history';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evidence History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    return ListTile(
                      title: Text(item['ngo_name'] ?? 'Unknown NGO'),
                      subtitle: Text('Status: ${item["status"]} - ${item["capture_time"] ?? ""}'),
                      trailing: Text('${item["distance"]?.toStringAsFixed(1) ?? "?"}m'),
                    );
                  },
                ),
    );
  }
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _updatePassword() async {
    if (_passwordController.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final response = await http.post(
        Uri.parse('$kApiBase/api/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'password': _passwordController.text,
        }),
      );
      if (response.statusCode == 200) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully')));
        _passwordController.clear();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update password')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_role');
    jwtToken = null;
    userRole = null;
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
            const SizedBox(height: 10),
            _loading 
              ? const CircularProgressIndicator()
              : ElevatedButton(onPressed: _updatePassword, child: const Text('Change Password')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: null, child: const Text('Forgot Password (Disabled)')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final double targetLat;
  final double targetLng;
  final String assignmentId;

  const CameraScreen({super.key, required this.targetLat, required this.targetLng, required this.assignmentId});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Position? _currentPosition;
  bool _isVerifying = false;
  String _status = "Ready to capture evidence";

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
    if (mounted) setState(() {});
  }
  
  bool _checkGeofence(double lat, double lng) {
    double distance = Geolocator.distanceBetween(lat, lng, widget.targetLat, widget.targetLng);
    return distance <= 200.0;
  }

  Future<void> _captureAndSave() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_currentPosition == null) {
      setState(() => _status = "Error: GPS not acquired yet.");
      return;
    }

    if (!_checkGeofence(_currentPosition!.latitude, _currentPosition!.longitude)) {
      setState(() => _status = "Error: You are not within 200m of the assigned institution.");
      return;
    }
    
    setState(() {
      _isVerifying = true;
      _status = "Capturing & stamping evidence...";
    });
    
    try {
      final XFile file = await _controller!.takePicture();
      final String timestamp = DateTime.now().toUtc().toIso8601String();
      
      await DatabaseHelper.insertInspection(file.path, _currentPosition!.latitude, _currentPosition!.longitude, timestamp);
      
      setState(() => _status = "Saved locally. Syncing...");
      
      await _syncWithBackend();
      
    } catch (e) {
      setState(() => _status = "Capture failed: $e");
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }
  
  Future<void> _syncWithBackend() async {
    final unsynced = await DatabaseHelper.getUnsynced();
    for (var record in unsynced) {
      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$kApiBase/api/evidence/submit'),
        );
        
        if (jwtToken != null) {
          request.headers['Authorization'] = 'Bearer $jwtToken';
        }
        
        final fileBytes = File(record['evidence_path']).readAsBytesSync();
        final digest = sha256.convert(fileBytes);
        
        request.fields['assignment_id'] = widget.assignmentId;
        request.fields['evidence_hash'] = digest.toString();
        request.fields['timestamp'] = record['timestamp'];
        request.fields['latitude'] = record['latitude'].toString();
        request.fields['longitude'] = record['longitude'].toString();
        request.files.add(await http.MultipartFile.fromPath('media', record['evidence_path']));
        
        var response = await request.send();
        final responseData = await response.stream.bytesToString();
        if (response.statusCode == 202) {
          await DatabaseHelper.markSynced(record['id']);
          setState(() => _status = "Sync successful! AI pipeline triggered.");
        } else {
          setState(() => _status = "Sync failed (${response.statusCode}): $responseData");
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
        title: const Text('Capture Evidence'),
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
