import 'package:flutter/material.dart';
import 'package:gstease/gst_calculator_screen.dart';
import 'package:gstease/invoice_screen.dart';
import 'package:gstease/rate_tracker_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GSTEase',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'GSTEase'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Calculate button size: (screenWidth - padding*2 - spacing_between_buttons) / number_of_buttons_per_row
    final buttonSize = (screenWidth - 16 * 2 - 16) / 2;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding( // Added overall padding
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          spacing: 16.0, // Horizontal space between buttons
          runSpacing: 16.0, // Vertical space between button lines
          alignment: WrapAlignment.start, // Align buttons to the start
          children: <Widget>[
            SizedBox( // To make the button square
              width: buttonSize, // Define square size
              height: buttonSize, // Define square size
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero, // Sharp edges
                  ),
                  padding: EdgeInsets.zero, // Remove default padding to use SizedBox for sizing
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GstCalculatorScreen()),
                  );
                },
                child: const Column( // Added Column for Icon and Text
                  mainAxisAlignment: MainAxisAlignment.center, // Center content in Column
                  children: <Widget>[
                    Icon(Icons.calculate, size: 40.0), // Calculator Icon, adjusted size
                    SizedBox(height: 8), // Spacing between Icon and Text
                    Text('GST Calculator', style: TextStyle(fontSize: 16.0), textAlign: TextAlign.center), // Text, adjusted size
                  ],
                ),
              ),
            ),
            SizedBox( // To make the button square
              width: buttonSize, // Define square size
              height: buttonSize, // Define square size
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero, // Sharp edges
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
                    Icon(Icons.receipt_long, size: 40.0), // Adjusted size
                    SizedBox(height: 8),
                    Text('Invoice', style: TextStyle(fontSize: 16.0), textAlign: TextAlign.center), // Adjusted size
                  ],
                ),
              ),
            ),
            SizedBox( // To make the button square
              width: buttonSize, // Define square size
              height: buttonSize, // Define square size
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero, // Sharp edges
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
                    Icon(Icons.timeline, size: 40.0), // Adjusted size
                    SizedBox(height: 8),
                    Text('Rate Tracker', style: TextStyle(fontSize: 16.0), textAlign: TextAlign.center), // Adjusted size
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
