/// Mock AnimalRepository for testing
/// Uses MockSupabaseDatabase instead of real Supabase client

import 'dart:async';
import 'package:manage/models/animal.dart';
import 'package:manage/models/weight_record.dart';
import 'package:manage/models/breeding_record.dart';
import 'mock_supabase.dart';

/// A testable version of AnimalRepository that uses MockSupabaseDatabase
class MockAnimalRepository {
  final MockSupabaseDatabase db;
  static const String _table = 'animals';
  static const String _weightTable = 'weight_records';
  static const String _breedingTable = 'breeding_records';

  // Simulate authenticated user ID
  String? currentUserId;

  MockAnimalRepository({required this.db, this.currentUserId = 'test-user-1'});

  /// Watch animals for a farm with real-time updates
  Stream<List<Animal>> watchAnimals(String farmId) {
    return db
        .stream(_table, where: {'farm_id': farmId})
        .map((data) => data.map((json) => Animal.fromSupabase(json)).toList());
  }

  /// Get all animals for a farm
  Future<List<Animal>> getAnimals(String farmId) async {
    final data = db.select(_table, where: {'farm_id': farmId});
    // Sort by created_at descending
    data.sort((a, b) {
      final aDate = DateTime.parse(a['created_at'] as String);
      final bDate = DateTime.parse(b['created_at'] as String);
      return bDate.compareTo(aDate);
    });
    return data.map((json) => Animal.fromSupabase(json)).toList();
  }

  /// Get a single animal by ID
  Future<Animal?> getAnimal(String id) async {
    final data = db.selectSingle(_table, where: {'id': id});
    if (data == null) return null;
    return Animal.fromSupabase(data);
  }

  /// Get animal by tag ID
  Future<Animal?> getAnimalByTagId(String farmId, String tagId) async {
    final data = db.selectSingle(
      _table,
      where: {'farm_id': farmId, 'tag_id': tagId},
    );
    if (data == null) return null;
    return Animal.fromSupabase(data);
  }

  /// Add a new animal
  Future<String> addAnimal(Animal animal) async {
    final data = animal.toSupabase();
    final inserted = db.insert(_table, data);
    final animalId = inserted['id'] as String;

    // Auto-create weight record if weight is provided
    if (animal.currentWeight != null && animal.currentWeight! > 0) {
      final now = DateTime.now();
      final weightRecord = WeightRecord(
        id: '',
        farmId: animal.farmId,
        animalId: animalId,
        date: now,
        weight: animal.currentWeight!,
        notes: 'Initial weight recorded when animal was added',
        createdAt: now,
      );
      db.insert(_weightTable, weightRecord.toSupabase());
    }

    // Auto-create breeding record if status is pregnant
    if (animal.status == AnimalStatus.pregnant) {
      final now = DateTime.now();
      final estimatedBreedingDate = now.subtract(const Duration(days: 60));
      final expectedFarrowDate = estimatedBreedingDate.add(
        const Duration(days: BreedingRecord.gestationDays),
      );

      final breedingRecord = BreedingRecord(
        id: '',
        farmId: animal.farmId,
        animalId: animalId,
        heatDate: estimatedBreedingDate.subtract(const Duration(days: 3)),
        breedingDate: estimatedBreedingDate,
        expectedFarrowDate: expectedFarrowDate,
        status: BreedingStatus.pregnant,
        notes: 'Auto-created breeding record for pregnant animal',
        createdAt: now,
        updatedAt: now,
      );
      db.insert(_breedingTable, breedingRecord.toSupabase());
    }

    return animalId;
  }

  /// Update an existing animal
  Future<void> updateAnimal(Animal animal) async {
    db.update(_table, animal.toSupabase(), where: {'id': animal.id});
  }

  /// Update only the weight of an animal
  Future<void> updateAnimalWeight(String animalId, double weight) async {
    db.update(
      _table,
      {
        'current_weight': weight,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: {'id': animalId},
    );
  }

  /// Update animal status
  Future<void> updateAnimalStatus(String animalId, AnimalStatus status) async {
    db.update(
      _table,
      {'status': status.name, 'updated_at': DateTime.now().toIso8601String()},
      where: {'id': animalId},
    );
  }

  /// Delete an animal
  Future<void> deleteAnimal(String id) async {
    db.delete(_table, where: {'id': id});
  }

  /// Get animals count for a farm
  Future<int> getAnimalsCount(String farmId) async {
    final data = db.select(_table, where: {'farm_id': farmId});
    return data.length;
  }

  /// Get animals by status
  Future<List<Animal>> getAnimalsByStatus(
    String farmId,
    AnimalStatus status,
  ) async {
    final allAnimals = db.select(_table, where: {'farm_id': farmId});
    return allAnimals
        .where((json) => json['status'] == status.name)
        .map((json) => Animal.fromSupabase(json))
        .toList();
  }

  /// Get animals by species
  Future<List<Animal>> getAnimalsBySpecies(
    String farmId,
    AnimalType species,
  ) async {
    final allAnimals = db.select(_table, where: {'farm_id': farmId});
    return allAnimals
        .where((json) => json['species'] == species.name)
        .map((json) => Animal.fromSupabase(json))
        .toList();
  }

  /// Search animals by tag or name
  Future<List<Animal>> searchAnimals(String farmId, String query) async {
    final allAnimals = db.select(_table, where: {'farm_id': farmId});
    final lowerQuery = query.toLowerCase();
    return allAnimals
        .where((json) {
          final tagId = (json['tag_id'] as String?)?.toLowerCase() ?? '';
          final name = (json['name'] as String?)?.toLowerCase() ?? '';
          return tagId.contains(lowerQuery) || name.contains(lowerQuery);
        })
        .map((json) => Animal.fromSupabase(json))
        .toList();
  }

  /// Get female animals for breeding selection
  Future<List<Animal>> getFemaleAnimals(String farmId) async {
    final allAnimals = db.select(_table, where: {'farm_id': farmId});
    return allAnimals
        .where((json) => json['gender'] == 'female')
        .map((json) => Animal.fromSupabase(json))
        .toList();
  }

  /// Get male animals for breeding selection
  Future<List<Animal>> getMaleAnimals(String farmId) async {
    final allAnimals = db.select(_table, where: {'farm_id': farmId});
    return allAnimals
        .where((json) => json['gender'] == 'male')
        .map((json) => Animal.fromSupabase(json))
        .toList();
  }

  /// Get statistics for a farm
  Future<Map<String, int>> getAnimalStatistics(String farmId) async {
    final allAnimals = db.select(_table, where: {'farm_id': farmId});

    final stats = <String, int>{
      'total': allAnimals.length,
      'healthy': 0,
      'sick': 0,
      'pregnant': 0,
      'nursing': 0,
      'sold': 0,
      'deceased': 0,
      'male': 0,
      'female': 0,
    };

    for (final animal in allAnimals) {
      final status = animal['status'] as String?;
      if (status != null && stats.containsKey(status)) {
        stats[status] = (stats[status] ?? 0) + 1;
      }

      final gender = animal['gender'] as String?;
      if (gender != null && stats.containsKey(gender)) {
        stats[gender] = (stats[gender] ?? 0) + 1;
      }
    }

    return stats;
  }
}
