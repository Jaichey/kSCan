import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kscan/main.dart'; // Change 'your_project_name' to your actual project name

void main() {
  testWidgets('Login screen renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that the login screen is displayed
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
  });

  testWidgets('Login fails with incorrect credentials', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());

    // Enter incorrect email and password
    await tester.enterText(find.byType(TextField).first, 'wrong@example.com');
    await tester.enterText(find.byType(TextField).last, 'wrongpassword');

    // Tap the login button
    await tester.tap(find.text('Login'));
    await tester.pump();

    // Check for error message
    expect(find.text('Invalid email or password!'), findsOneWidget);
  });

  testWidgets('Navigate to Sign Up screen', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    // Tap the "Sign Up" button
    await tester.tap(find.text("Don't have an account? Sign Up"));
    await tester.pumpAndSettle();

    // Verify that we navigated to the Sign Up screen
    expect(find.text('Sign Up'), findsOneWidget);
  });
}
