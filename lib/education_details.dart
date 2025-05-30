//Created by: Dhanunjai
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:kscan/upload_docs.dart';
import 'home_page.dart';
import 'widgets/scrollable_year.dart';
import 'package:flutter/services.dart';

class EducationDetails extends StatefulWidget {
  const EducationDetails({super.key});

  @override
  State<EducationDetails> createState() => _EducationDetailsState();
}

class _EducationDetailsState extends State<EducationDetails> {
  final _formKey = GlobalKey<FormState>();
  final previousSchoolCollegeController = TextEditingController();
  final boardUniversityController = TextEditingController();
  final yearOfpassingController = TextEditingController();
  final marksgradeController = TextEditingController();
  bool isSaving = false;
  String? documentId; // Store the document ID

  @override
  void initState() {
    super.initState();
    _fetchExistingData();
  }

  Future<void> _fetchExistingData() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    var querySnapshot =
        await FirebaseFirestore.instance
            .collection("applications")
            .where("userId", isEqualTo: userId)
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      var doc = querySnapshot.docs.first;
      setState(() {
        documentId = doc.id;
        previousSchoolCollegeController.text = doc["previousSchool_College"];
        boardUniversityController.text = doc["Board_University"];
        yearOfpassingController.text = doc["YearOfPassing"];
        marksgradeController.text = doc["Marks_Grade"];
      });
    }
  }

  Future<void> _saveData() async {
    if (_formKey.currentState!.validate() && !isSaving) {
      setState(() => isSaving = true);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SpinKitCircle(color: Colors.blue, size: 50.0),
                      SizedBox(height: 10),
                      Text("Saving data", style: TextStyle(fontSize: 25)),
                    ],
                  ),
                ),
              ),
            ),
      );

      try {
        String userId = FirebaseAuth.instance.currentUser!.uid;
        Map<String, dynamic> educationData = {
          "previousSchool_College": previousSchoolCollegeController.text,
          "Board_University": boardUniversityController.text,
          "YearOfPassing": yearOfpassingController.text,
          "Marks_Grade": marksgradeController.text,
          "userId": userId,
        };

        if (documentId == null) {
          var docRef = await FirebaseFirestore.instance
              .collection("applications")
              .add(educationData);
          documentId = docRef.id;
        } else {
          await FirebaseFirestore.instance
              .collection("applications")
              .doc(documentId)
              .update(educationData);
        }

        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data saved successfully!")),
        );

        // ✅ Navigate to the next page after saving
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DocumentUploadScreen()),
        );
      } catch (e) {
        Navigator.pop(context); // Close dialog if error
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      } finally {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Application Form"),
        automaticallyImplyLeading: false,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.logout),
        //     onPressed:
        //         () => Navigator.pushReplacement(
        //           context,
        //           MaterialPageRoute(builder: (context) => const MyHomePage()),
        //         ),
        //   ),
        // ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Text(
                  "Education Details",
                  style: TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 300,
                height: 70,
                child: TextFormField(
                  controller: previousSchoolCollegeController,
                  decoration: InputDecoration(
                    labelText: "Previous School/College",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blue, // Blue border when focused
                        width: 2.0,
                      ),
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? "Required" : null,
                ),
              ),
              SizedBox(
                width: 300,
                height: 70,
                child: TextFormField(
                  controller: boardUniversityController,
                  decoration: InputDecoration(
                    labelText: "Board/University Name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blue, // Blue border when focused
                        width: 2.0,
                      ),
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? "Required" : null,
                ),
              ),
              //Year of Passing
              SizedBox(
                width: 300,
                height: 70,
                child: CupertinoYearSelector(
                  controller: yearOfpassingController,
                ),
              ),

              SizedBox(
                width: 300,
                height: 70,
                child: TextFormField(
                  controller: marksgradeController,
                  decoration: InputDecoration(
                    labelText: "Marks/Grade",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blue, // Blue border when focused
                        width: 2.0,
                      ),
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? "Required" : null,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Center the buttons
                children: [
                  Transform.translate(
                    offset: const Offset(0, -10),
                    child: Center(
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyHomePage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 200),
                  Transform.translate(
                    offset: Offset(0, -10),
                    child: Center(
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveData,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue,
                          ),
                          child:
                              isSaving
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
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
    );
  }
}
