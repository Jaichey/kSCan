import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> downloadZip(Uint8List zipBytes, String fileName) async {
  final status = await Permission.storage.request();
  if (status.isGranted) {
    try {
      Directory? downloadsDir;

      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsBytes(zipBytes);

      print('File downloaded to: ${file.path}');
    } catch (e) {
      print('Failed to save file: $e');
    }
  } else {
    print('Storage permission not granted');
  }
}
