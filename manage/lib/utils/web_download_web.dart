import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

void downloadOnWeb(Uint8List bytes, String filename, String mimeType) {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  web.URL.revokeObjectURL(url);
}

void downloadTextOnWeb(String content, String filename, String mimeType) {
  final bytes = utf8.encode(content);
  downloadOnWeb(Uint8List.fromList(bytes), filename, mimeType);
}
