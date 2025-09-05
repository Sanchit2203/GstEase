import 'package:flutter/material.dart';
import 'package:gstease/login_screen.dart';
import 'package:gstease/registration_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        // The AppBar will be part of the main screen with BottomNavigationBar,
        // so it might be better to remove this AppBar if ProfileScreen is only a body part.
        // For now, let's keep it simple as it was originally.
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Manage your profile or login/register',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('Login'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                );
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}