import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveAndShareFile(
  Uint8List bytes,
  String filename,
  String mimeType,
) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$filename');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles([
    XFile(file.path, mimeType: mimeType),
  ], subject: filename);
}

Future<void> saveAndShareTextFile(
  String content,
  String filename,
  String mimeType,
) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$filename');
  await file.writeAsString(content);
  await Share.shareXFiles([
    XFile(file.path, mimeType: mimeType),
  ], subject: filename);
}
