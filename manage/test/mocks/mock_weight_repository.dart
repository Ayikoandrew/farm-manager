/// Mock WeightRepository for testing
/// Uses MockSupabaseDatabase instead of real Supabase client

import 'dart:async';
import 'package:manage/models/weight_record.dart';
import 'mock_supabase.dart';

/// A testable version of WeightRepository that uses MockSupabaseDatabase
class MockWeightRepository {
  final MockSupabaseDatabase db;
  static const String _table = 'weight_records';

  MockWeightRepository({required this.db});

  /// Watch weight records for an animal with real-time updates
  Stream<List<WeightRecord>> watchWeightRecords(String animalId) {
    return db.stream(_table, where: {'animal_id': animalId}).map((data) {
      final records = data
          .map((json) => WeightRecord.fromSupabase(json))
          .toList();
      // Sort by date descending
      records.sort((a, b) => b.date.compareTo(a.date));
      return records;
    });
  }

  /// Get all weight records for an animal
  Future<List<WeightRecord>> getWeightRecords(String animalId) async {
    final data = db.select(_table, where: {'animal_id': animalId});
    final records = data
        .map((json) => WeightRecord.fromSupabase(json))
        .toList();
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  /// Get weight records for a farm
  Future<List<WeightRecord>> getWeightRecordsForFarm(String farmId) async {
    final data = db.select(_table, where: {'farm_id': farmId});
    final records = data
        .map((json) => WeightRecord.fromSupabase(json))
        .toList();
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  /// Get a single weight record by ID
  Future<WeightRecord?> getWeightRecord(String id) async {
    final data = db.selectSingle(_table, where: {'id': id});
    if (data == null) return null;
    return WeightRecord.fromSupabase(data);
  }

  /// Get the latest weight record for an animal
  Future<WeightRecord?> getLatestWeightRecord(String animalId) async {
    final records = await getWeightRecords(animalId);
    return records.isNotEmpty ? records.first : null;
  }

  /// Add a new weight record
  Future<String> addWeightRecord(WeightRecord record) async {
    final data = record.toSupabase();
    final inserted = db.insert(_table, data);
    return inserted['id'] as String;
  }

  /// Update an existing weight record
  Future<void> updateWeightRecord(WeightRecord record) async {
    db.update(_table, record.toSupabase(), where: {'id': record.id});
  }

  /// Delete a weight record
  Future<void> deleteWeightRecord(String id) async {
    db.delete(_table, where: {'id': id});
  }

  /// Get weight records in date range
  Future<List<WeightRecord>> getWeightRecordsInRange(
    String animalId, {
    required DateTime start,
    required DateTime end,
  }) async {
    final allRecords = await getWeightRecords(animalId);
    return allRecords.where((r) {
      return r.date.isAfter(start.subtract(const Duration(days: 1))) &&
          r.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Calculate weight gain between two records
  double? calculateWeightGain(WeightRecord older, WeightRecord newer) {
    return newer.weight - older.weight;
  }

  /// Calculate average daily gain
  double? calculateAverageDailyGain(WeightRecord older, WeightRecord newer) {
    final days = newer.date.difference(older.date).inDays;
    if (days <= 0) return null;
    return (newer.weight - older.weight) / days;
  }
}
