import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_page.dart';
import 'package:dio/dio.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'services/doc_download_web.dart'
    if (dart.library.io) 'services/doc_download_mobile.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(initSettings);
    requestNotificationPermission(); // call permission after init
  }

  String searchQuery = '';
  final List<String> expectedDocuments = [
    "Aadhar Card",
    "Study Certificate",
    "Joining Certificate",
    "Marksheet",
    "Signature",
  ];
  bool isDownloading = false;
  @override
  Widget build(BuildContext context) {
    final usersRef = FirebaseFirestore.instance.collection('applications');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Confirm Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(context).pop(); // Close dialog first
                            await FirebaseAuth.instance.signOut();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Logged out successfully'),
                                ),
                              );
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            }
                          },
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search user by name...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: usersRef.orderBy('name', descending: false).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userDocs =
                    snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final role = data['role'];
                      final name =
                          (data['name'] ?? '').toString().toLowerCase();

                      return (role == null || role != 'admin') &&
                          name.contains(searchQuery);
                    }).toList();

                if (userDocs.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                return ListView.builder(
                  itemCount: userDocs.length,
                  itemBuilder: (context, index) {
                    final user = userDocs[index];
                    final data = user.data() as Map<String, dynamic>;
                    final userId = data['userId'] ?? user.id;

                    return Tooltip(
                      message:
                          'Tap to view ${data['name'] ?? 'this user'}\'s documents',
                      waitDuration: const Duration(milliseconds: 500),
                      showDuration: const Duration(seconds: 2),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            hoverColor: Colors.blue.withOpacity(0.05),
                            onTap: () => _showUserDetailsDialog(userId, data),
                            child: ListTile(
                              leading: FutureBuilder<String?>(
                                future: _getUserProfilePhoto(userId),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData &&
                                      snapshot.data != null) {
                                    return CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        snapshot.data!,
                                      ),
                                    );
                                  }
                                  return const Icon(
                                    Icons.account_circle,
                                    size: 40,
                                  );
                                },
                              ),
                              title: Text(data['name'] ?? 'No Name'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Email: ${data['email'] ?? 'No Email'}'),
                                  Text(
                                    'Contact: ${data['contact'] ?? 'No Contact'}',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _getUserProfilePhoto(String userId) async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('applications')
              .where('userId', isEqualTo: userId)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        final profileImageUrl = data['profileImageUrl'];
        if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
          return "$profileImageUrl?v=${DateTime.now().millisecondsSinceEpoch}";
        }
      }

      final storageRef = FirebaseStorage.instance.ref().child(
        'users/$userId/profile_picture.jpg',
      );

      final url = await storageRef.getDownloadURL();
      return "$url?v=${DateTime.now().millisecondsSinceEpoch}";
    } catch (e) {
      debugPrint("No profile image found for $userId: $e");
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _getUserDocumentStatus(
    String userId,
  ) async {
    final List<Map<String, dynamic>> statusList = [];
    try {
      final result =
          await FirebaseStorage.instance
              .ref('users/$userId/documents')
              .listAll();
      final existingFiles = result.items.map((item) => item.name).toSet();

      for (var docName in expectedDocuments) {
        final foundFile = existingFiles.firstWhere(
          (fileName) =>
              fileName.toLowerCase().startsWith(docName.toLowerCase()),
          orElse: () => '',
        );
        if (foundFile.isNotEmpty) {
          final url =
              await FirebaseStorage.instance
                  .ref('users/$userId/documents/$foundFile')
                  .getDownloadURL();
          statusList.add({
            'name': docName,
            'exists': true,
            'url': url,
            'fileName': foundFile,
          });
        } else {
          statusList.add({'name': docName, 'exists': false});
        }
      }
    } catch (e) {
      for (var docName in expectedDocuments) {
        statusList.add({'name': docName, 'exists': false});
      }
    }
    return statusList;
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  Future<void> showDownloadNotification(String username) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'download_channel', // Channel ID
          'Downloads', // Channel name
          channelDescription: 'Notification for document download',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@drawable/ic_notification', // Small icon for notification
          largeIcon: DrawableResourceAndroidBitmap(
            '@drawable/ic_notification_large',
          ), // Large icon
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      'Download Complete',
      'Documents for $username have been downloaded.',
      notificationDetails,
    );
  }

  void requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        if (!await Permission.notification.isGranted) {
          final result = await Permission.notification.request();
          if (!result.isGranted) {
            debugPrint("Notification permission not granted.");
          }
        }
      }
    }
  }

  Future<void> _downloadAndZipDocuments(
    String userName,
    List<Map<String, dynamic>> availableDocuments,
  ) async {
    try {
      final dio = Dio();
      final archive = Archive();

      for (var doc in availableDocuments) {
        final url = doc['url'];

        // Fetch file bytes
        final response = await dio.get<List<int>>(
          url,
          options: Options(responseType: ResponseType.bytes),
        );

        // Try to extract file extension from URL
        String extension = '';
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;
        if (pathSegments.isNotEmpty && pathSegments.last.contains('.')) {
          extension = '.${pathSegments.last.split('.').last}';
        }

        // If extension is still empty, try from content-type
        if (extension.isEmpty) {
          final headResponse = await dio.head(url);
          final contentType = headResponse.headers.value('content-type') ?? '';

          if (contentType.contains('image/jpeg')) {
            extension = '.jpg';
          } else if (contentType.contains('image/png')) {
            extension = '.png';
          } else if (contentType.contains('application/pdf')) {
            extension = '.pdf';
          } else if (contentType.contains('image/svg+xml')) {
            extension = '.svg';
          }
        }

        final fileName = "${doc['name']}$extension";

        archive.addFile(
          ArchiveFile(fileName, response.data!.length, response.data!),
        );
      }

      final zipEncoder = ZipEncoder();
      final zipBytes = zipEncoder.encode(archive);

      if (kIsWeb) {
        downloadZip(Uint8List.fromList(zipBytes), "$userName-documents.zip");
      } else {
        if (Platform.isAndroid || Platform.isIOS) {
          final status = await Permission.manageExternalStorage.request();
          if (status.isDenied || status.isPermanentlyDenied) {
            openAppSettings();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Please enable storage permission."),
              ),
            );
            return;
          }
        }
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        final zipFile = File('${downloadsDir.path}/$userName-documents.zip');
        await zipFile.writeAsBytes(zipBytes);
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Download Complete'),
                content: const Text(
                  'All documents have been downloaded and saved successfully.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
      await showDownloadNotification(userName);
    } catch (e) {
      debugPrint("Error zipping documents: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to download documents.")),
      );
    }
  }

  void _showUserDetailsDialog(String userId, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) {
        bool isDownloading = false; // local state for dialog
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(userData['name'] ?? 'User Details'),
              content: FutureBuilder<List<Map<String, dynamic>>>(
                future: _getUserDocumentStatus(userId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 150,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final documentStatus = snapshot.data!;
                  final availableDocuments =
                      documentStatus.where((e) => e['exists'] == true).toList();

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: ${userData['email'] ?? 'No Email'}'),
                        Text('Contact: ${userData['contact'] ?? 'No Contact'}'),
                        const SizedBox(height: 12),
                        const Text(
                          'Documents:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (availableDocuments.isEmpty)
                          const Text('No documents uploaded.')
                        else
                          ...documentStatus.map(
                            (e) => ListTile(
                              dense: true,
                              leading: Icon(
                                e['exists'] ? Icons.check_circle : Icons.cancel,
                                color: e['exists'] ? Colors.green : Colors.red,
                              ),
                              title: Text(e['name']),
                              onTap:
                                  e['exists']
                                      ? () async {
                                        final url = e['url'];
                                        if (await canLaunchUrl(
                                          Uri.parse(url),
                                        )) {
                                          await launchUrl(Uri.parse(url));
                                        }
                                      }
                                      : null,
                            ),
                          ),
                        const SizedBox(height: 12),
                        if (availableDocuments.isNotEmpty)
                          ElevatedButton.icon(
                            icon:
                                isDownloading
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(Icons.download),
                            label: Text(
                              isDownloading
                                  ? "Downloading..."
                                  : "Download All Documents",
                            ),
                            onPressed:
                                isDownloading
                                    ? null
                                    : () async {
                                      setStateDialog(() {
                                        isDownloading = true;
                                      });

                                      await _downloadAndZipDocuments(
                                        userData['name'] ?? 'user',
                                        availableDocuments,
                                      );

                                      setStateDialog(() {
                                        isDownloading = false;
                                      });
                                    },
                          ),
                      ],
                    ),
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
