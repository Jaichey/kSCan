import 'package:flutter/material.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contact Us')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reach us at:', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.email),
              title: Text('support@kscan.app'),
            ),
            ListTile(
              leading: Icon(Icons.phone),
              title: Text('+91 99498 75507'),
            ),
            ListTile(
              leading: Icon(Icons.location_on),
              title: Text('KMIT, Hyderabad, India'),
            ),
          ],
        ),
      ),
    );
  }
}
