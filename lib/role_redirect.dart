import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'admin_page.dart';

class RoleBasedRedirectPage extends StatelessWidget {
  const RoleBasedRedirectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text("No user found.")));
    }

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('applications').doc(uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(decoration: TextDecoration.none),
              ),
            ),
          );
        }
        final isAdmin =
            snapshot.data?.exists == true &&
            (snapshot.data!.data() as Map<String, dynamic>?)?['role'] ==
                'admin';

        if (isAdmin) {
          return const AdminPage();
        } else {
          return const MyHomePage();
        }
      },
    );
  }
}
