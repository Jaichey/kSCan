import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
      if (userId.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = "User not logged in.";
        });
        return;
      }

      QuerySnapshot userSnapshot =
          await FirebaseFirestore.instance
              .collection("applications")
              .where("userId", isEqualTo: userId)
              .get();

      if (userSnapshot.docs.isNotEmpty) {
        setState(() {
          userData = userSnapshot.docs.first.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "No application data found for this user.";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error fetching data: ${e.toString()}";
      });
      print("Firestore Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Generated Report")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : userData != null
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Report Summary",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Name: ${userData!["name"] ?? "N/A"}",
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            "DOB: ${userData!["dob"] ?? "N/A"}",
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            "Father's Name: ${userData!["fatherName"] ?? "N/A"}",
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            "Mother's Name: ${userData!["motherName"] ?? "N/A"}",
                            style: const TextStyle(fontSize: 16),
                          ),
                          // Text(
                          //   "Category: ${userData!["option"] ?? "N/A"}",
                          //   style: const TextStyle(fontSize: 16),
                          // ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Back to Home"),
                      ),
                    ),
                  ],
                )
                : Center(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
      ),
    );
  }
}
