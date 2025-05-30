import 'dart:html' as html;
import 'dart:typed_data';

void downloadZip(Uint8List zipBytes, String fileName) {
  final blob = html.Blob([zipBytes], 'application/zip');
  final downloadUrl = html.Url.createObjectUrlFromBlob(blob);

  // ignore: unused_local_variable
  final anchor =
      html.AnchorElement(href: downloadUrl)
        ..setAttribute("download", fileName)
        ..click();

  html.Url.revokeObjectUrl(downloadUrl);
}
