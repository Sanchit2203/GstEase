import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Added padding
          child: SizedBox( // To make the button square
            width: 200, // Define square size
            height: 200, // Define square size
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // Sharp edges
                ),
              ),
              onPressed: () {
                // TODO: Navigate to GST Calculator screen
                print('GST Calculator button pressed');
              },
              child: const Column( // Added Column for Icon and Text
                mainAxisAlignment: MainAxisAlignment.center, // Center content in Column
                children: <Widget>[
                  Icon(Icons.calculate, size: 80.0), // Calculator Icon
                  SizedBox(height: 8), // Spacing between Icon and Text
                  Text('GST Calculator', style: TextStyle(fontSize: 20.0)), // Text
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
