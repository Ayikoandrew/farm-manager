import 'package:flutter_test/flutter_test.dart';
import 'package:manage/models/weight_record.dart';

import '../helpers/test_factories.dart';
import '../mocks/mock_supabase.dart';
import '../mocks/mock_weight_repository.dart';

void main() {
  late MockSupabaseDatabase mockDb;
  late MockWeightRepository repository;

  setUp(() {
    mockDb = MockSupabaseDatabase();
    repository = MockWeightRepository(db: mockDb);
    resetAllFactories();
  });

  tearDown(() {
    mockDb.dispose();
  });

  WeightRecord createTestWeightRecord({
    String id = 'weight-1',
    String farmId = 'farm-1',
    String animalId = 'animal-1',
    double weight = 100.0,
    DateTime? date,
    String? notes,
  }) {
    return WeightRecord(
      id: id,
      farmId: farmId,
      animalId: animalId,
      weight: weight,
      date: date ?? DateTime.now(),
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  group('MockWeightRepository', () {
    group('addWeightRecord', () {
      test('should add a weight record and return document ID', () async {
        final record = createTestWeightRecord();

        final docId = await repository.addWeightRecord(record);

        expect(docId, isNotEmpty);
        final retrieved = await repository.getWeightRecord(docId);
        expect(retrieved, isNotNull);
      });

      test('should store weight record data correctly', () async {
        final record = createTestWeightRecord(
          animalId: 'animal-123',
          weight: 85.5,
          notes: 'After feeding',
        );

        final docId = await repository.addWeightRecord(record);

        final retrieved = await repository.getWeightRecord(docId);
        expect(retrieved!.animalId, 'animal-123');
        expect(retrieved.weight, 85.5);
        expect(retrieved.notes, 'After feeding');
      });
    });

    group('getWeightRecord', () {
      test('should return weight record when exists', () async {
        final record = createTestWeightRecord();
        final docId = await repository.addWeightRecord(record);

        final result = await repository.getWeightRecord(docId);

        expect(result, isNotNull);
        expect(result!.weight, record.weight);
      });

      test('should return null when record does not exist', () async {
        final result = await repository.getWeightRecord('non-existent');

        expect(result, isNull);
      });
    });

    group('getWeightRecords', () {
      test('should return all weight records for an animal', () async {
        await repository.addWeightRecord(
          createTestWeightRecord(id: 'w1', animalId: 'animal-1', weight: 100.0),
        );
        await repository.addWeightRecord(
          createTestWeightRecord(id: 'w2', animalId: 'animal-1', weight: 105.0),
        );
        await repository.addWeightRecord(
          createTestWeightRecord(id: 'w3', animalId: 'animal-2', weight: 80.0),
        );

        final result = await repository.getWeightRecords('animal-1');

        expect(result.length, 2);
        expect(result.map((r) => r.weight), containsAll([100.0, 105.0]));
      });

      test('should return empty list when no records exist', () async {
        final result = await repository.getWeightRecords('non-existent');

        expect(result, isEmpty);
      });

      test('should return records sorted by date descending', () async {
        final now = DateTime.now();
        await repository.addWeightRecord(
          createTestWeightRecord(
            id: 'w1',
            animalId: 'animal-1',
            weight: 100.0,
            date: now.subtract(const Duration(days: 10)),
          ),
        );
        await repository.addWeightRecord(
          createTestWeightRecord(
            id: 'w2',
            animalId: 'animal-1',
            weight: 110.0,
            date: now,
          ),
        );
        await repository.addWeightRecord(
          createTestWeightRecord(
            id: 'w3',
            animalId: 'animal-1',
            weight: 105.0,
            date: now.subtract(const Duration(days: 5)),
          ),
        );

        final result = await repository.getWeightRecords('animal-1');

        expect(result.length, 3);
        expect(result[0].weight, 110.0); // Most recent
        expect(result[1].weight, 105.0);
        expect(result[2].weight, 100.0); // Oldest
      });
    });

    group('getWeightRecordsForFarm', () {
      test('should return all weight records for a farm', () async {
        await repository.addWeightRecord(
          createTestWeightRecord(id: 'w1', farmId: 'farm-1', animalId: 'a1'),
        );
        await repository.addWeightRecord(
          createTestWeightRecord(id: 'w2', farmId: 'farm-1', animalId: 'a2'),
        );
        await repository.addWeightRecord(
          createTestWeightRecord(id: 'w3', farmId: 'farm-2', animalId: 'a3'),
        );

        final result = await repository.getWeightRecordsForFarm('farm-1');

        expect(result.length, 2);
      });
    });

    group('getLatestWeightRecord', () {
      test('should return the most recent weight record', () async {
        final now = DateTime.now();
        await repository.addWeightRecord(
          createTestWeightRecord(
            id: 'w1',
            animalId: 'animal-1',
            weight: 100.0,
            date: now.subtract(const Duration(days: 10)),
          ),
        );
        await repository.addWeightRecord(
          createTestWeightRecord(
            id: 'w2',
            animalId: 'animal-1',
            weight: 115.0,
            date: now,
          ),
        );

        final result = await repository.getLatestWeightRecord('animal-1');

        expect(result, isNotNull);
        expect(result!.weight, 115.0);
      });

      test('should return null when no records exist', () async {
        final result = await repository.getLatestWeightRecord('non-existent');

        expect(result, isNull);
      });
    });

    group('updateWeightRecord', () {
      test('should update weight record data', () async {
        final record = createTestWeightRecord(weight: 100.0);
        final docId = await repository.addWeightRecord(record);
        final stored = await repository.getWeightRecord(docId);

        final updated = stored!.copyWith(weight: 105.0, notes: 'Updated');
        await repository.updateWeightRecord(updated);

        final result = await repository.getWeightRecord(docId);
        expect(result!.weight, 105.0);
        expect(result.notes, 'Updated');
      });
    });

    group('deleteWeightRecord', () {
      test('should remove weight record from database', () async {
        final record = createTestWeightRecord();
        final docId = await repository.addWeightRecord(record);

        await repository.deleteWeightRecord(docId);

        final result = await repository.getWeightRecord(docId);
        expect(result, isNull);
      });
    });

    group('getWeightRecordsInRange', () {
      test('should return records within date range', () async {
        final now = DateTime.now();
        await repository.addWeightRecord(
          createTestWeightRecord(
            id: 'w1',
            animalId: 'animal-1',
            weight: 100.0,
            date: now.subtract(const Duration(days: 30)),
          ),
        );
        await repository.addWeightRecord(
          createTestWeightRecord(
            id: 'w2',
            animalId: 'animal-1',
            weight: 110.0,
            date: now.subtract(const Duration(days: 15)),
          ),
        );
        await repository.addWeightRecord(
          createTestWeightRecord(
            id: 'w3',
            animalId: 'animal-1',
            weight: 120.0,
            date: now,
          ),
        );

        final result = await repository.getWeightRecordsInRange(
          'animal-1',
          start: now.subtract(const Duration(days: 20)),
          end: now,
        );

        expect(result.length, 2);
        expect(result.map((r) => r.weight), containsAll([110.0, 120.0]));
      });
    });

    group('calculateWeightGain', () {
      test('should calculate positive weight gain', () {
        final older = createTestWeightRecord(weight: 100.0);
        final newer = createTestWeightRecord(weight: 115.0);

        final gain = repository.calculateWeightGain(older, newer);

        expect(gain, 15.0);
      });

      test('should calculate negative weight change', () {
        final older = createTestWeightRecord(weight: 100.0);
        final newer = createTestWeightRecord(weight: 95.0);

        final gain = repository.calculateWeightGain(older, newer);

        expect(gain, -5.0);
      });
    });

    group('calculateAverageDailyGain', () {
      test('should calculate correct ADG', () {
        final now = DateTime.now();
        final older = createTestWeightRecord(
          weight: 100.0,
          date: now.subtract(const Duration(days: 10)),
        );
        final newer = createTestWeightRecord(
          weight: 110.0,
          date: now,
        );

        final adg = repository.calculateAverageDailyGain(older, newer);

        expect(adg, closeTo(1.0, 0.01)); // 10kg over 10 days = 1kg/day
      });

      test('should return null for zero or negative days', () {
        final now = DateTime.now();
        final record1 = createTestWeightRecord(weight: 100.0, date: now);
        final record2 = createTestWeightRecord(weight: 110.0, date: now);

        final adg = repository.calculateAverageDailyGain(record1, record2);

        expect(adg, isNull);
      });
    });

    group('watchWeightRecords', () {
      test('should return a stream', () async {
        final stream = repository.watchWeightRecords('animal-1');
        expect(stream, isA<Stream<List<WeightRecord>>>());
      });

      test('should emit data after adding records', () async {
        await repository.addWeightRecord(
          createTestWeightRecord(animalId: 'animal-1', weight: 100.0),
        );

        final stream = repository.watchWeightRecords('animal-1');
        final data = await stream.first;

        expect(data.length, 1);
        expect(data.first.weight, 100.0);
      });
    });
  });
}
