// frontend/lib/screens/verify_email_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String token;

  VerifyEmailScreen({required this.token});

  @override
  _VerifyEmailScreenState createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _verifyEmail();
  }

  void _verifyEmail() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await AuthService().verifyEmail(widget.token);
      
      if (response.containsKey('message') && response['message'].contains('successfully')) {
        Fluttertoast.showToast(msg: 'Email verified successfully!');
        
        // Navigate to login after successful verification
        Future.delayed(Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/login');
        });
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? 'Verification failed');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Verification failed: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Verify Email')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isLoading 
              ? CircularProgressIndicator()
              : Icon(Icons.verified, size: 80, color: Colors.green),
            SizedBox(height: 20),
            Text(
              _isLoading 
                ? 'Verifying your email...' 
                : 'Email verification successful!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}