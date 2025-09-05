
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart'; // Assuming your login screen is here

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  static const String id = 'profile_screen'; // For named navigation

  @override
  Widget build(BuildContext context) {
    // Get the current user
    final User? user = FirebaseAuth.instance.currentUser;
    final String? userEmail = user?.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false, // Don't show back button if navigated from login
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                'Welcome!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (userEmail != null)
                Text(
                  'Email: $userEmail',
                  style: TextStyle(fontSize: 18),
                )
              else
                const Text(
                  'Email: Not available',
                  style: TextStyle(fontSize: 18),
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: const Text('Logout', style: TextStyle(fontSize: 18)),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  // Navigate back to the login screen after logout
                  // Make sure LoginScreen.id is defined in your login_screen.dart
                  // or use MaterialPageRoute directly if not using named routes for login.
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    LoginScreen.id, 
                    (Route<dynamic> route) => false
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
