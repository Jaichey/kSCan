//Created by Dhanunjai on 23-02-2025

// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:kscan/profile.dart';
import 'education_details.dart';
import 'feedback_screen.dart';
import 'help_faq_screen.dart';
import 'contact_us_screen.dart';
import 'about_us_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final dobController = TextEditingController();
  final fatherNameController = TextEditingController();
  final motherNameController = TextEditingController();
  final contactController = TextEditingController();
  final addressController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _iconAnimationController;

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
  @override
  void initState() {
    super.initState();
    dobController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _fetchUserData();

    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
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

      if (!mounted) return; // <-- Add this check here

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
            "email": user.email,
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
      key: _scaffoldKey,
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          _iconAnimationController.forward();
        } else {
          _iconAnimationController.reverse();
        }
      },
      appBar: AppBar(
        leading: IconButton(
          icon: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _iconAnimationController,
          ),
          onPressed: () {
            if (_scaffoldKey.currentState!.isDrawerOpen) {
              Navigator.of(context).pop(); // Close drawer
            } else {
              _scaffoldKey.currentState!.openDrawer(); // Open drawer
            }
          },
        ),
        title: const Text("kSCan"),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: Colors.blue),
                  child: Text(
                    'Menu',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.feedback),
                  title: Text('Feedback'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FeedbackScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.help_outline),
                  title: Text('Help & FAQs'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HelpFaqScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.contact_phone),
                  title: Text('Contact Us'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ContactUsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('About Us'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AboutUsScreen()),
                    );
                  },
                ),
                SizedBox(height: 80),
              ],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                child: Text(
                  '© 2025 kSCan',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Text(
                  "Application Form",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
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
                  const SizedBox(width: 235),
                  Transform.translate(
                    offset: Offset(0, -10),
                    child: SizedBox(
                      width: 50,
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
                                            (context) =>
                                                const EducationDetails(),
                                      ),
                                    );
                                  }
                                },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            // Adjust icon size if needed
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

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5), // Reduce padding
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue, width: 2.0),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.blue, // Blue border when focused
              width: 2.0,
            ),
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
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
      padding: const EdgeInsets.symmetric(
        vertical: 5,
      ), // Reduce padding slightly
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.blue, // Blue border when focused
              width: 2.0,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 15,
          ), // Maintain height
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
