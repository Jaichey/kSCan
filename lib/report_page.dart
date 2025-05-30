import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'dart:convert';

class ReportPageMulti extends StatelessWidget {
  final List<Map<String, dynamic>> results;

  const ReportPageMulti({super.key, required this.results});

  dynamic _getReportValue(
    Map<String, dynamic> data,
    List<String> possibleKeys,
  ) {
    for (var key in possibleKeys) {
      if (data.containsKey(key) &&
          data[key] != null &&
          data[key].toString().isNotEmpty) {
        return data[key];
      }
    }
    return "Not Available";
  }

  Widget _buildInfoRow(
    String label,
    Map<String, dynamic> data,
    List<String> fieldKeys,
  ) {
    final value = _getReportValue(data, fieldKeys);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value.toString())),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    Map<String, dynamic> data,
    List<Map<String, List<String>>> fieldConfigs,
  ) {
    final items = <Widget>[];

    for (final config in fieldConfigs) {
      final label = config['label']!.first;
      final keys = config['keys']!;
      final value = _getReportValue(data, keys);
      if (value != "Not Available") {
        items.add(_buildInfoRow(label, data, keys));
      }
    }

    return items.isNotEmpty
        ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            ...items,
            const SizedBox(height: 16),
          ],
        )
        : const SizedBox.shrink();
  }

  Future<void> _generatePdf(BuildContext context) async {
    final pdf = pw.Document();

    final extractedData =
        results.isNotEmpty && results[0]["extracted_data"] is Map
            ? results[0]["extracted_data"] as Map<String, dynamic>
            : <String, dynamic>{};
    final comparisonResult =
        results.isNotEmpty && results[0]["comparison_result"] is Map
            ? results[0]["comparison_result"] as Map<String, dynamic>
            : <String, dynamic>{};
    final details =
        comparisonResult['details'] is Map
            ? comparisonResult['details'] as Map<String, dynamic>
            : <String, dynamic>{};
    final faceComparison =
        results.isNotEmpty && results[0]["face_comparison"] is Map
            ? results[0]["face_comparison"] as Map<String, dynamic>
            : <String, dynamic>{};

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'DOCUMENT REPORT ANALYSIS',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Verification Results',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text('Verdict: ${comparisonResult['verdict'] ?? 'N/A'}'),
              pw.Text(
                'Overall Similarity: ${comparisonResult['similarity_score']?.toStringAsFixed(2) ?? 'N/A'}%',
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Face Verification',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Result: ${faceComparison['photoMatch']?.toString().toUpperCase() ?? 'N/A'}',
              ),
              if (faceComparison['faceSimilarity'] != null)
                pw.Text(
                  'Similarity: ${(faceComparison['faceSimilarity'] * 100).toStringAsFixed(2)}%',
                ),
              pw.SizedBox(height: 20),
              ...details.entries
                  .where((entry) {
                    final info = entry.value as Map<String, dynamic>? ?? {};
                    final profile =
                        info['profile_value']?.toString().trim() ?? '';
                    final document =
                        info['extracted_value']?.toString().trim() ?? '';
                    return profile.isNotEmpty && document.isNotEmpty;
                  })
                  .map((entry) {
                    final field = entry.key;
                    final info = entry.value as Map<String, dynamic>? ?? {};
                    final profileValue = info['profile_value'] ?? 'N/A';
                    final documentValue = info['extracted_value'] ?? 'N/A';
                    final similarity = info['similarity']?.toString() ?? '0';
                    final match = info['match'] == true;

                    return pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          field,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text('Profile: $profileValue'),
                        pw.Text('Document: $documentValue'),
                        pw.Text('Match: ${match ? '✓' : '✗'} ($similarity%)'),
                        pw.Divider(),
                      ],
                    );
                  })
                  .toList(),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) => pdf.save());
  }

  @override
  // Replace your build method with this corrected version:
  @override
  Widget build(BuildContext context) {
    if (results.isEmpty || results[0] == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final extractedData =
        results[0]["extracted_data"] as Map<String, dynamic>? ?? {};
    final comparisonResult =
        results[0]["comparison_result"] as Map<String, dynamic>? ?? {};
    final details = comparisonResult["details"] as Map<String, dynamic>? ?? {};
    final faceComparison =
        results[0]["face_comparison"] as Map<String, dynamic>? ?? {};
    final faceMatch =
        faceComparison['photoMatch']?.toString() ?? 'Not Available';
    final faceSimilarity = faceComparison['faceSimilarity'] as double?;
    final faceImages = results[0]["face_images"] as Map<String, dynamic>? ?? {};

    // Helper function to build image widget safely
    Widget _buildFaceImage(String? imagePath) {
      if (imagePath == null || imagePath.isEmpty) {
        return Container(
          width: 150,
          height: 150,
          color: Colors.grey[300],
          child: const Icon(Icons.person, size: 50),
        );
      }

      try {
        if (imagePath.startsWith('http')) {
          return Image.network(
            imagePath,
            width: 150,
            height: 150,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
          );
        } else if (imagePath.startsWith('data:image')) {
          return Image.memory(
            base64Decode(imagePath.split(',')[1]),
            width: 150,
            height: 150,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
          );
        } else {
          return Image.file(
            File(imagePath),
            width: 150,
            height: 150,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
          );
        }
      } catch (e) {
        return _buildPlaceholderImage();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Document Report"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _generatePdf(context),
            tooltip: 'Generate PDF',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DOCUMENT REPORT ANALYSIS',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),

            // Verification Results
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verification Results: ${comparisonResult['verdict'] ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Overall Similarity: ${comparisonResult['similarity_score']?.toStringAsFixed(2) ?? 'N/A'}%',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Face Verification
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Face Verification',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Result: '),
                      Text(
                        faceMatch.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              faceMatch == 'success'
                                  ? Colors.green
                                  : faceMatch == 'failed'
                                  ? Colors.red
                                  : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  if (faceSimilarity != null)
                    Text(
                      'Similarity: ${(faceSimilarity * 100).toStringAsFixed(2)}%',
                    ),
                  const SizedBox(height: 16),

                  // Face Images
                  if (faceImages['document_face'] != null ||
                      faceImages['uploaded_face'] != null)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          if (faceImages['document_face'] != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Column(
                                children: [
                                  const Text('Document Face'),
                                  const SizedBox(height: 8),
                                  _buildFaceImage(faceImages['document_face']),
                                ],
                              ),
                            ),
                          if (faceImages['uploaded_face'] != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Column(
                                children: [
                                  const Text('Supporting Face'),
                                  const SizedBox(height: 8),
                                  _buildFaceImage(faceImages['uploaded_face']),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Detailed Comparison
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detailed Comparison',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...details.entries
                      .where((entry) {
                        final info = entry.value as Map<String, dynamic>? ?? {};
                        final profile =
                            info['profile_value']?.toString().trim() ?? '';
                        final document =
                            info['extracted_value']?.toString().trim() ?? '';
                        return profile.isNotEmpty && document.isNotEmpty;
                      })
                      .map((entry) {
                        final field = entry.key;
                        final info = entry.value as Map<String, dynamic>? ?? {};
                        final profileValue = info['profile_value'] ?? 'N/A';
                        final documentValue = info['extracted_value'] ?? 'N/A';
                        final similarity =
                            info['similarity']?.toString() ?? '0';
                        final match = info['match'] == true;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                field,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('Profile Value: $profileValue'),
                              Text('Document Value: $documentValue'),
                              Row(
                                children: [
                                  const Text('Match: '),
                                  Icon(
                                    match ? Icons.check : Icons.close,
                                    color: match ? Colors.green : Colors.red,
                                  ),
                                  Text(' ($similarity%)'),
                                ],
                              ),
                              const Divider(),
                            ],
                          ),
                        );
                      })
                      .toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    // Placeholder image widget for error handling

    return Container(
      width: 150,
      height: 150,
      color: Colors.grey[300],
      child: const Icon(Icons.error, color: Colors.red),
    );
  }

  Widget _buildFaceImage(dynamic imageData) {
    if (imageData == null || imageData['data'] == null) {
      return Container(
        width: 150,
        height: 150,
        color: Colors.grey[300],
        child: Icon(Icons.error),
      );
    }

    if (imageData['type'] == 'base64') {
      return Image.memory(
        base64Decode(imageData['data'].split(',')[1]),
        width: 150,
        height: 150,
        fit: BoxFit.cover,
      );
    } else {
      return Image.network(
        imageData['data'],
        width: 150,
        height: 150,
        fit: BoxFit.cover,
      );
    }
  }
}
