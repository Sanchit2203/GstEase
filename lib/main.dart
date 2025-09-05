
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gstease/firebase_options.dart'; // Import firebase_options.dart
import 'package:gstease/gst_calculator_screen.dart';
import 'package:gstease/invoice_screen.dart';
import 'package:gstease/rate_tracker_screen.dart';
import 'package:gstease/profile_screen.dart';
import 'package:gstease/login_screen.dart'; // Import LoginScreen
import 'package:gstease/registration_screen.dart'; // Import RegistrationScreen

void main() async { // Make main async
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Use options from firebase_options.dart
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GSTEase',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // Use initialRoute and routes for named navigation
      initialRoute: LoginScreen.id, // Start with the LoginScreen
      routes: {
        LoginScreen.id: (context) => const LoginScreen(),
        RegistrationScreen.id: (context) => const RegistrationScreen(),
        MyHomePage.id: (context) => const MyHomePage(title: 'GSTEase'),
        ProfileScreen.id: (context) => const ProfileScreen(), // For logout navigation
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;
  static const String id = 'my_home_page'; // For named navigation

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0; // Index for BottomNavigationBar

  // Dashboard content builder
  Widget _buildDashboard(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = (screenWidth - 16 * 2 - 16) / 2; // padding*2 (left/right) - spacing_between_buttons
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        spacing: 16.0,
        runSpacing: 16.0,
        alignment: WrapAlignment.start,
        children: <Widget>[
          SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                padding: EdgeInsets.zero,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GstCalculatorScreen()),
                );
              },
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.calculate, size: 40.0),
                  SizedBox(height: 8),
                  Text('GST Calculator', style: TextStyle(fontSize: 16.0), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                padding: EdgeInsets.zero,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InvoiceScreen()),
                );
              },
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.receipt_long, size: 40.0),
                  SizedBox(height: 8),
                  Text('Invoice', style: TextStyle(fontSize: 16.0), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                padding: EdgeInsets.zero,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RateTrackerScreen()),
                );
              },
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.timeline, size: 40.0),
                  SizedBox(height: 8),
                  Text('Rate Tracker', style: TextStyle(fontSize: 16.0), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Construct the list of widgets for the BottomNavigationBar here
    // ProfileScreen is already designed to pick up the current user
    final List<Widget> widgetOptions = <Widget>[
      _buildDashboard(context), // Dashboard view
      const ProfileScreen(),    // Profile screen (shows email and logout)
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        automaticallyImplyLeading: false, // Prevent back button on home page after login
      ),
      body: Center(
        child: widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped,
      ),
    );
  }
}
