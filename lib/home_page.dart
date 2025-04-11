import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'login_page.dart';
import 'educationDetails.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final dobController = TextEditingController();
  final fatherNameController = TextEditingController();
  final motherNameController = TextEditingController();
  final contactController = TextEditingController();
  final addressController = TextEditingController();

  String? selectedNationality;
  String? selectedCategory;
  bool isSaving = false;

  final List<Map<String, String>> nationalities = [
    {"name": "India", "flag": "🇮🇳"},
    {"name": "United States", "flag": "🇺🇸"},
    {"name": "United Kingdom", "flag": "🇬🇧"},
    {"name": "Canada", "flag": "🇨🇦"},
    {"name": "Australia", "flag": "🇦🇺"},
    {"name": "Germany", "flag": "🇩🇪"},
    {"name": "France", "flag": "🇫🇷"},
    {"name": "Japan", "flag": "🇯🇵"},
    {"name": "China", "flag": "🇨🇳"},
    {"name": "Brazil", "flag": "🇧🇷"},
  ];

  final List<Map<String, String>> categories = [
    {"name": "General", "flag": "🟢"},
    {"name": "OBC", "flag": "🟡"},
    {"name": "SC", "flag": "🔴"},
    {"name": "ST", "flag": "🔵"},
  ];

  @override
  void initState() {
    super.initState();
    dobController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _fetchUserData();
  }

  @override
  void dispose() {
    nameController.dispose();
    dobController.dispose();
    fatherNameController.dispose();
    motherNameController.dispose();
    contactController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection("applications")
              .where("userId", isEqualTo: user.uid)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        var data = querySnapshot.docs.first.data() as Map<String, dynamic>;

        setState(() {
          nameController.text = data["name"] ?? "";
          dobController.text = data["dob"] ?? "";
          fatherNameController.text = data["fatherName"] ?? "";
          motherNameController.text = data["motherName"] ?? "";
          contactController.text = data["contact"] ?? "";
          addressController.text = data["address"] ?? "";
          selectedCategory = data["category"] ?? categories.first["name"];
          selectedNationality =
              data["nationality"] ?? nationalities.first["name"];
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<bool> _saveData() async {
    if (_formKey.currentState!.validate() && !isSaving) {
      setState(() => isSaving = true);
      _showLoadingDialog();

      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception("User not authenticated");
        }

        CollectionReference applications = FirebaseFirestore.instance
            .collection("applications");

        QuerySnapshot querySnapshot =
            await applications.where("userId", isEqualTo: user.uid).get();

        if (querySnapshot.docs.isNotEmpty) {
          String docId = querySnapshot.docs.first.id;
          await applications.doc(docId).update({
            "name": nameController.text,
            "dob": dobController.text,
            "fatherName": fatherNameController.text,
            "motherName": motherNameController.text,
            "contact": contactController.text,
            "address": addressController.text,
            "category": selectedCategory,
            "nationality": selectedNationality,
          });
        } else {
          await applications.add({
            "name": nameController.text,
            "dob": dobController.text,
            "fatherName": fatherNameController.text,
            "motherName": motherNameController.text,
            "contact": contactController.text,
            "address": addressController.text,
            "category": selectedCategory,
            "nationality": selectedNationality,
            "userId": user.uid,
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data saved successfully!")),
        );

        return true;
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
        return false;
      } finally {
        Navigator.pop(context);
        setState(() => isSaving = false);
      }
    }
    return false;
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => WillPopScope(
            onWillPop: () async => false,
            child: Center(
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
                      const Text("Saving data", style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
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
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SizedBox(
                width: 300,
                height: 70,
                child: _buildTextField(nameController, "Name"),
              ),
              SizedBox(
                width: 300,
                height: 70,
                child: _buildDateField(context, dobController, "Date of Birth"),
              ),
              SizedBox(
                width: 300,
                height: 70,
                child: _buildTextField(fatherNameController, "Father's Name"),
              ),
              SizedBox(
                width: 300,
                height: 70,
                child: _buildTextField(motherNameController, "Mother's Name"),
              ),
              SizedBox(
                width: 300,
                height: 70,
                child: _buildTextField(contactController, "Contact"),
              ),
              SizedBox(
                width: 300,
                height: 70,
                child: _buildTextField(addressController, "Address"),
              ),
              SizedBox(
                width: 300,
                height: 70,
                child: _buildDropdown(
                  "Nationality",
                  nationalities,
                  selectedNationality,
                  (val) => setState(() => selectedNationality = val),
                ),
              ),
              SizedBox(
                width: 300,
                height: 70,
                child: _buildDropdown(
                  "Category",
                  categories,
                  selectedCategory,
                  (val) => setState(() => selectedCategory = val),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Center the buttons
                children: [
                  SizedBox(
                    width: 150, // Half the width since both buttons should fit
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          isSaving
                              ? null
                              : () async {
                                if (await _saveData()) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => const EducationDetails(),
                                    ),
                                  );
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, // Text color
                        backgroundColor: Colors.blue, // Button background color
                      ),
                      child: const Text("Save & Next"),
                    ),
                  ),
                  const SizedBox(width: 10), // Space between buttons
                  SizedBox(
                    width: 150,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EducationDetails(),
                            ),
                          ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, // Text color
                        backgroundColor: Colors.blue, // Button background color
                      ),
                      child: const Text("Next"),
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

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        validator:
            (value) => value!.isEmpty ? "Please enter your $label" : null,
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context,
    TextEditingController controller,
    String label,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              setState(() {
                controller.text = DateFormat(
                  'yyyy-MM-dd',
                ).format(pickedDate ?? DateTime.now());
              });
            },
          ),
        ),
        validator:
            (value) => value!.isEmpty ? "Please select your $label" : null,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<Map<String, String>> items,
    String? selectedValue,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        items:
            items.map((item) {
              return DropdownMenuItem<String>(
                value: item["name"],
                child: Text("${item["flag"]} ${item["name"]}"),
              );
            }).toList(),
        onChanged: onChanged,
        validator:
            (value) => value == null ? "Please select your $label" : null,
      ),
    );
  }
}
