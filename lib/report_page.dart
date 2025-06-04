import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'dart:math';

Map<String, dynamic> cleanResultJson(Map<String, dynamic> result) {
  final cleaned = Map<String, dynamic>.from(result);

  if (cleaned.containsKey('face_images')) {
    cleaned['face_images']?.remove('face_image_base64');
  }

  if (cleaned.containsKey('faces')) {
    cleaned.remove('faces');
  }

  if (cleaned.containsKey('face_image_path')) {
    cleaned.remove('face_image_path');
  }

  return cleaned;
}

String prettyJson(Map<String, dynamic> json) {
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(json);
}

String generateUniqueDocumentId() {
  final random = Random();
  final timestampPart = DateTime.now().millisecondsSinceEpoch.toString();

  return 'SC56${timestampPart.substring(timestampPart.length - 2)}${String.fromCharCode(65 + random.nextInt(26))}';
}

class ReportPageMulti extends StatefulWidget {
  final List<Map<String, dynamic>> results;
  final String? documentType; // Add document type parameter
  const ReportPageMulti({super.key, required this.results, this.documentType});

  @override
  State<ReportPageMulti> createState() => _ReportPageMultiState();
}

class _ReportPageMultiState extends State<ReportPageMulti>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

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

  Future<void> _generatePdf(BuildContext context) async {
    // Load your logo image (must be in your assets)
    final logoImage = await imageFromAssetBundle(
      'assets/images/kSCan_logo(transperent).png',
    );
    final pdf = pw.Document();

    final result = widget.results[0];
    final comparisonResult =
        result["comparison_result"] as Map<String, dynamic>? ?? {};
    final faceComparison =
        result["face_comparison"] as Map<String, dynamic>? ?? {};
    final details = comparisonResult['details'] as Map<String, dynamic>? ?? {};
    final docID = generateUniqueDocumentId();

    // Define styles for reuse
    final headerStyle = pw.TextStyle(
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blue900,
    );

    final titleStyle = pw.TextStyle(
      fontSize: 16,
      fontWeight: pw.FontWeight.bold,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40), // Add margin for border effect
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Watermark (behind everything)
              pw.Positioned.fill(
                child: pw.Opacity(
                  opacity: 0.1, // Adjust transparency (0.0 to 1.0)
                  child: pw.Center(
                    child: pw.Transform.rotateBox(
                      angle: 0,
                      child: pw.Image(logoImage, width: 400, height: 400),
                    ),
                  ),
                ),
              ),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue800, width: 1.5),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Padding(
                  padding: pw.EdgeInsets.all(20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Header with logo
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'DOCUMENT REPORT ANALYSIS',
                            style: headerStyle,
                          ),
                          pw.Column(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.SizedBox(
                                width: 80,
                                height: 80,
                                child: pw.Image(logoImage),
                              ),
                              pw.Text(
                                'ID: $docID',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.grey600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 20),

                      // Document verification section
                      pw.Text('Verification Results', style: titleStyle),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Verdict: ${comparisonResult['verdict'] ?? 'N/A'}',
                      ),
                      pw.Text(
                        'Overall Similarity: ${comparisonResult['similarity_score']?.toStringAsFixed(2) ?? 'N/A'}%',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),

                      // Face verification section
                      pw.Text('Face Verification', style: titleStyle),
                      pw.Text(
                        'Result: ${faceComparison['photoMatch']?.toString().toUpperCase() ?? 'N/A'}',
                      ),
                      if (faceComparison['faceSimilarity'] != null)
                        pw.Text(
                          'Similarity: ${faceComparison['faceSimilarity'].toStringAsFixed(2)}%',
                        ),
                      pw.SizedBox(height: 20),

                      // Details section
                      ...details.entries.map((entry) {
                        final info = entry.value as Map<String, dynamic>? ?? {};
                        final profile =
                            info['profile_value']?.toString().trim() ?? '';
                        final document =
                            info['extracted_value']?.toString().trim() ?? '';
                        if (profile.isEmpty && document.isEmpty) {
                          return pw.SizedBox.shrink();
                        }
                        final similarity =
                            info['similarity']?.toString() ?? '0';
                        final match = info['match'] == true;
                        return pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              entry.key.capitalize,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text('Profile: $profile'),
                            pw.Text('Document: $document'),
                            pw.Text(
                              'Match: ${match ? 'Yes' : 'No'} ($similarity%)',
                            ),
                            pw.Divider(),
                          ],
                        );
                      }).toList(),

                      // Footer
                      pw.Spacer(),
                      pw.Divider(),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())} © kSCan',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                          pw.Text(
                            'Page ${context.pageNumber}/${context.pagesCount}',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  Widget _buildReportTab() {
    final result = widget.results[0];
    final comparisonResult =
        result["comparison_result"] as Map<String, dynamic>? ?? {};
    final details = comparisonResult["details"] as Map<String, dynamic>? ?? {};
    final faceComparison =
        result["face_comparison"] as Map<String, dynamic>? ?? {};
    final faceImages = result["face_images"] as Map<String, dynamic>? ?? {};
    final docNumberValidation = result['validation'];

    // Get document type from results or widget parameter
    final docType =
        comparisonResult['document_type'] ?? widget.documentType ?? 'Document';
    final docTypeTitle = docType.toString().toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black, // Background fill
              borderRadius: BorderRadius.circular(12), // Rounded corners
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                '$docTypeTitle VERIFICATION REPORT',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildDocumentTypeBadge(docType),
          const SizedBox(height: 16),
          _buildVerificationSummary(comparisonResult),
          const SizedBox(height: 16),
          _buildFaceComparisonSection(faceComparison, faceImages),
          const SizedBox(height: 16),
          if (docNumberValidation != null)
            _buildDocumentNumberValidationCard(docNumberValidation),
          const SizedBox(height: 16),
          _buildDetailedComparisonSection(details, docType),
        ],
      ),
    );
  }

  Widget _buildDocumentTypeBadge(String docType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue),
      ),
      child: Center(
        child: Text(
          docType,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationSummary(Map<String, dynamic> comparisonResult) {
    final verdict = comparisonResult['verdict'] ?? 'N/A';
    final score =
        comparisonResult['similarity_score']?.toStringAsFixed(2) ?? 'N/A';
    final matched = comparisonResult['matched_fields'] ?? 0;
    final total = comparisonResult['total_fields'] ?? 0;
    final date = DateFormat('MMMM dd, yyyy - hh:mm a').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getVerdictColor(verdict).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getVerdictColor(verdict)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                verdict.toLowerCase() == 'match' ||
                        verdict.toLowerCase() == 'verified' ||
                        verdict.toLowerCase() == 'success' ||
                        verdict.toLowerCase() == 'correct'
                    ? Icons.verified
                    : Icons.warning,
                color: _getVerdictColor(verdict),
              ),
              const SizedBox(width: 8),
              Text(
                'Verification Result: ${verdict.toUpperCase()}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getVerdictColor(verdict),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Overall Similarity: $score%',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Verified on: $date',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Color _getVerdictColor(String verdict) {
    switch (verdict.toLowerCase()) {
      case 'correct' || 'match' || 'success' || 'verified':
        return Colors.green;
      case 'incorrect' || 'no match' || 'failed' || 'unverified':
        return Colors.red;
      case 'partial' || 'incomplete':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDetailedComparisonSection(
    Map<String, dynamic> details,
    String docType,
  ) {
    final importantFields = _getImportantFieldsForDocType(docType);

    return Container(
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
          ..._buildComparisonRows(details, importantFields),
        ],
      ),
    );
  }

  List<String> _getImportantFieldsForDocType(String docType) {
    switch (docType.toLowerCase()) {
      case 'aadhaar':
        return [
          'name',
          'Father\'s Name',
          'date_of_birth',
          'aadhaar_number',
          'address',
          'Phone Number',
        ];
      case 'passport':
        return ['name', 'passport_number', 'date_of_birth', 'nationality'];
      case 'bonafide':
        return ['name', 'university', 'college', 'course', 'year'];
      default:
        return [];
    }
  }

  List<Widget> _buildComparisonRows(
    Map<String, dynamic> details,
    List<String> importantFields,
  ) {
    final rows = <Widget>[];

    // Add important fields first
    for (final field in importantFields) {
      if (details.containsKey(field)) {
        rows.add(_buildComparisonRow(field, details[field]));
        rows.add(const SizedBox(height: 8));
      }
    }

    // Add other fields
    for (final entry in details.entries) {
      if (!importantFields.contains(entry.key)) {
        rows.add(_buildComparisonRow(entry.key, entry.value));
        rows.add(const SizedBox(height: 8));
      }
    }

    return rows;
  }

  List<Widget> _buildDetailedComparison(Map<String, dynamic> details) {
    return details.entries
        .where((entry) {
          final info = entry.value as Map<String, dynamic>? ?? {};
          final profile = info['profile_value']?.toString().trim() ?? '';
          final document = info['extracted_value']?.toString().trim() ?? '';
          return profile.isNotEmpty && document.isNotEmpty;
        })
        .map((entry) => _buildComparisonRow(entry.key, entry.value))
        .toList();
  }

  Widget _buildComparisonRow(String field, dynamic info) {
    final infoMap = info as Map<String, dynamic>? ?? {};
    final profileValue = infoMap['profile_value'] ?? 'N/A';
    final documentValue = infoMap['extracted_value'] ?? 'N/A';
    final similarity = infoMap['similarity']?.toString() ?? '0';
    final match = infoMap['match'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.capitalize,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('Profile Value: $profileValue'),
          Text('Document Value: $documentValue'),
          Row(
            children: [
              const Text('Match: '),
              Icon(
                match ? Icons.check_circle : Icons.cancel,
                color: match ? Colors.green : Colors.red,
              ),
              Text(' ($similarity%)'),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildFaceComparisonSection(
    Map<String, dynamic> faceComparison,
    Map<String, dynamic> faceImages,
  ) {
    return Container(
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
                faceComparison['photoMatch']?.toString().toUpperCase() ?? 'N/A',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getMatchColor(faceComparison['photoMatch']),
                ),
              ),
            ],
          ),
          if (faceComparison['faceSimilarity'] != null)
            Text(
              'Similarity: ${faceComparison['faceSimilarity'].toStringAsFixed(2)}%',
            ),
          const SizedBox(height: 16),
          if (faceImages['uploaded_face'] != null)
            _buildFaceImageWithLabel(
              image: faceImages['uploaded_face'],
              label: 'Supporting Face',
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentNumberValidationCard(dynamic validationResult) {
    dynamic statusRaw = validationResult?['status'];
    String status;
    if (statusRaw is int) {
      // Map int to string
      status = statusRaw == 1 ? 'valid' : 'invalid';
    } else {
      status = statusRaw?.toString() ?? 'Unknown';
    }
    String message = validationResult?['message']?.toString() ?? '';
    Color color;
    switch (status.toLowerCase()) {
      case 'valid':
        color = Colors.green;
        break;
      case 'invalid':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Card(
      color: color.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(
          status.toLowerCase() == 'valid' ? Icons.check_circle : Icons.error,
          color: color,
        ),
        title: Text(
          'Document Number Validation',
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        subtitle: Text(
          message.isNotEmpty ? message : 'Status: $status',
          style: TextStyle(color: color),
        ),
      ),
    );
  }

  Color _getMatchColor(dynamic match) {
    final value = match?.toString().toLowerCase();
    if (value == 'true' ||
        value == 'match' ||
        value == 'yes' ||
        value == 'success') {
      return Colors.green;
    } else if (value == 'false' ||
        value == 'no match' ||
        value == 'no' ||
        value == 'failed') {
      return Colors.red;
    }
    return Colors.grey;
  }

  Widget _buildFaceImageWithLabel({
    required dynamic image,
    required String label,
  }) {
    return Column(
      children: [
        Text(label),
        const SizedBox(height: 8),
        _buildFaceImage(image),
      ],
    );
  }

  Widget _buildFaceImage(dynamic imageData) {
    if (imageData == null) return _buildPlaceholderImage();

    try {
      if (imageData is String) {
        if (imageData.startsWith('data:image')) {
          final base64Str = imageData.split(',')[1];
          return Image.memory(
            base64Decode(base64Str),
            width: 150,
            height: 150,
            fit: BoxFit.cover,
          );
        } else if (imageData.startsWith('http')) {
          return Image.network(
            imageData,
            width: 150,
            height: 150,
            fit: BoxFit.cover,
          );
        } else if (!kIsWeb) {
          final file = File(imageData);
          if (file.existsSync()) {
            return Image.file(file, width: 150, height: 150, fit: BoxFit.cover);
          }
        }
      } else if (imageData is Uint8List) {
        return Image.memory(
          imageData,
          width: 150,
          height: 150,
          fit: BoxFit.cover,
        );
      }
    } catch (_) {}

    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 150,
      height: 150,
      color: Colors.grey[300],
      child: const Icon(Icons.error, size: 50, color: Colors.grey),
    );
  }

  Widget _buildRawDataTab() {
    final result = widget.results[0];
    print('Raw Result: $result');
    final extractedData =
        result["extracted_data"] as Map<String, dynamic>? ?? {};
    final personalDetails =
        extractedData["personal_details"] as Map<String, dynamic>? ?? {};

    // Maintain visual ordering
    final orderedKeys = [
      "Personal Information",
      "Contact Information",
      "Educational Details",
      "Document Identifiers",
      "Employment/Income Details",
      "Additional Information",
    ];

    final orderedPersonalDetails = {
      for (var key in orderedKeys)
        if (personalDetails.containsKey(key)) key: personalDetails[key],
    };

    final formattedJson = prettyJson(orderedPersonalDetails);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        formattedJson,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.results.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Result'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.article, size: 20, color: Colors.black),
                  SizedBox(width: 8),
                  Text(
                    "Report",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.document_scanner, size: 20, color: Colors.black),
                  SizedBox(width: 8),
                  Text(
                    "Document Data",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.blue.withOpacity(0.2),
          ),
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.white,
          indicatorSize: TabBarIndicatorSize.tab,
        ),
        actions: [
          if (_tabController.index == 0)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () => _generatePdf(context),
              tooltip: 'Generate PDF',
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildReportTab(), _buildRawDataTab()],
      ),
    );
  }
}
