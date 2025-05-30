import 'package:flutter/material.dart';

class HelpFaqScreen extends StatelessWidget {
  final List<Map<String, String>> faqs = [
    {
      'question': 'How do I scan a document?',
      'answer':
          'Go to the home page, tap on the scan icon, and follow the instructions.',
    },
    {
      'question': 'Can I upload existing images?',
      'answer':
          'Yes! Use the "Upload" option to select images from your device.',
    },
    {
      'question': 'Is my data secure?',
      'answer': 'Absolutely. All your data is stored securely in Firebase.',
    },
  ];

  HelpFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Help & FAQs')),
      body: ListView.builder(
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          return ExpansionTile(
            title: Text(faqs[index]['question']!),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(faqs[index]['answer']!),
              ),
            ],
          );
        },
      ),
    );
  }
}
