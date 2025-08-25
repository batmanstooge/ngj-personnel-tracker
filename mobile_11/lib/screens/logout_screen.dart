import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../services/auth_service.dart';
import 'login_screen.dart';

class LogoutScreen extends StatefulWidget {
  @override
  _LogoutScreenState createState() => _LogoutScreenState();
}

class _LogoutScreenState extends State<LogoutScreen> {
  File? _logoutPhoto;
  bool _isLoading = false;
  bool _photoTaken = false;

  Future<void> _takeLogoutPhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _logoutPhoto = File(pickedFile.path);
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

  _logout() async {
    if (_logoutPhoto == null) {
      Fluttertoast.showToast(
        msg: 'Please take a logout photo for verification',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String photoBase64 = await _getImageBase64(_logoutPhoto!);
      final response = await AuthService().logout(photoBase64);

      if (response.containsKey('message')) {
        Fluttertoast.showToast(msg: response['message']);
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('auth_token');
      await prefs.remove('current_job_id');

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      String errorMessage;

      if (e.toString().contains('Connection refused')) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Network error. Please try again.';
      } else {
        errorMessage = 'Logout failed. Please try again.';
      }

      print('Logout error: ${e.toString()}');
      Fluttertoast.showToast(msg: errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logout'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 80, color: Theme.of(context).primaryColor),
            SizedBox(height: 30),
            Text(
              'End Job & Logout',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 10),
            Text(
              'Please take a photo to verify logout',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 30),

            // Photo capture section
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (_photoTaken && _logoutPhoto != null)
                    Container(
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).primaryColor,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_logoutPhoto!, fit: BoxFit.cover),
                      ),
                    )
                  else
                    Container(
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).disabledColor,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context).disabledColor.withOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 60,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),

                  SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _takeLogoutPhoto,
                    icon: Icon(Icons.camera_alt),
                    label: Text('Take Logout Photo'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
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
                      ? Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text('Logging out...'),
                          ],
                        ),
                      )
                      : ElevatedButton(
                        onPressed: _photoTaken ? _logout : null,
                        child: Text(
                          'Confirm Logout',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
            ),

            SizedBox(height: 20),

            Text(
              'Taking a logout photo confirms the end of your job session.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
