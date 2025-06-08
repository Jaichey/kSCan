import 'dart:typed_data';
import 'dart:convert';
import 'dart:io' as io;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'report_page.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> selectedFiles = [];
  bool isSubmitting = false;

  final List<String> docTypesRequiringPhoto = ['aadhaar', 'marksheet'];
  String loadingMessage = "Please wait...";

  @override
  void initState() {
    super.initState();
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: kIsWeb,
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        for (var file in result.files) {
          selectedFiles.add(
            kIsWeb
                ? {
                  "name": file.name,
                  "bytes": file.bytes!,
                  "docType": "",
                  "docNumber": "",
                  "extraImageBytes": null,
                  "extraImagePath": null,
                }
                : {
                  "name": file.name,
                  "path": file.path!,
                  "docType": "",
                  "docNumber": "",
                  "extraImageBytes": null,
                  "extraImagePath": null,
                },
          );
        }
      });
    }
  }

  Future<void> captureFromCamera() async {
    if (kIsWeb) {
      showError(
        "Camera capture is not supported on web.",
        "assets/animations/camera_error.json",
      );
      return;
    }
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        selectedFiles.add({
          "name": photo.name,
          "path": photo.path,
          "docType": "",
          "docNumber": "",
          "extraImageBytes": null,
          "extraImagePath": null,
        });
      });
    }
  }

  void showUploadOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Choose Upload Option"),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt, size: 40),
                    onPressed: () {
                      Navigator.pop(context);
                      captureFromCamera();
                    },
                  ),
                  const Text("Camera"),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.upload_file, size: 40),
                    onPressed: () {
                      Navigator.pop(context);
                      pickFile();
                    },
                  ),
                  const Text("Upload File"),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> pickExtraImage(int index) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        selectedFiles[index]["extraImageBytes"] = bytes;
        selectedFiles[index]["extraImagePath"] = picked.path;
      });
    }
  }

  Future<String?> getDocumentId(String userUid) async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection("applications")
              .where("userId", isEqualTo: userUid)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
    } catch (e) {
      print("Error fetching document ID: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> sendFileForVerification({
    required String fileName,
    String? filePath,
    Uint8List? fileBytes,
    Uint8List? extraImageBytes,
    String? extraImagePath,
    required String uid,
    required String docType,
    required String docNumber,
    required String documentId,
  }) async {
    try {
      final uri = Uri.parse(
        "https://kscan-backend.onrender.com/upload-and-verify",
      );
      // final uri = Uri.parse("http://127.0.0.1:5000/upload-and-verify");
      final request = http.MultipartRequest('POST', uri);
      request.fields['uid'] = uid;
      request.fields['docType'] = docType;
      request.fields['docNumber'] = docNumber;
      request.fields['documentId'] = documentId;
      request.fields['requireFaceComparison'] =
          docTypesRequiringPhoto.contains(docType).toString();

      if (kIsWeb && fileBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
        );
        if (extraImageBytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'face',
              extraImageBytes,
              filename: "face_$fileName",
            ),
          );
        }
      } else if (filePath != null) {
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
        if (extraImagePath != null) {
          request.files.add(
            await http.MultipartFile.fromPath('extraImage', extraImagePath),
          );
        }
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        final jsonString = await response.stream.bytesToString();
        final jsonResponse = json.decode(jsonString);

        // Enhance the response with face image paths
        if (jsonResponse['results'] != null &&
            jsonResponse['results'].isNotEmpty) {
          final result = jsonResponse['results'][0];
          if (extraImageBytes != null || extraImagePath != null) {
            result['face_images'] = {
              'uploaded_face':
                  kIsWeb
                      ? 'data:image/jpeg;base64,${base64Encode(extraImageBytes!)}'
                      : extraImagePath,
              'document_face': result['extracted_data']?['face_image_path'],
            };
          }
          return result;
        }
      }
    } catch (e) {
      print("Verification error: $e");
    }
    return null;
  }

  void showError(String message, String lottieAsset) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(lottieAsset, height: 150),
                const SizedBox(height: 12),
                Text(message),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  Future<void> submitFiles() async {
    if (!mounted) return;
    setState(() {
      isSubmitting = true;
      loadingMessage = "Please wait...";
    });

    try {
      if (selectedFiles.isEmpty) {
        showError("No documents selected.", "assets/animations/warning.json");
        return;
      }

      for (var file in selectedFiles) {
        if (file["docType"].isEmpty ||
            (file["docNumber"]?.trim().isEmpty ?? true)) {
          showError(
            "Please fill all document types and numbers.",
            "assets/animations/upload_fail.json",
          );
          return;
        }

        if (docTypesRequiringPhoto.contains(file["docType"]) &&
            file["extraImageBytes"] == null &&
            file["extraImagePath"] == null) {
          showError(
            "Missing supporting photo for ${file["docType"]}.",
            "assets/animations/photo.json",
          );
          return;
        }
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        showError(
          "Please Login to submit files",
          "assets/animations/error.json",
        );
        return;
      }

      final documentId = await getDocumentId(user.uid);
      if (documentId == null) {
        showError("Document ID not found.", "assets/animations/error.json");
        return;
      }

      List<Map<String, dynamic>> allResults = [];

      for (int i = 0; i < selectedFiles.length; i++) {
        final file = selectedFiles[i];
        if (!mounted) return;
        setState(() {
          loadingMessage =
              "Verifying Document ${i + 1} of ${selectedFiles.length}...";
        });

        final result = await sendFileForVerification(
          fileName: file["name"],
          filePath: file["path"],
          fileBytes: file["bytes"],
          extraImageBytes: file["extraImageBytes"],
          extraImagePath: file["extraImagePath"],
          uid: user.uid,
          docType: file["docType"],
          docNumber: file["docNumber"],
          documentId: documentId,
        );

        if (result != null) {
          result["docType"] = file["docType"];
          allResults.add(result);
        }

        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (!mounted) return;
      setState(() => isSubmitting = false);

      if (allResults.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ReportPageMulti(
                  results: allResults,
                  documentType: allResults[0]['docType'].toUpperCase(),
                ),
          ),
        );
      } else {
        showError(
          "Server problem, please try again.",
          "assets/animations/failure.json",
        );
      }
    } catch (e) {
      print("Unexpected error: $e");
      if (mounted) {
        showError("Unexpected error: $e", "assets/animations/error.json");
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text("Upload Documents"),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child:
                      selectedFiles.isEmpty
                          ? const Center(child: Text("No documents selected."))
                          : ListView.builder(
                            itemCount: selectedFiles.length,
                            itemBuilder: (context, index) {
                              final file = selectedFiles[index];
                              final isImage =
                                  file["name"].toLowerCase().endsWith(".png") ||
                                  file["name"].toLowerCase().endsWith(".jpg") ||
                                  file["name"].toLowerCase().endsWith(".jpeg");
                              final isPdf = file["name"].toLowerCase().endsWith(
                                ".pdf",
                              );

                              Widget thumbnail;
                              if (isImage) {
                                if (kIsWeb && file["bytes"] != null) {
                                  thumbnail = Image.memory(
                                    file["bytes"],
                                    width: 60,
                                    height: 60,
                                  );
                                } else if (file["path"] != null) {
                                  thumbnail = Image.file(
                                    io.File(file["path"]),
                                    width: 60,
                                    height: 60,
                                  );
                                } else {
                                  thumbnail = const Icon(
                                    Icons.insert_drive_file,
                                  );
                                }
                              } else if (isPdf) {
                                thumbnail = const Icon(
                                  Icons.picture_as_pdf_rounded,
                                  color: Colors.red,
                                  size: 40,
                                );
                              } else {
                                thumbnail = const Icon(
                                  Icons.insert_drive_file,
                                  size: 60,
                                );
                              }
                              TextEditingController docNumberController =
                                  TextEditingController(
                                    text: file["docNumber"],
                                  );
                              docNumberController.addListener(() {
                                selectedFiles[index]["docNumber"] =
                                    docNumberController.text;
                              });

                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ListTile(
                                        leading: thumbnail,
                                        title: Text(file["name"]),
                                        trailing: IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            setState(
                                              () =>
                                                  selectedFiles.removeAt(index),
                                            );
                                          },
                                        ),
                                      ),
                                      DropdownButtonFormField<String>(
                                        value:
                                            file["docType"].isNotEmpty
                                                ? file["docType"]
                                                : null,
                                        hint: const Text(
                                          "Select Document Type",
                                        ),
                                        items:
                                            [
                                                  'aadhaar',
                                                  'pan',
                                                  'passport',
                                                  'driving_license',
                                                  'bonafide',
                                                  'caste_certificate',
                                                  'voter_id',
                                                  'income_certificate',
                                                ]
                                                .map(
                                                  (type) => DropdownMenuItem(
                                                    value: type,
                                                    child: Text(
                                                      type.toUpperCase(),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            selectedFiles[index]["docType"] =
                                                value!;
                                            if (!docTypesRequiringPhoto
                                                .contains(value)) {
                                              selectedFiles[index]["extraImageBytes"] =
                                                  null;
                                              selectedFiles[index]["extraImagePath"] =
                                                  null;
                                            }
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      TextField(
                                        decoration: const InputDecoration(
                                          labelText: "Document Number",
                                        ),
                                        onChanged: (value) {
                                          selectedFiles[index]["docNumber"] =
                                              value;
                                        },
                                        controller: TextEditingController(
                                          text: file["docNumber"],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      if (docTypesRequiringPhoto.contains(
                                        file["docType"],
                                      )) ...[
                                        if (file["extraImageBytes"] != null ||
                                            file["extraImagePath"] != null)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child:
                                                kIsWeb
                                                    ? Image.memory(
                                                      file["extraImageBytes"],
                                                      height: 100,
                                                    )
                                                    : Image.file(
                                                      io.File(
                                                        file["extraImagePath"],
                                                      ),
                                                      height: 100,
                                                    ),
                                          ),
                                        ElevatedButton.icon(
                                          icon: const Icon(
                                            Icons.image,
                                            color: Colors.white,
                                          ),
                                          label: const Text(
                                            "Select Supporting Image",
                                          ),
                                          onPressed:
                                              () => pickExtraImage(index),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          "Note: Please upload a clear photo of your face for verification.",
                                          style: TextStyle(
                                            color: Colors.green[700],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("Add More Documents"),
                  onPressed: showUploadOptionsDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload, color: Colors.white),
                  label: const Text("Submit for Verification"),
                  onPressed: submitFiles,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isSubmitting)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SpinKitCircle(color: Colors.white),
                  const SizedBox(height: 30),
                  Flexible(
                    child: Text(
                      loadingMessage,
                      style: const TextStyle(
                        decoration: TextDecoration.none,
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
