import 'package:flutter/material.dart';
import 'package:version_control/firebaseVersion_controller.dart'; // Import your version controller

void main() async {
  // Run the app
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    // Check for updates when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    await VersionController.checkForUpdates(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My App'),
        actions: [
          // Add manual update check button
          IconButton(
            icon: Icon(Icons.system_update),
            onPressed: _checkForUpdates,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Current Version: 1.0.0'), // Replace with actual version
            ElevatedButton(
              onPressed: _checkForUpdates,
              child: Text('Check for Updates'),
            ),
          ],
        ),
      ),
    );
  }
}