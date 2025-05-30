import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/image_picker_service.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'services/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final ImagePickerService _imagePickerService = ImagePickerService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();

  String? _displayImage;
  bool _isUploading = false;
  late DocumentReference profileRef;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      profileRef = FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .collection("profile")
          .doc("details");

      _listenProfileChanges();
    }
  }

  void _listenProfileChanges() {
    profileRef.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          nameController.text = data['name'] ?? '';
          emailController.text = data['email'] ?? user?.email ?? '';
          contactController.text = data['contact'] ?? '';
          _displayImage =
              data['profileImageUrl'] == null
                  ? null
                  : "${data['profileImageUrl']}?v=${DateTime.now().millisecondsSinceEpoch}";
        });
      } else {
        setState(() {
          nameController.text = user?.displayName ?? '';
          emailController.text = user?.email ?? '';
        });
      }
    });
  }

  Future<void> _handleImagePick(ImageSource source) async {
    setState(() => _isUploading = true);

    final downloadUrl = await _imagePickerService.pickAndUploadImage(
      context: context,
      pathInStorage: "users/${user!.uid}/profile_picture.jpg",
      source: source,
    );

    if (downloadUrl != null) {
      await profileRef.set({
        'profileImageUrl': downloadUrl,
      }, SetOptions(merge: true));

      setState(() {
        _displayImage = downloadUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Profile picture updated!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to upload image.')),
      );
    }

    setState(() => _isUploading = false);
  }

  Future<void> _removeProfilePicture() async {
    try {
      final ref = FirebaseStorage.instance.ref(
        "users/${user!.uid}/profile_picture.jpg",
      );
      await ref.delete();
      await profileRef.set({'profileImageUrl': null}, SetOptions(merge: true));
      setState(() => _displayImage = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Profile picture removed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('⚠️ Failed to delete image: $e')));
    }
  }

  Future<void> _saveProfileDetails() async {
    await profileRef.set({
      'name': nameController.text.trim(),
      'email': emailController.text.trim(),
      'contact': contactController.text.trim(),
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('✅ Profile updated')));
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  Future<void> _refreshProfile() async {
    _listenProfileChanges();
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Choose from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _handleImagePick(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Take a Photo"),
                onTap: () {
                  Navigator.pop(context);
                  _handleImagePick(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text("Remove Photo"),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfilePicture();
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text("My Profile"),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const MyHomePage()),
                );
              },
            ),
            actions: [
              IconButton(
                icon: Icon(
                  themeProvider.isDarkMode
                      ? Icons.light_mode
                      : Icons.dark_mode, // Change icon based on theme
                  color: Theme.of(context).colorScheme.primary,
                ),
                tooltip:
                    themeProvider.isDarkMode
                        ? "Switch to Light Mode"
                        : "Switch to Dark Mode",
                onPressed: () {
                  themeProvider.toggleTheme(); // Toggle the theme
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refreshProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          child:
                              _displayImage == null
                                  ? const Icon(
                                    Icons.account_circle,
                                    size: 110,
                                    color: Colors.grey,
                                  )
                                  : ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: _displayImage!,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      placeholder:
                                          (context, url) =>
                                              const CircularProgressIndicator(),
                                      errorWidget:
                                          (context, url, error) => const Icon(
                                            Icons.account_circle,
                                            size: 110,
                                            color: Colors.grey,
                                          ),
                                    ),
                                  ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: Material(
                            color: Colors.blue,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap:
                                  _isUploading
                                      ? null
                                      : _showImageSourceActionSheet,
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: emailController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: contactController,
                    decoration: const InputDecoration(
                      labelText: 'Contact',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: _saveProfileDetails,
                    icon: const Icon(Icons.save),
                    label: const Text("Save Profile"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isUploading)
          Container(
            color: Colors.black45,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }
}
