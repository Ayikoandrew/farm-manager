import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/animal.dart';
import '../models/weight_record.dart';
import '../models/breeding_record.dart';
import '../config/supabase_config.dart';

class AnimalRepository {
  final SupabaseClient _client;
  static const String _table = 'animals';
  static const String _weightTable = 'weight_records';
  static const String _breedingTable = 'breeding_records';

  AnimalRepository({SupabaseClient? client})
    : _client = client ?? SupabaseConfig.client;

  /// Watch animals for a farm with real-time updates
  Stream<List<Animal>> watchAnimals(String farmId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('farm_id', farmId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Animal.fromSupabase(json)).toList());
  }

  /// Get all animals for a farm
  Future<List<Animal>> getAnimals(String farmId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('farm_id', farmId)
        .order('created_at', ascending: false);
    return (response as List).map((json) => Animal.fromSupabase(json)).toList();
  }

  /// Get animals for a farm with pagination
  Future<List<Animal>> getAnimalsPaginated(
    String farmId, {
    required int limit,
    required int offset,
  }) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('farm_id', farmId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (response as List).map((json) => Animal.fromSupabase(json)).toList();
  }

  /// Get a single animal by ID
  Future<Animal?> getAnimal(String id) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return Animal.fromSupabase(response);
  }

  /// Watch a single animal by ID with real-time updates
  Stream<Animal?> watchAnimalById(String id) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((data) => data.isEmpty ? null : Animal.fromSupabase(data.first));
  }

  /// Get animal by tag ID
  Future<Animal?> getAnimalByTagId(String farmId, String tagId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('farm_id', farmId)
        .eq('tag_id', tagId)
        .maybeSingle();
    if (response == null) return null;
    return Animal.fromSupabase(response);
  }

  /// Add a new animal
  /// Also creates a weight record if currentWeight is provided
  /// Also creates a breeding record if status is pregnant
  Future<String> addAnimal(Animal animal) async {
    try {
      final data = animal.toSupabase();
      // print('DEBUG: Adding animal with data: $data');
      // print('DEBUG: farm_id = ${data['farm_id']}');

      // Check if user can access this farm
      final userId = _client.auth.currentUser?.id;
      // print('DEBUG: Current user ID = $userId');

      // Check farm ownership
      final farm = await _client
          .from('farms')
          .select('id, owner_id, name')
          .eq('id', data['farm_id'])
          .maybeSingle();
      if (kDebugMode) {
        print('DEBUG: Farm data = $farm');
      }

      // Check user's active_farm_id
      final user = await _client
          .from('users')
          .select('active_farm_id, farms')
          .eq('id', userId!)
          .maybeSingle();
      if (kDebugMode) {
        print('DEBUG: User data = $user');
      }

      final response = await _client
          .from(_table)
          .insert(data)
          .select('id')
          .single();

      final animalId = response['id'] as String;
      if (kDebugMode) {
        print('DEBUG: Animal added successfully with id = $animalId');
      }

      // Auto-create weight record if weight is provided
      if (animal.currentWeight != null && animal.currentWeight! > 0) {
        try {
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
          await _client.from(_weightTable).insert(weightRecord.toSupabase());
          if (kDebugMode) {
            print(
              'DEBUG: Weight record created for animal $animalId with weight ${animal.currentWeight}',
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print('DEBUG: Failed to create weight record: $e');
          }
          // Don't fail the whole operation if weight record fails
        }
      }

      // Auto-create breeding record if status is pregnant
      if (animal.status == AnimalStatus.pregnant) {
        try {
          final now = DateTime.now();
          // Estimate breeding happened about 60 days ago (mid-pregnancy)
          final estimatedBreedingDate = now.subtract(const Duration(days: 60));
          final gestationDays = GestationPeriods.forSpecies(animal.species);
          final expectedDeliveryDate = estimatedBreedingDate.add(
            Duration(days: gestationDays),
          );

          final breedingRecord = BreedingRecord(
            id: '',
            farmId: animal.farmId,
            animalId: animalId,
            heatDate: estimatedBreedingDate.subtract(
              const Duration(days: 3),
            ), // Estimate heat date
            breedingDate: estimatedBreedingDate,
            expectedDeliveryDate: expectedDeliveryDate,
            status: BreedingStatus.pregnant,
            notes: 'Auto-created when animal was added with pregnant status',
            createdAt: now,
            updatedAt: now,
          );
          await _client
              .from(_breedingTable)
              .insert(breedingRecord.toSupabase());
          if (kDebugMode) {
            print(
              'DEBUG: Breeding record created for pregnant animal $animalId',
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print('DEBUG: Failed to create breeding record: $e');
          }
          // Don't fail the whole operation if breeding record fails
        }
      }

      return animalId;
    } catch (e, stack) {
      if (kDebugMode) {
        print('DEBUG ERROR: Failed to add animal: $e');
      }
      if (kDebugMode) {
        print('DEBUG STACK: $stack');
      }
      rethrow;
    }
  }

  /// Update an existing animal
  /// Also creates a weight record if weight changed
  /// Also creates a breeding record if status changed to pregnant
  Future<void> updateAnimal(Animal animal, {Animal? previousAnimal}) async {
    await _client.from(_table).update(animal.toSupabase()).eq('id', animal.id);

    // If we have the previous animal state, we can track changes
    if (previousAnimal != null) {
      final now = DateTime.now();

      // Auto-create weight record if weight changed
      if (animal.currentWeight != null &&
          animal.currentWeight! > 0 &&
          animal.currentWeight != previousAnimal.currentWeight) {
        try {
          final weightRecord = WeightRecord(
            id: '',
            farmId: animal.farmId,
            animalId: animal.id,
            date: now,
            weight: animal.currentWeight!,
            notes: 'Weight updated',
            createdAt: now,
          );
          await _client.from(_weightTable).insert(weightRecord.toSupabase());
          if (kDebugMode) {
            print(
              'DEBUG: Weight record created for animal ${animal.id} with new weight ${animal.currentWeight}',
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print('DEBUG: Failed to create weight record on update: $e');
          }
        }
      }

      // Auto-create breeding record if status changed to pregnant
      if (animal.status == AnimalStatus.pregnant &&
          previousAnimal.status != AnimalStatus.pregnant) {
        try {
          // Assume breeding just happened
          final breedingDate = now;
          final gestationDays = GestationPeriods.forSpecies(animal.species);
          final expectedDeliveryDate = breedingDate.add(
            Duration(days: gestationDays),
          );

          final breedingRecord = BreedingRecord(
            id: '',
            farmId: animal.farmId,
            animalId: animal.id,
            heatDate: now.subtract(const Duration(days: 3)),
            breedingDate: breedingDate,
            expectedDeliveryDate: expectedDeliveryDate,
            status: BreedingStatus.pregnant,
            notes: 'Auto-created when animal status changed to pregnant',
            createdAt: now,
            updatedAt: now,
          );
          await _client
              .from(_breedingTable)
              .insert(breedingRecord.toSupabase());
          if (kDebugMode) {
            print(
              'DEBUG: Breeding record created for animal ${animal.id} status change to pregnant',
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print('DEBUG: Failed to create breeding record on update: $e');
          }
        }
      }
    }
  }

  /// Update animal weight
  Future<void> updateAnimalWeight(String animalId, double weight) async {
    await _client
        .from(_table)
        .update({
          'current_weight': weight,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', animalId);
  }

  /// Update animal status
  Future<void> updateAnimalStatus(String animalId, AnimalStatus status) async {
    await _client
        .from(_table)
        .update({
          'status': status.name,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', animalId);
  }

  /// Update animal photo URL
  Future<void> updateAnimalPhotoUrl(String animalId, String photoUrl) async {
    await _client
        .from(_table)
        .update({
          'photo_url': photoUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', animalId);
  }

  /// Delete an animal
  Future<void> deleteAnimal(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  /// Watch animals by status
  Stream<List<Animal>> watchAnimalsByStatus(
    String farmId,
    AnimalStatus status,
  ) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('farm_id', farmId)
        .map(
          (data) => data
              .where((json) => json['status'] == status.name)
              .map((json) => Animal.fromSupabase(json))
              .toList(),
        );
  }

  /// Watch female animals
  Stream<List<Animal>> watchFemaleAnimals(String farmId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('farm_id', farmId)
        .order('created_at', ascending: false)
        .map(
          (data) => data
              .where((json) => json['gender'] == Gender.female.name)
              .map((json) => Animal.fromSupabase(json))
              .toList(),
        );
  }

  /// Watch male animals
  Stream<List<Animal>> watchMaleAnimals(String farmId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('farm_id', farmId)
        .order('created_at', ascending: false)
        .map(
          (data) => data
              .where((json) => json['gender'] == Gender.male.name)
              .map((json) => Animal.fromSupabase(json))
              .toList(),
        );
  }

  /// Get offspring for an animal (animals where this animal is mother or father)
  Future<List<Animal>> getOffspring(String animalId) async {
    final response = await _client
        .from(_table)
        .select()
        .or('mother_id.eq.$animalId,father_id.eq.$animalId')
        .order('birth_date', ascending: false);
    return (response as List).map((json) => Animal.fromSupabase(json)).toList();
  }

  /// Watch offspring for an animal with real-time updates
  Stream<List<Animal>> watchOffspring(String animalId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .map(
          (data) => data
              .where(
                (json) =>
                    json['mother_id'] == animalId ||
                    json['father_id'] == animalId,
              )
              .map((json) => Animal.fromSupabase(json))
              .toList(),
        );
  }
}
