/// Mock Supabase client and related classes for testing
/// This file provides mock implementations for Supabase services

import 'dart:async';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mock SupabaseClient for testing
class MockSupabaseClient extends Mock implements SupabaseClient {}

/// Mock GoTrueClient (Auth) for testing
class MockGoTrueClient extends Mock implements GoTrueClient {}

/// Mock SupabaseQueryBuilder for testing
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

/// Mock PostgrestFilterBuilder for testing
class MockPostgrestFilterBuilder<T> extends Mock
    implements PostgrestFilterBuilder<T> {}

/// Mock PostgrestTransformBuilder for testing
class MockPostgrestTransformBuilder<T> extends Mock
    implements PostgrestTransformBuilder<T> {}

/// Mock data storage that simulates Supabase tables
class MockSupabaseDatabase {
  final Map<String, List<Map<String, dynamic>>> _tables = {};
  final Map<String, StreamController<List<Map<String, dynamic>>>>
  _streamControllers = {};
  int _idCounter = 0; // Counter for unique IDs

  /// Get or create a table
  List<Map<String, dynamic>> _getTable(String table) {
    return _tables.putIfAbsent(table, () => []);
  }

  /// Get stream controller for a table
  StreamController<List<Map<String, dynamic>>> _getStreamController(
    String table,
  ) {
    return _streamControllers.putIfAbsent(
      table,
      () => StreamController<List<Map<String, dynamic>>>.broadcast(),
    );
  }

  /// Notify listeners of table changes
  void _notifyListeners(String table) {
    final controller = _streamControllers[table];
    if (controller != null && !controller.isClosed) {
      controller.add(List.from(_getTable(table)));
    }
  }

  /// Insert data into a table
  Map<String, dynamic> insert(String table, Map<String, dynamic> data) {
    final tableData = _getTable(table);
    final newData = Map<String, dynamic>.from(data);

    // Auto-generate ID if not provided (use counter for uniqueness)
    if (!newData.containsKey('id') || newData['id'] == null) {
      _idCounter++;
      newData['id'] =
          'mock-${DateTime.now().millisecondsSinceEpoch}-$_idCounter';
    }

    // Add timestamps
    newData['created_at'] ??= DateTime.now().toIso8601String();
    newData['updated_at'] ??= DateTime.now().toIso8601String();

    tableData.add(newData);
    _notifyListeners(table);
    return newData;
  }

  /// Select data from a table
  List<Map<String, dynamic>> select(
    String table, {
    Map<String, dynamic>? where,
  }) {
    final tableData = _getTable(table);

    if (where == null || where.isEmpty) {
      return List.from(tableData);
    }

    return tableData.where((row) {
      return where.entries.every((entry) => row[entry.key] == entry.value);
    }).toList();
  }

  /// Select single row from a table
  Map<String, dynamic>? selectSingle(
    String table, {
    required Map<String, dynamic> where,
  }) {
    final results = select(table, where: where);
    return results.isNotEmpty ? results.first : null;
  }

  /// Update data in a table
  List<Map<String, dynamic>> update(
    String table,
    Map<String, dynamic> data, {
    required Map<String, dynamic> where,
  }) {
    final tableData = _getTable(table);
    final updated = <Map<String, dynamic>>[];

    for (var i = 0; i < tableData.length; i++) {
      final row = tableData[i];
      final matches = where.entries.every(
        (entry) => row[entry.key] == entry.value,
      );

      if (matches) {
        tableData[i] = {
          ...row,
          ...data,
          'updated_at': DateTime.now().toIso8601String(),
        };
        updated.add(tableData[i]);
      }
    }

    if (updated.isNotEmpty) {
      _notifyListeners(table);
    }

    return updated;
  }

  /// Delete data from a table
  List<Map<String, dynamic>> delete(
    String table, {
    required Map<String, dynamic> where,
  }) {
    final tableData = _getTable(table);
    final deleted = <Map<String, dynamic>>[];

    tableData.removeWhere((row) {
      final matches = where.entries.every(
        (entry) => row[entry.key] == entry.value,
      );
      if (matches) deleted.add(row);
      return matches;
    });

    if (deleted.isNotEmpty) {
      _notifyListeners(table);
    }

    return deleted;
  }

  /// Get a stream of data from a table
  Stream<List<Map<String, dynamic>>> stream(
    String table, {
    Map<String, dynamic>? where,
  }) {
    final controller = _getStreamController(table);

    // Emit current data immediately
    Future.microtask(() {
      if (!controller.isClosed) {
        final data = select(table, where: where);
        controller.add(data);
      }
    });

    // Return filtered stream if where clause provided
    if (where != null && where.isNotEmpty) {
      return controller.stream.map((data) {
        return data.where((row) {
          return where.entries.every((entry) => row[entry.key] == entry.value);
        }).toList();
      });
    }

    return controller.stream;
  }

  /// Clear all data (useful for test setup)
  void clear() {
    _tables.clear();
  }

  /// Clear a specific table
  void clearTable(String table) {
    _tables[table]?.clear();
    _notifyListeners(table);
  }

  /// Dispose all stream controllers
  void dispose() {
    for (final controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();
    _tables.clear();
  }
}

/// Mock user for authentication tests
class MockUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final Map<String, dynamic>? userMetadata;
  final DateTime createdAt;

  MockUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.userMetadata,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'user_metadata': {'display_name': displayName, ...?userMetadata},
    'created_at': createdAt.toIso8601String(),
  };
}

/// Mock authentication service
class MockAuthService {
  MockUser? _currentUser;
  final _authStateController = StreamController<MockUser?>.broadcast();

  MockUser? get currentUser => _currentUser;
  Stream<MockUser?> get authStateChanges => _authStateController.stream;

  Future<MockUser> signIn({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 50));

    _currentUser = MockUser(id: 'user-${email.hashCode}', email: email);
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  Future<MockUser> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));

    _currentUser = MockUser(
      id: 'user-${email.hashCode}',
      email: email,
      displayName: displayName,
    );
    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 50));
    _currentUser = null;
    _authStateController.add(null);
  }

  void setUser(MockUser? user) {
    _currentUser = user;
    _authStateController.add(user);
  }

  void dispose() {
    _authStateController.close();
  }
}
