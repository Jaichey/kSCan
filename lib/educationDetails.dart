import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'report_page.dart';
import 'home_page.dart';

class EducationDetails extends StatefulWidget {
  const EducationDetails({super.key});

  @override
  State<EducationDetails> createState() => _EducationDetailsState();
}

class _EducationDetailsState extends State<EducationDetails> {
  File? _selectedImage;
  FilePickerResult? _uploadedFile;
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
                    children: [
                      const SpinKitCircle(color: Colors.blue, size: 50.0),
                      const SizedBox(height: 10),
                      const Text("Saving data", style: TextStyle(fontSize: 25)),
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
          // If no document exists, create a new one
          var docRef = await FirebaseFirestore.instance
              .collection("applications")
              .add(educationData);
          documentId = docRef.id;
        } else {
          // Update the existing document
          await FirebaseFirestore.instance
              .collection("applications")
              .doc(documentId)
              .update(educationData);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data saved successfully!")),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      } finally {
        Navigator.pop(context);
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _uploadedFile = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Application Form"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed:
                () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MyHomePage()),
                ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "Education Details",
                  style: TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: previousSchoolCollegeController,
                decoration: InputDecoration(
                  labelText: "Previous School/College",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: boardUniversityController,
                decoration: InputDecoration(
                  labelText: "Board/University Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: yearOfpassingController,
                decoration: InputDecoration(
                  labelText: "Year Of Passing",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: marksgradeController,
                decoration: InputDecoration(
                  labelText: "Marks/Grade",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickFile,
                child: const Text("Upload Document"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _pickImage(ImageSource.camera),
                child: const Text("Capture Image"),
              ),
              if (_selectedImage != null)
                Image.file(_selectedImage!, height: 100),
              if (_uploadedFile != null)
                Text("Selected File: ${_uploadedFile!.files.single.name}"),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _saveData,
                  child:
                      isSaving
                          ? const SpinKitFadingCircle(
                            color: Colors.white,
                            size: 24.0,
                          )
                          : const Text("Save"),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReportPage(),
                        ),
                      ),
                  child: const Text("Analyze"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
