import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:personal_tracker/screens/login_screen.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  void _register() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      Fluttertoast.showToast(msg: 'Please enter a valid email address');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await AuthService().register(email);

      if (response.containsKey('message')) {
        Fluttertoast.showToast(msg: response['message']);
        if (response['message'].contains('Verification email sent') ||
            response['message'].contains('User registered successfully')) {
          // Navigate to login screen after successful registration
          Future.delayed(Duration(seconds: 2), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          });
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Registration failed. Please try again.");
      print('Registration error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email, size: 80, color: Theme.of(context).primaryColor),
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

            SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child:
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                        onPressed: _register,
                        child: Text('Register', style: TextStyle(fontSize: 16)),
                      ),
            ),

            SizedBox(height: 20),

            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}
