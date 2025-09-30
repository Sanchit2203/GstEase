
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gstease/firebase_options.dart'; // Import firebase_options.dart
import 'package:gstease/auth_wrapper.dart'; // Import AuthWrapper
import 'package:gstease/gst_calculator_screen.dart';
import 'package:gstease/invoice_screen.dart';
import 'package:gstease/rate_tracker_screen.dart';
import 'package:gstease/profile_screen.dart';
import 'package:gstease/login_screen.dart'; // Import LoginScreen
import 'package:gstease/registration_screen.dart'; // Import RegistrationScreen
import 'package:gstease/upi_payment_screen.dart'; // Import UPI Payment Screen
import 'package:gstease/payment_history_screen.dart'; // Import Payment History Screen
import 'package:gstease/upi_receive_screen.dart'; // Import UPI Receive Screen
import 'package:gstease/reports_screen.dart'; // Import Reports Screen


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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 4,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 3,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6750A4), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
        ),
      ),
      debugShowCheckedModeBanner: false,
      // Use AuthWrapper to handle authentication state
      home: const AuthWrapper(),
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.05),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to GSTEase',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage GST calculations and payments with ease',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            
            // UPI SECTION
            Row(
              children: [
                Icon(Icons.payment, color: Theme.of(context).colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'UPI Payment Services',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildDashboardCard(
                  context,
                  title: 'UPI Payment',
                  subtitle: 'Pay via UPI',
                  icon: Icons.payment,
                  colors: [const Color(0xFF4CAF50), const Color(0xFF8BC34A)],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UPIPaymentScreen()),
                    );
                  },
                ),
                _buildDashboardCard(
                  context,
                  title: 'Receive Payment',
                  subtitle: 'Generate QR Code',
                  icon: Icons.qr_code,
                  colors: [const Color(0xFF00BCD4), const Color(0xFF4FC3F7)],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UPIReceiveScreen()),
                    );
                  },
                ),
                _buildDashboardCard(
                  context,
                  title: 'Payment History',
                  subtitle: 'View transactions',
                  icon: Icons.history,
                  colors: [const Color(0xFF9C27B0), const Color(0xFFE91E63)],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PaymentHistoryScreen()),
                    );
                  },
                ),
                _buildDashboardCard(
                  context,
                  title: 'Reports',
                  subtitle: 'View analytics',
                  icon: Icons.analytics,
                  colors: [const Color(0xFF1565C0), const Color(0xFF2196F3)],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ReportsScreen()),
                    );
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // GST SECTION
            Row(
              children: [
                Icon(Icons.calculate, color: Theme.of(context).colorScheme.secondary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'GST Management',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildDashboardCard(
                  context,
                  title: 'GST Calculator',
                  subtitle: 'Calculate GST quickly',
                  icon: Icons.calculate,
                  colors: [const Color(0xFF6750A4), const Color(0xFF8E7CC3)],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const GstCalculatorScreen()),
                    );
                  },
                ),
                _buildDashboardCard(
                  context,
                  title: 'Invoice',
                  subtitle: 'Generate invoices',
                  icon: Icons.receipt_long,
                  colors: [const Color(0xFF2E7D32), const Color(0xFF4CAF50)],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const InvoiceScreen()),
                    );
                  },
                ),
                _buildDashboardCard(
                  context,
                  title: 'Rate Tracker',
                  subtitle: 'Track GST rates',
                  icon: Icons.trending_up,
                  colors: [const Color(0xFFE65100), const Color(0xFFFF9800)],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RateTrackerScreen()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 6,
      shadowColor: colors[0].withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(widget.title),
          ],
        ),
        automaticallyImplyLeading: false, // Prevent back button on home page after login
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
      ),
      body: Center(
        child: widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey.shade600,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Colors.white,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
