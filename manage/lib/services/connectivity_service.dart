import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/env_helper.dart';

import 'connectivity_web.dart'
    if (dart.library.io) 'connectivity_stub.dart'
    as platform;

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final _connectionStatusController = StreamController<bool>.broadcast();

  Stream<bool> get connectionStream => _connectionStatusController.stream;
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    _isConnected = await checkConnection();
    _connectionStatusController.add(_isConnected);

    if (kIsWeb) {
      // For web, listen to online/offline events
      platform.onOnline(() {
        _isConnected = true;
        _connectionStatusController.add(_isConnected);
      });
      platform.onOffline(() {
        _isConnected = false;
        _connectionStatusController.add(_isConnected);
      });
    } else {
      // For mobile/desktop, use the connectivity plugin
      _connectivity.onConnectivityChanged.listen((result) async {
        _isConnected = await checkConnection();
        _connectionStatusController.add(_isConnected);
      });
    }
  }

  Future<bool> checkConnection() async {
    // On web, use navigator.onLine (no CORS issues)
    if (kIsWeb) {
      return platform.isOnline;
    }

    // On mobile/desktop, use connectivity_plus
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }
    } catch (e) {
      debugPrint('Connectivity plugin error: $e');
    }

    // Verify actual internet access with HTTP request to Supabase (has CORS configured)
    try {
      final supabaseUrl = EnvHelper.get('SUPABASE_URL');
      if (supabaseUrl != null) {
        final response = await http
            .get(Uri.parse('$supabaseUrl/rest/v1/'))
            .timeout(const Duration(seconds: 5));
        // Supabase returns various status codes, but if we get a response, we're connected
        return response.statusCode < 500;
      }
    } catch (e) {
      debugPrint('Supabase connectivity check failed: $e');
      return false;
    }

    return true;
  }

  void dispose() {
    _connectionStatusController.close();
  }
}
