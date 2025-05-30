import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'home_page.dart';
import 'admin_page.dart';

class WelcomeLoader extends StatefulWidget {
  final String name;
  final bool isAdmin;

  const WelcomeLoader({super.key, required this.name, required this.isAdmin});

  @override
  State<WelcomeLoader> createState() => _WelcomeLoaderState();
}

class _WelcomeLoaderState extends State<WelcomeLoader> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => widget.isAdmin ? const AdminPage() : const MyHomePage(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/success.json',
                width: 200,
                height: 200,
                repeat: true,
              ),
              const SizedBox(height: 30),
              Text(
                'Welcome, ${widget.name}!',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
