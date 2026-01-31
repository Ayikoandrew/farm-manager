import 'dart:js_interop';
import 'package:web/web.dart' as web;

bool get isOnline => web.window.navigator.onLine;

void onOnline(void Function() callback) {
  web.window.addEventListener(
    'online',
    (web.Event event) {
      callback();
    }.toJS,
  );
}

void onOffline(void Function() callback) {
  web.window.addEventListener(
    'offline',
    (web.Event event) {
      callback();
    }.toJS,
  );
}
