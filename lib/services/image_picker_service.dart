import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<bool> _requestPermission(ImageSource source) async {
    if (kIsWeb) return true;

    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      return status.isGranted;
    } else {
      if (Platform.isAndroid) {
        if (await Permission.photos.request().isGranted) {
          return true;
        } else {
          final storageStatus = await Permission.storage.request();
          return storageStatus.isGranted;
        }
      }
      return true;
    }
  }

  Future<String?> pickAndUploadImage({
    required String pathInStorage,
    required ImageSource source,
    required BuildContext context,
  }) async {
    try {
      final hasPermission = await _requestPermission(source);
      if (!hasPermission) {
        debugPrint("❌ Permission denied");
        return null;
      }

      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        debugPrint("❌ No image selected.");
        return null;
      }

      Uint8List imageData;

      if (kIsWeb) {
        imageData = await pickedFile.readAsBytes();
      } else {
        // ✅ Step 1: Enable overlays to avoid status bar overlap during cropping
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
        );

        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          compressQuality: 85,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: Colors.blue,
              toolbarWidgetColor: Colors.white,
              statusBarColor: Colors.blue,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
              hideBottomControls: false,
              cropFrameStrokeWidth: 2,
              backgroundColor: Colors.black,
            ),
            IOSUiSettings(title: 'Crop Image'),
          ],
        );

        // ✅ Step 2: Restore immersive sticky mode after cropping
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

        if (croppedFile == null) {
          debugPrint("❌ Cropping cancelled.");
          return null;
        }

        imageData = await File(croppedFile.path).readAsBytes();
      }

      final ref = FirebaseStorage.instance.ref().child(pathInStorage);
      await ref.putData(imageData, SettableMetadata(contentType: 'image/jpeg'));

      final downloadUrl = await ref.getDownloadURL();
      debugPrint("✅ Uploaded image URL: $downloadUrl");

      return downloadUrl;
    } catch (e, stack) {
      debugPrint("❌ Image upload failed: $e");
      debugPrint("$stack");
      return null;
    }
  }

  // ✅ Optional utility: set status bar color if needed
  void setStatusBarColor(Color color) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(statusBarColor: color),
    );
  }

  // ✅ Enable immersive fullscreen (use after crop if needed)
  void enableFullScreenMode() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
  }

  // ✅ Adds top padding dynamically based on status bar
  Widget buildWithTopPadding(Widget child, BuildContext context) {
    double statusBarHeight = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.only(top: statusBarHeight),
      child: child,
    );
  }
}
