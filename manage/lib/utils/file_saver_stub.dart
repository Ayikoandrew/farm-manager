import 'dart:typed_data';

Future<void> saveAndShareFile(
  Uint8List bytes,
  String filename,
  String mimeType,
) async {
  throw UnsupportedError('saveAndShareFile is not supported on web');
}

Future<void> saveAndShareTextFile(
  String content,
  String filename,
  String mimeType,
) async {
  throw UnsupportedError('saveAndShareTextFile is not supported on web');
}
