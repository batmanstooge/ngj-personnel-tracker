import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isOtpSent = false;
  bool _isLoading = false;

  void _sendOtp() async {
    final phoneNumber = _phoneController.text.trim();
    
    if (phoneNumber.isEmpty || phoneNumber.length < 10) {
      Fluttertoast.showToast(msg: 'Please enter a valid phone number');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final response = await ApiService.sendOtp(phoneNumber);
      
      if (response.containsKey('message')) {
        setState(() {
          _isOtpSent = true;
        });
        Fluttertoast.showToast(msg: response['message']);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
      print('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _verifyOtp() async {
    final phoneNumber = _phoneController.text.trim();
    final otp = _otpController.text.trim();
    
    if (otp.isEmpty || otp.length < 4) {
      Fluttertoast.showToast(msg: 'Please enter a valid OTP');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final response = await ApiService.verifyOtp(phoneNumber, otp);
      
      if (response.containsKey('token')) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
        
        Fluttertoast.showToast(msg: 'Login successful!');
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        centerTitle: true,
      ),
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
              'Location Tracker',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 30),
            
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixText: '+91 ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixStyle: TextStyle(fontSize: 16),
              ),
              keyboardType: TextInputType.phone,
              enabled: !_isOtpSent && !_isLoading,
            ),
            
            SizedBox(height: 20),
            
            if (_isOtpSent)
              TextField(
                controller: _otpController,
                decoration: InputDecoration(
                  labelText: 'Enter OTP',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                enabled: !_isLoading,
              ),
            
            SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _isOtpSent ? _verifyOtp : _sendOtp,
                      child: Text(
                        _isOtpSent ? 'Verify OTP' : 'Send OTP',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
            ),
            
            if (_isOtpSent)
              TextButton(
                onPressed: () {
                  setState(() {
                    _isOtpSent = false;
                  });
                },
                child: Text('Resend OTP'),
              ),
          ],
        ),
      ),
    );
  }
}