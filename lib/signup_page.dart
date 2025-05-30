import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'services/error_dialog.dart';

class SignUpPage extends StatefulWidget {
  static route() => MaterialPageRoute(builder: (context) => const SignUpPage());
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with TickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool _isPasswordVisible = false;

  late AnimationController _logoController;
  late AnimationController _formController;
  late AnimationController _buttonController;

  late Animation<double> _logoAnimation;
  late Animation<Offset> _formAnimation;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeIn,
    );

    _formController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _formAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _formController, curve: Curves.easeOut));

    _buttonController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _buttonAnimation = CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeIn,
    );

    // Start animations
    _logoController.forward();
    _formController.forward();
    _buttonController.forward();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _logoController.dispose();
    _formController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> createUserWithEmailAndPassword() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      Navigator.pushReplacement(context, LoginPage.route());

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      HapticFeedback.vibrate();
      showErrorDialog(
        context: context,
        animationPath: 'assets/animations/error.json',
        message: 'An error occurred: ${e.message}',
      );
    } catch (e) {
      HapticFeedback.vibrate();
      showErrorDialog(
        context: context,
        animationPath: 'assets/animations/error.json',
        message: 'An unexpected error occurred: $e',
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Transform.translate(
          offset: Offset(0, -55),
          child: Padding(
            padding: EdgeInsets.only(top: 5),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Animation
                  FadeTransition(
                    opacity: _logoAnimation,
                    child: Flexible(
                      child: Image.asset(
                        'assets/images/kSCan_Loading_Login.gif',
                        width: 280,
                      ),
                    ),
                  ),
                  // Title Text
                  Transform.translate(
                    offset: Offset(0, -18),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Form Fields with Slide In Animation
                  SlideTransition(
                    position: _formAnimation,
                    child: Column(
                      children: [
                        // Email Field
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            width: 300,
                            height: 60,
                            child: TextFormField(
                              controller: emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.blue,
                                    width: 2.0,
                                  ),
                                ),
                              ),
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? "Enter your email"
                                          : !RegExp(
                                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                          ).hasMatch(value)
                                          ? "Enter a valid email"
                                          : null,
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Password Field
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            width: 300,
                            height: 60,
                            child: TextFormField(
                              controller: passwordController,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.blue,
                                    width: 2.0,
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),

                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              obscureText: !_isPasswordVisible,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter a password";
                                } else if (value.length < 6) {
                                  return "Password must be at least 6 characters";
                                } else if (!RegExp(
                                  r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$',
                                ).hasMatch(value)) {
                                  return "Password must contain at least one letter and one number";
                                } else if (value.contains(' ')) {
                                  return "Password cannot contain spaces";
                                } else if (value.length > 20) {
                                  return "Password cannot exceed 20 characters";
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, -18),
                    child: const SizedBox(height: 10),
                  ),
                  Text(
                    '1.Password must be at least 6 characters long.'
                    '\n2.Contain at least one letter and one number.'
                    '\n3.Cannot contain spaces.'
                    '\n4.Cannot exceed 20 characters.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 10),
                  // Button with Fade-in Animation
                  FadeTransition(
                    opacity: _buttonAnimation,
                    child:
                        isLoading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                              width: 300,
                              height: 60,
                              child: ElevatedButton(
                                onPressed: createUserWithEmailAndPassword,
                                child: const Text(
                                  "SIGN UP",
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 255, 255, 255),
                                  ),
                                ),
                              ),
                            ),
                  ),
                  const SizedBox(height: 15),
                  // Sign In Link
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Already have an account? ",
                        style: TextStyle(fontSize: 16),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap:
                              () => Navigator.pushReplacement(
                                context,
                                LoginPage.route(),
                              ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
