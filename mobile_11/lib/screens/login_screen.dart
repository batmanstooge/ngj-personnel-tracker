import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  File? _loginPhoto;
  bool _isLoading = false;
  bool _photoTaken = false;

  Future<void> _takeLoginPhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _loginPhoto = File(pickedFile.path);
          _photoTaken = true;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error taking photo: ${e.toString()}');
    }
  }

  Future<String> _getImageBase64(File imageFile) async {
    List<int> imageBytes = await imageFile.readAsBytes();
    return base64Encode(imageBytes);
  }

  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_device';
    } else {
      return 'unknown_device';
    }
  }

  void _login() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      Fluttertoast.showToast(msg: 'Please enter a valid email address');
      return;
    }

    if (_loginPhoto == null) {
      Fluttertoast.showToast(msg: 'Please take a login photo for verification');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Convert photo to base64
      final photoBase64 = await _getImageBase64(_loginPhoto!);

      // Get device ID
      final deviceId = await _getDeviceId();

      final response = await AuthService().login(email, deviceId, photoBase64);

      if (response.containsKey('token')) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );

        Fluttertoast.showToast(msg: 'Login successful!');
      } else {
        // Handle error response properly
        String errorMessage = response['message'] ?? 'Login failed';
        Fluttertoast.showToast(msg: errorMessage);
      }
    } catch (e) {
      // Better error handling
      String errorMessage = EdgeInsets.only.toString();
      if (e.toString().contains('Connection refused')) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Network error. Please try again.';
      } else {
        errorMessage = e
            .toString()
            .replaceAll('Exception: ', '')
            .replaceAll('Error: ', '');
      }

      print('Login error: ${e.toString()}');
      Fluttertoast.showToast(msg: "User not found. Please register first");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(height: 30),
            Text(
              'Personnel Tracker',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 30),

            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
            ),

            SizedBox(height: 20),

            // Photo capture section
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Login Photo Verification',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Please take a photo for physical presence verification',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: 15),

                  if (_photoTaken && _loginPhoto != null)
                    Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).primaryColor,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_loginPhoto!, fit: BoxFit.cover),
                      ),
                    )
                  else
                    Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).disabledColor,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context).disabledColor.withOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 50,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),

                  SizedBox(height: 15),

                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _takeLoginPhoto,
                    icon: Icon(Icons.camera_alt),
                    label: Text('Take Photo'),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child:
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                        onPressed: _photoTaken ? _login : null,
                        child: Text(
                          'Start Job & Login',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
            ),

            SizedBox(height: 20),

            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/register');
              },
              child: Text('Don\'t have an account? Register'),
            ),
          ],
        ),
      ),
    );
  }
}
