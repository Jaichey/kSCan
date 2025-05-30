import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('About Us')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'kScan is a lightweight, easy-to-use scanning application developed by passionate students from KMIT. '
          'Our goal is to simplify document scanning and management for students and professionals alike.\n\n'
          'Version: 1.0.0',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
