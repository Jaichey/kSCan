// Created by: Dhanunjai on 23/02/2025
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kscan/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:kscan/services/theme_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kscan/services/splash_screen.dart';
import 'upload_docs.dart';
import 'report_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final sampleResults = [
  {
    "comparison_result": {
      "verdict": "match",
      "similarity_score": 96.5,
      "matched_fields": 5,
      "total_fields": 5,
      "document_type": "Aadhaar",
      "details": {
        "name": {
          "profile_value": "Rahul Sharma",
          "extracted_value": "Rahul Sharma",
          "similarity": 100,
          "match": true,
        },
      },
    },
    "face_comparison": {"photoMatch": "match", "faceSimilarity": 98.2},
    "face_images": {
      "uploaded_face": "https://randomuser.me/api/portraits/men/1.jpg",
    },
    "validation": {
      // <-- This key must match your code
      "status": "valid", // or 1
      "message": "Document number is valid and matches the profile.",
    },
    "extracted_data": {
      "personal_details": {
        "Personal Information": {"Name": "Rahul Sharma"},
      },
    },
  },
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'kSCan',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        fontFamily: 'Cera Pro',
        brightness: Brightness.light,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        fontFamily: 'Cera Pro',
        brightness: Brightness.dark,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
      home: const SplashScreen(), // Use SplashScreen as the initial screen
    );
  }
}
