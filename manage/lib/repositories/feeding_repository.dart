import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/feeding_record.dart';
import '../config/supabase_config.dart';

class FeedingRepository {
  final SupabaseClient _client;
  static const String _table = 'feeding_records';

  FeedingRepository({SupabaseClient? client})
    : _client = client ?? SupabaseConfig.client;

  /// Watch all feeding records for a farm
  Stream<List<FeedingRecord>> watchFeedingRecords(String farmId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('farm_id', farmId)
        .order('date', ascending: false)
        .map(
          (data) =>
              data.map((json) => FeedingRecord.fromSupabase(json)).toList(),
        );
  }

  /// Get animal feed by tag ID
  Future<FeedingRecord?> getAnimalFeedByTagId(
    String farmId,
    String tagId,
  ) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('farm_id', farmId)
        .eq('tag_id', tagId)
        .maybeSingle();
    if (response == null) return null;
    return FeedingRecord.fromSupabase(response);
  }

  /// Get feeding records with pagination
  Future<List<FeedingRecord>> getFeedingRecordsPaginated(
    String farmId, {
    required int limit,
    required int offset,
  }) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('farm_id', farmId)
        .order('date', ascending: false)
        .range(offset, offset + limit - 1);
    return (response as List)
        .map((json) => FeedingRecord.fromSupabase(json))
        .toList();
  }

  /// Watch feeding records for a specific animal
  Stream<List<FeedingRecord>> watchFeedingRecordsForAnimal(String animalId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('animal_id', animalId)
        .order('date', ascending: false)
        .map(
          (data) =>
              data.map((json) => FeedingRecord.fromSupabase(json)).toList(),
        );
  }

  /// Get feeding records for a specific animal with pagination
  Future<List<FeedingRecord>> getFeedingRecordsForAnimalPaginated(
    String animalId, {
    required int limit,
    required int offset,
  }) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('animal_id', animalId)
        .order('date', ascending: false)
        .range(offset, offset + limit - 1);
    return (response as List)
        .map((json) => FeedingRecord.fromSupabase(json))
        .toList();
  }

  /// Get feeding records for a date range
  Future<List<FeedingRecord>> getFeedingRecordsForDateRange(
    String farmId,
    DateTime start,
    DateTime end,
  ) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('farm_id', farmId)
        .gte('date', start.toIso8601String())
        .lte('date', end.toIso8601String())
        .order('date', ascending: false);
    return (response as List)
        .map((json) => FeedingRecord.fromSupabase(json))
        .toList();
  }

  /// Add a new feeding record
  Future<String> addFeedingRecord(FeedingRecord record) async {
    final response = await _client
        .from(_table)
        .insert(record.toSupabase())
        .select('id')
        .single();
    return response['id'] as String;
  }

  /// Update a feeding record
  Future<void> updateFeedingRecord(FeedingRecord record) async {
    await _client.from(_table).update(record.toSupabase()).eq('id', record.id);
  }

  /// Delete a feeding record
  Future<void> deleteFeedingRecord(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  /// Get total feed for an animal
  Future<double> getTotalFeedForAnimal(String animalId) async {
    final response = await _client
        .from(_table)
        .select('quantity')
        .eq('animal_id', animalId);
    return (response as List).fold<double>(
      0,
      (total, json) => total + ((json['quantity'] ?? 0) as num).toDouble(),
    );
  }

  /// Get total feed for a date
  Future<double> getTotalFeedForDate(String farmId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final response = await _client
        .from(_table)
        .select('quantity')
        .eq('farm_id', farmId)
        .gte('date', startOfDay.toIso8601String())
        .lt('date', endOfDay.toIso8601String());

    return (response as List).fold<double>(
      0,
      (total, json) => total + ((json['quantity'] ?? 0) as num).toDouble(),
    );
  }
}
