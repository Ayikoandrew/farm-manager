import 'package:flutter_test/flutter_test.dart';
import 'package:manage/models/animal.dart';

import '../helpers/test_factories.dart';
import '../mocks/mock_supabase.dart';
import '../mocks/mock_animal_repository.dart';

void main() {
  late MockSupabaseDatabase mockDb;
  late MockAnimalRepository repository;

  setUp(() {
    mockDb = MockSupabaseDatabase();
    repository = MockAnimalRepository(db: mockDb);
    resetAllFactories();
  });

  tearDown(() {
    mockDb.dispose();
  });

  Animal createTestAnimal({
    String id = 'animal-1',
    String farmId = 'farm-1',
    String tagId = 'PIG-001',
    String breed = 'Large White',
    Gender gender = Gender.female,
    double currentWeight = 100.0,
    AnimalStatus status = AnimalStatus.healthy,
  }) {
    return Animal(
      id: id,
      farmId: farmId,
      tagId: tagId,
      breed: breed,
      gender: gender,
      species: AnimalType.pig,
      birthDate: DateTime(2023, 6, 1),
      currentWeight: currentWeight,
      status: status,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  group('MockAnimalRepository', () {
    group('addAnimal', () {
      test('should add an animal and return document ID', () async {
        final animal = createTestAnimal();

        final docId = await repository.addAnimal(animal);

        expect(docId, isNotEmpty);
        final retrieved = await repository.getAnimal(docId);
        expect(retrieved, isNotNull);
      });

      test('should store animal data correctly', () async {
        final animal = createTestAnimal(
          tagId: 'COW-001',
          breed: 'Holstein',
          currentWeight: 450.0,
        );

        final docId = await repository.addAnimal(animal);

        final retrieved = await repository.getAnimal(docId);
        expect(retrieved!.tagId, 'COW-001');
        expect(retrieved.breed, 'Holstein');
        expect(retrieved.currentWeight, 450.0);
      });

      test(
        'should auto-create weight record when weight is provided',
        () async {
          final animal = createTestAnimal(currentWeight: 100.0);

          await repository.addAnimal(animal);

          final weightRecords = mockDb.select('weight_records');
          expect(weightRecords.length, 1);
          expect(weightRecords.first['weight'], 100.0);
        },
      );

      test(
        'should auto-create breeding record when status is pregnant',
        () async {
          final animal = createTestAnimal(
            gender: Gender.female,
            status: AnimalStatus.pregnant,
          );

          await repository.addAnimal(animal);

          final breedingRecords = mockDb.select('breeding_records');
          expect(breedingRecords.length, 1);
          expect(breedingRecords.first['status'], 'pregnant');
        },
      );
    });

    group('getAnimal', () {
      test('should return animal when exists', () async {
        final animal = createTestAnimal();
        final docId = await repository.addAnimal(animal);

        final result = await repository.getAnimal(docId);

        expect(result, isNotNull);
        expect(result!.tagId, animal.tagId);
        expect(result.breed, animal.breed);
      });

      test('should return null when animal does not exist', () async {
        final result = await repository.getAnimal('non-existent');

        expect(result, isNull);
      });
    });

    group('getAnimalByTagId', () {
      test('should return animal when tag ID exists', () async {
        final animal = createTestAnimal(tagId: 'UNIQUE-TAG');
        await repository.addAnimal(animal);

        final result = await repository.getAnimalByTagId(
          animal.farmId,
          'UNIQUE-TAG',
        );

        expect(result, isNotNull);
        expect(result!.tagId, 'UNIQUE-TAG');
      });

      test('should return null when tag ID does not exist', () async {
        final result = await repository.getAnimalByTagId(
          'farm-1',
          'NON-EXISTENT',
        );

        expect(result, isNull);
      });

      test('should only find animal in the correct farm', () async {
        final animal = createTestAnimal(farmId: 'farm-1', tagId: 'SHARED-TAG');
        await repository.addAnimal(animal);

        final result = await repository.getAnimalByTagId(
          'farm-2',
          'SHARED-TAG',
        );

        expect(result, isNull);
      });
    });

    group('getAnimals', () {
      test('should return all animals for a farm', () async {
        await repository.addAnimal(
          createTestAnimal(id: 'a1', farmId: 'farm-1', tagId: 'PIG-001'),
        );
        await repository.addAnimal(
          createTestAnimal(id: 'a2', farmId: 'farm-1', tagId: 'PIG-002'),
        );
        await repository.addAnimal(
          createTestAnimal(id: 'a3', farmId: 'farm-2', tagId: 'PIG-003'),
        );

        final result = await repository.getAnimals('farm-1');

        expect(result.length, 2);
        expect(result.map((a) => a.tagId), containsAll(['PIG-001', 'PIG-002']));
      });

      test('should return empty list when no animals exist', () async {
        final result = await repository.getAnimals('empty-farm');

        expect(result, isEmpty);
      });
    });

    group('updateAnimal', () {
      test('should update animal data', () async {
        final animal = createTestAnimal();
        final docId = await repository.addAnimal(animal);
        final storedAnimal = await repository.getAnimal(docId);

        final updatedAnimal = storedAnimal!.copyWith(
          breed: 'Updated Breed',
          currentWeight: 150.0,
        );
        await repository.updateAnimal(updatedAnimal);

        final result = await repository.getAnimal(docId);
        expect(result!.breed, 'Updated Breed');
        expect(result.currentWeight, 150.0);
      });
    });

    group('updateAnimalWeight', () {
      test('should update only weight', () async {
        final animal = createTestAnimal(currentWeight: 100.0);
        final docId = await repository.addAnimal(animal);

        await repository.updateAnimalWeight(docId, 125.5);

        final result = await repository.getAnimal(docId);
        expect(result!.currentWeight, 125.5);
      });
    });

    group('updateAnimalStatus', () {
      test('should update animal status', () async {
        final animal = createTestAnimal(status: AnimalStatus.healthy);
        final docId = await repository.addAnimal(animal);

        await repository.updateAnimalStatus(docId, AnimalStatus.sick);

        final result = await repository.getAnimal(docId);
        expect(result!.status, AnimalStatus.sick);
      });

      test('should update from healthy to pregnant', () async {
        final animal = createTestAnimal(
          gender: Gender.female,
          status: AnimalStatus.healthy,
        );
        final docId = await repository.addAnimal(animal);

        await repository.updateAnimalStatus(docId, AnimalStatus.pregnant);

        final result = await repository.getAnimal(docId);
        expect(result!.status, AnimalStatus.pregnant);
      });
    });

    group('deleteAnimal', () {
      test('should remove animal from database', () async {
        final animal = createTestAnimal();
        final docId = await repository.addAnimal(animal);

        await repository.deleteAnimal(docId);

        final result = await repository.getAnimal(docId);
        expect(result, isNull);
      });
    });

    group('getAnimalsCount', () {
      test('should return correct count', () async {
        await repository.addAnimal(
          createTestAnimal(id: 'a1', farmId: 'farm-1'),
        );
        await repository.addAnimal(
          createTestAnimal(id: 'a2', farmId: 'farm-1'),
        );
        await repository.addAnimal(
          createTestAnimal(id: 'a3', farmId: 'farm-1'),
        );

        final count = await repository.getAnimalsCount('farm-1');

        expect(count, 3);
      });

      test('should return 0 for empty farm', () async {
        final count = await repository.getAnimalsCount('empty-farm');

        expect(count, 0);
      });
    });

    group('getAnimalsByStatus', () {
      test('should filter by status', () async {
        await repository.addAnimal(
          createTestAnimal(
            id: 'a1',
            farmId: 'farm-1',
            status: AnimalStatus.healthy,
          ),
        );
        await repository.addAnimal(
          createTestAnimal(
            id: 'a2',
            farmId: 'farm-1',
            status: AnimalStatus.sick,
          ),
        );
        await repository.addAnimal(
          createTestAnimal(
            id: 'a3',
            farmId: 'farm-1',
            status: AnimalStatus.healthy,
          ),
        );

        final healthy = await repository.getAnimalsByStatus(
          'farm-1',
          AnimalStatus.healthy,
        );
        final sick = await repository.getAnimalsByStatus(
          'farm-1',
          AnimalStatus.sick,
        );

        expect(healthy.length, 2);
        expect(sick.length, 1);
      });
    });

    group('searchAnimals', () {
      test('should find animals by tag ID', () async {
        await repository.addAnimal(
          createTestAnimal(id: 'a1', farmId: 'farm-1', tagId: 'ABC-001'),
        );
        await repository.addAnimal(
          createTestAnimal(id: 'a2', farmId: 'farm-1', tagId: 'XYZ-002'),
        );

        final results = await repository.searchAnimals('farm-1', 'ABC');

        expect(results.length, 1);
        expect(results.first.tagId, 'ABC-001');
      });

      test('should be case insensitive', () async {
        await repository.addAnimal(
          createTestAnimal(id: 'a1', farmId: 'farm-1', tagId: 'PIG-001'),
        );

        final results = await repository.searchAnimals('farm-1', 'pig');

        expect(results.length, 1);
      });
    });

    group('getFemaleAnimals', () {
      test('should return only female animals', () async {
        await repository.addAnimal(
          createTestAnimal(id: 'a1', farmId: 'farm-1', gender: Gender.female),
        );
        await repository.addAnimal(
          createTestAnimal(id: 'a2', farmId: 'farm-1', gender: Gender.male),
        );
        await repository.addAnimal(
          createTestAnimal(id: 'a3', farmId: 'farm-1', gender: Gender.female),
        );

        final females = await repository.getFemaleAnimals('farm-1');

        expect(females.length, 2);
        expect(females.every((a) => a.gender == Gender.female), isTrue);
      });
    });

    group('getMaleAnimals', () {
      test('should return only male animals', () async {
        await repository.addAnimal(
          createTestAnimal(id: 'a1', farmId: 'farm-1', gender: Gender.female),
        );
        await repository.addAnimal(
          createTestAnimal(id: 'a2', farmId: 'farm-1', gender: Gender.male),
        );
        await repository.addAnimal(
          createTestAnimal(id: 'a3', farmId: 'farm-1', gender: Gender.male),
        );

        final males = await repository.getMaleAnimals('farm-1');

        expect(males.length, 2);
        expect(males.every((a) => a.gender == Gender.male), isTrue);
      });
    });

    group('getAnimalStatistics', () {
      test('should return correct statistics', () async {
        await repository.addAnimal(
          createTestAnimal(
            id: 'a1',
            farmId: 'farm-1',
            gender: Gender.female,
            status: AnimalStatus.healthy,
          ),
        );
        await repository.addAnimal(
          createTestAnimal(
            id: 'a2',
            farmId: 'farm-1',
            gender: Gender.male,
            status: AnimalStatus.healthy,
          ),
        );
        await repository.addAnimal(
          createTestAnimal(
            id: 'a3',
            farmId: 'farm-1',
            gender: Gender.female,
            status: AnimalStatus.pregnant,
          ),
        );
        await repository.addAnimal(
          createTestAnimal(
            id: 'a4',
            farmId: 'farm-1',
            gender: Gender.female,
            status: AnimalStatus.sick,
          ),
        );

        final stats = await repository.getAnimalStatistics('farm-1');

        expect(stats['total'], 4);
        expect(stats['healthy'], 2);
        expect(stats['pregnant'], 1);
        expect(stats['sick'], 1);
        expect(stats['female'], 3);
        expect(stats['male'], 1);
      });
    });

    group('watchAnimals', () {
      test('should return a stream', () async {
        final stream = repository.watchAnimals('farm-1');
        expect(stream, isA<Stream<List<Animal>>>());
      });

      test('should emit data after adding animals', () async {
        // Add an animal first
        await repository.addAnimal(
          createTestAnimal(farmId: 'farm-1', tagId: 'STREAM-001'),
        );

        // Then get the stream - it should have the animal
        final stream = repository.watchAnimals('farm-1');
        final data = await stream.first;

        expect(data.length, 1);
        expect(data.first.tagId, 'STREAM-001');
      });
    });
  });
}
