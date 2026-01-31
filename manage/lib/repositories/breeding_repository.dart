import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/animal.dart';
import '../models/breeding_record.dart';
import '../config/supabase_config.dart';

class BreedingRepository {
  final SupabaseClient _client;
  static const String _table = 'breeding_records';

  BreedingRepository({SupabaseClient? client})
    : _client = client ?? SupabaseConfig.client;

  /// Watch all breeding records for a farm
  Stream<List<BreedingRecord>> watchBreedingRecords(String farmId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('farm_id', farmId)
        .order('heat_date', ascending: false)
        .map(
          (data) =>
              data.map((json) => BreedingRecord.fromSupabase(json)).toList(),
        );
  }

  /// Watch breeding records for a specific animal
  Stream<List<BreedingRecord>> watchBreedingRecordsForAnimal(String animalId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('animal_id', animalId)
        .order('heat_date', ascending: false)
        .map(
          (data) =>
              data.map((json) => BreedingRecord.fromSupabase(json)).toList(),
        );
  }

  /// Get breeding records for a specific animal with pagination
  Future<List<BreedingRecord>> getBreedingRecordsForAnimalPaginated(
    String animalId, {
    required int limit,
    required int offset,
  }) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('animal_id', animalId)
        .order('heat_date', ascending: false)
        .range(offset, offset + limit - 1);
    return (response as List)
        .map((json) => BreedingRecord.fromSupabase(json))
        .toList();
  }

  /// Watch pregnant animals
  Stream<List<BreedingRecord>> watchPregnantAnimals(String farmId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('farm_id', farmId)
        .order('expected_farrow_date')
        .map(
          (data) => data
              .where((json) => json['status'] == BreedingStatus.pregnant.name)
              .map((json) => BreedingRecord.fromSupabase(json))
              .toList(),
        );
  }

  /// Watch animals in heat
  Stream<List<BreedingRecord>> watchAnimalsInHeat(String farmId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('farm_id', farmId)
        .order('heat_date', ascending: false)
        .map(
          (data) => data
              .where((json) => json['status'] == BreedingStatus.inHeat.name)
              .map((json) => BreedingRecord.fromSupabase(json))
              .toList(),
        );
  }

  /// Add a new breeding record
  Future<String> addBreedingRecord(BreedingRecord record) async {
    final response = await _client
        .from(_table)
        .insert(record.toSupabase())
        .select('id')
        .single();
    return response['id'] as String;
  }

  /// Update a breeding record
  Future<void> updateBreedingRecord(BreedingRecord record) async {
    await _client.from(_table).update(record.toSupabase()).eq('id', record.id);
  }

  /// Delete a breeding record
  Future<void> deleteBreedingRecord(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  /// Mark as bred - requires species to calculate expected delivery date
  Future<void> markAsBred(
    String recordId,
    DateTime breedingDate,
    String? sireId, {
    AnimalType species = AnimalType.pig, // Default for backward compatibility
  }) async {
    final gestationDays = GestationPeriods.forSpecies(species);
    final expectedDeliveryDate = breedingDate.add(
      Duration(days: gestationDays),
    );

    await _client
        .from(_table)
        .update({
          'status': BreedingStatus.bred.name,
          'breeding_date': breedingDate.toIso8601String(),
          'sire_id': sireId,
          'expected_farrow_date': expectedDeliveryDate.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', recordId);
  }

  /// Confirm pregnancy
  Future<void> confirmPregnancy(String recordId) async {
    await _client
        .from(_table)
        .update({
          'status': BreedingStatus.pregnant.name,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', recordId);
  }

  /// Record farrowing
  Future<void> recordFarrowing(
    String recordId,
    DateTime farrowDate,
    int litterSize,
  ) async {
    await _client
        .from(_table)
        .update({
          'status': BreedingStatus.delivered.name,
          'actual_farrow_date': farrowDate.toIso8601String(),
          'litter_size': litterSize,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', recordId);
  }

  /// Mark as failed
  Future<void> markAsFailed(String recordId) async {
    await _client
        .from(_table)
        .update({
          'status': BreedingStatus.failed.name,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', recordId);
  }

  /// Get upcoming farrowings
  Future<List<BreedingRecord>> getUpcomingFarrowings(
    String farmId,
    int withinDays,
  ) async {
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: withinDays));

    final response = await _client
        .from(_table)
        .select()
        .eq('farm_id', farmId)
        .eq('status', BreedingStatus.pregnant.name)
        .gte('expected_farrow_date', now.toIso8601String())
        .lte('expected_farrow_date', futureDate.toIso8601String())
        .order('expected_farrow_date');

    return (response as List)
        .map((json) => BreedingRecord.fromSupabase(json))
        .toList();
  }
}
