import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

class DocReaderService {
  final url = Uri.parse(
    'http://192.168.29.214:5000/extract',
  ); // your backend IP

  Future<String> extractDocumentDetails({required dynamic file}) async {
    var request = http.MultipartRequest('POST', url); // <-- fixed here

    if (kIsWeb) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          file["bytes"] as Uint8List,
          filename: file["name"],
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file["path"],
          filename: file["name"],
        ),
      );
    }

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final decoded = json.decode(responseBody);
        return decoded['result'] ?? 'No data returned';
      } else {
        return 'Error: ${response.statusCode}\n$responseBody';
      }
    } catch (e) {
      return 'Upload failed: $e';
    }
  }
}
