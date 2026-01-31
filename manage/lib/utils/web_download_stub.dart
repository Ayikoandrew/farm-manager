import 'dart:typed_data';

void downloadOnWeb(Uint8List bytes, String filename, String mimeType) {
  throw UnsupportedError('downloadOnWeb is only supported on web platform');
}

void downloadTextOnWeb(String content, String filename, String mimeType) {
  throw UnsupportedError('downloadTextOnWeb is only supported on web platform');
}
