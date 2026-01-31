/// Breeding Repository Tests - Migrated to Supabase Mock Testing
/// Uses MockSupabaseDatabase instead of FakeFirebaseFirestore

import 'package:flutter_test/flutter_test.dart';
import 'package:manage/models/breeding_record.dart';
import '../mocks/mock_supabase.dart';

/// Mock BreedingRepository for testing with MockSupabaseDatabase
class MockBreedingRepository {
  final MockSupabaseDatabase db;
  static const String _table = 'breeding_records';

  MockBreedingRepository({required this.db});

  /// Add a breeding record
  Future<String> addBreedingRecord(BreedingRecord record) async {
    final data = record.toSupabase();
    final inserted = db.insert(_table, data);
    return inserted['id'] as String;
  }

  /// Update a breeding record
  Future<void> updateBreedingRecord(BreedingRecord record) async {
    db.update(_table, record.toSupabase(), where: {'id': record.id});
  }

  /// Delete a breeding record
  Future<void> deleteBreedingRecord(String id) async {
    db.delete(_table, where: {'id': id});
  }

  /// Mark as bred with breeding date and optional sire
  Future<void> markAsBred(
    String id,
    DateTime breedingDate,
    String? sireId,
  ) async {
    final expectedFarrowDate = breedingDate.add(
      const Duration(days: BreedingRecord.gestationDays),
    );
    db.update(
      _table,
      {
        'status': BreedingStatus.bred.name,
        'breeding_date': breedingDate.toIso8601String(),
        'expected_farrow_date': expectedFarrowDate.toIso8601String(),
        'sire_id': sireId,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: {'id': id},
    );
  }

  /// Confirm pregnancy
  Future<void> confirmPregnancy(String id) async {
    db.update(
      _table,
      {
        'status': BreedingStatus.pregnant.name,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: {'id': id},
    );
  }

  /// Record farrowing
  Future<void> recordFarrowing(
    String id,
    DateTime farrowDate,
    int litterSize,
  ) async {
    db.update(
      _table,
      {
        'status': BreedingStatus.farrowed.name,
        'actual_farrow_date': farrowDate.toIso8601String(),
        'litter_size': litterSize,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: {'id': id},
    );
  }

  /// Mark as failed
  Future<void> markAsFailed(String id) async {
    db.update(
      _table,
      {
        'status': BreedingStatus.failed.name,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: {'id': id},
    );
  }

  /// Watch breeding records for a farm
  Stream<List<BreedingRecord>> watchBreedingRecords(String farmId) {
    return db
        .stream(_table, where: {'farm_id': farmId})
        .map(
          (data) =>
              data.map((json) => BreedingRecord.fromSupabase(json)).toList(),
        );
  }

  /// Watch breeding records for an animal
  Stream<List<BreedingRecord>> watchBreedingRecordsForAnimal(String animalId) {
    return db
        .stream(_table, where: {'animal_id': animalId})
        .map(
          (data) =>
              data.map((json) => BreedingRecord.fromSupabase(json)).toList(),
        );
  }

  /// Watch pregnant animals
  Stream<List<BreedingRecord>> watchPregnantAnimals(String farmId) {
    return db
        .stream(_table, where: {'farm_id': farmId})
        .map(
          (data) => data
              .where((json) => json['status'] == BreedingStatus.pregnant.name)
              .map((json) => BreedingRecord.fromSupabase(json))
              .toList(),
        );
  }

  /// Watch animals in heat
  Stream<List<BreedingRecord>> watchAnimalsInHeat(String farmId) {
    return db
        .stream(_table, where: {'farm_id': farmId})
        .map(
          (data) => data
              .where((json) => json['status'] == BreedingStatus.inHeat.name)
              .map((json) => BreedingRecord.fromSupabase(json))
              .toList(),
        );
  }

  /// Get upcoming farrowings
  Future<List<BreedingRecord>> getUpcomingFarrowings(
    String farmId,
    int withinDays,
  ) async {
    final now = DateTime.now();
    final cutoffDate = now.add(Duration(days: withinDays));

    final allRecords = db.select(_table, where: {'farm_id': farmId});
    return allRecords
        .where((json) {
          if (json['status'] != BreedingStatus.pregnant.name) return false;
          if (json['expected_farrow_date'] == null) return false;
          final expectedDate = DateTime.parse(json['expected_farrow_date']);
          return expectedDate.isAfter(now) && expectedDate.isBefore(cutoffDate);
        })
        .map((json) => BreedingRecord.fromSupabase(json))
        .toList();
  }
}

void main() {
  late MockSupabaseDatabase mockDb;
  late MockBreedingRepository repository;

  setUp(() {
    mockDb = MockSupabaseDatabase();
    repository = MockBreedingRepository(db: mockDb);
  });

  tearDown(() {
    mockDb.dispose();
  });

  BreedingRecord createTestBreedingRecord({
    String id = 'breeding-1',
    String farmId = 'farm-1',
    String animalId = 'animal-1',
    String? sireId,
    DateTime? heatDate,
    DateTime? breedingDate,
    DateTime? expectedFarrowDate,
    DateTime? actualFarrowDate,
    BreedingStatus status = BreedingStatus.inHeat,
    int? litterSize,
    String? notes,
  }) {
    return BreedingRecord(
      id: id,
      farmId: farmId,
      animalId: animalId,
      sireId: sireId,
      heatDate: heatDate ?? DateTime.now(),
      breedingDate: breedingDate,
      expectedFarrowDate: expectedFarrowDate,
      actualFarrowDate: actualFarrowDate,
      status: status,
      litterSize: litterSize,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> addBreedingRecordToDb(BreedingRecord record) async {
    final data = record.toSupabase();
    data['id'] = record.id;
    mockDb.insert('breeding_records', data);
  }

  group('BreedingRepository', () {
    group('addBreedingRecord', () {
      test('should add a breeding record and return document ID', () async {
        final record = createTestBreedingRecord();

        final docId = await repository.addBreedingRecord(record);

        expect(docId, isNotEmpty);
        final data = mockDb.selectSingle(
          'breeding_records',
          where: {'id': docId},
        );
        expect(data, isNotNull);
      });

      test('should store breeding data correctly', () async {
        final record = createTestBreedingRecord(
          animalId: 'sow-001',
          sireId: 'boar-001',
          status: BreedingStatus.pregnant,
          notes: 'AI breeding',
        );

        final docId = await repository.addBreedingRecord(record);

        final data = mockDb.selectSingle(
          'breeding_records',
          where: {'id': docId},
        );
        expect(data!['animal_id'], 'sow-001');
        expect(data['sire_id'], 'boar-001');
        expect(data['status'], 'pregnant');
        expect(data['notes'], 'AI breeding');
      });
    });

    group('updateBreedingRecord', () {
      test('should update breeding record data', () async {
        final record = createTestBreedingRecord();
        await addBreedingRecordToDb(record);

        final updatedRecord = record.copyWith(
          status: BreedingStatus.pregnant,
          notes: 'Confirmed pregnancy',
        );
        await repository.updateBreedingRecord(updatedRecord);

        final data = mockDb.selectSingle(
          'breeding_records',
          where: {'id': record.id},
        );
        expect(data!['status'], 'pregnant');
        expect(data['notes'], 'Confirmed pregnancy');
      });
    });

    group('deleteBreedingRecord', () {
      test('should delete breeding record', () async {
        final record = createTestBreedingRecord();
        await addBreedingRecordToDb(record);

        await repository.deleteBreedingRecord(record.id);

        final data = mockDb.selectSingle(
          'breeding_records',
          where: {'id': record.id},
        );
        expect(data, isNull);
      });
    });

    group('markAsBred', () {
      test('should update status to bred with breeding date', () async {
        final record = createTestBreedingRecord(status: BreedingStatus.inHeat);
        await addBreedingRecordToDb(record);

        final breedingDate = DateTime(2024, 6, 15);
        await repository.markAsBred(record.id, breedingDate, 'boar-001');

        final data = mockDb.selectSingle(
          'breeding_records',
          where: {'id': record.id},
        );
        expect(data!['status'], 'bred');
        expect(data['sire_id'], 'boar-001');
        final storedBreedingDate = DateTime.parse(data['breeding_date']);
        expect(storedBreedingDate.day, breedingDate.day);
      });

      test('should calculate expected farrow date (114 days)', () async {
        final record = createTestBreedingRecord();
        await addBreedingRecordToDb(record);

        final breedingDate = DateTime(2024, 6, 15);
        await repository.markAsBred(record.id, breedingDate, null);

        final data = mockDb.selectSingle(
          'breeding_records',
          where: {'id': record.id},
        );
        final expectedFarrowDate = DateTime.parse(
          data!['expected_farrow_date'],
        );

        // Expected farrow date should be ~114 days after breeding
        final daysDiff = expectedFarrowDate.difference(breedingDate).inDays;
        expect(daysDiff, 114);
      });
    });

    group('confirmPregnancy', () {
      test('should update status to pregnant', () async {
        final record = createTestBreedingRecord(status: BreedingStatus.bred);
        await addBreedingRecordToDb(record);

        await repository.confirmPregnancy(record.id);

        final data = mockDb.selectSingle(
          'breeding_records',
          where: {'id': record.id},
        );
        expect(data!['status'], 'pregnant');
      });
    });

    group('recordFarrowing', () {
      test('should record farrowing with litter size', () async {
        final record = createTestBreedingRecord(
          status: BreedingStatus.pregnant,
        );
        await addBreedingRecordToDb(record);

        final farrowDate = DateTime(2024, 10, 7);
        await repository.recordFarrowing(record.id, farrowDate, 12);

        final data = mockDb.selectSingle(
          'breeding_records',
          where: {'id': record.id},
        );
        expect(data!['status'], 'farrowed');
        expect(data['litter_size'], 12);
        final storedFarrowDate = DateTime.parse(data['actual_farrow_date']);
        expect(storedFarrowDate.day, farrowDate.day);
      });
    });

    group('markAsFailed', () {
      test('should update status to failed', () async {
        final record = createTestBreedingRecord(status: BreedingStatus.bred);
        await addBreedingRecordToDb(record);

        await repository.markAsFailed(record.id);

        final data = mockDb.selectSingle(
          'breeding_records',
          where: {'id': record.id},
        );
        expect(data!['status'], 'failed');
      });
    });

    group('watchBreedingRecords', () {
      test('should emit breeding records for farm', () async {
        await addBreedingRecordToDb(
          createTestBreedingRecord(id: 'b1', farmId: 'farm-1'),
        );

        final stream = repository.watchBreedingRecords('farm-1');

        await expectLater(
          stream.first,
          completion(
            isA<List<BreedingRecord>>().having(
              (list) => list.length,
              'length',
              1,
            ),
          ),
        );
      });
    });

    group('watchBreedingRecordsForAnimal', () {
      test('should emit only records for specific animal', () async {
        await addBreedingRecordToDb(
          createTestBreedingRecord(id: 'b1', animalId: 'animal-1'),
        );
        await addBreedingRecordToDb(
          createTestBreedingRecord(id: 'b2', animalId: 'animal-2'),
        );

        final stream = repository.watchBreedingRecordsForAnimal('animal-1');

        await expectLater(
          stream.first,
          completion(
            isA<List<BreedingRecord>>().having(
              (list) => list.every((r) => r.animalId == 'animal-1'),
              'all for animal-1',
              isTrue,
            ),
          ),
        );
      });
    });

    group('watchPregnantAnimals', () {
      test('should emit only pregnant records', () async {
        final expectedFarrow = DateTime.now().add(const Duration(days: 30));

        await addBreedingRecordToDb(
          createTestBreedingRecord(
            id: 'b1',
            farmId: 'farm-1',
            status: BreedingStatus.pregnant,
            expectedFarrowDate: expectedFarrow,
          ),
        );
        await addBreedingRecordToDb(
          createTestBreedingRecord(
            id: 'b2',
            farmId: 'farm-1',
            status: BreedingStatus.inHeat,
          ),
        );

        final stream = repository.watchPregnantAnimals('farm-1');

        await expectLater(
          stream.first,
          completion(
            isA<List<BreedingRecord>>().having(
              (list) => list.every((r) => r.status == BreedingStatus.pregnant),
              'all pregnant',
              isTrue,
            ),
          ),
        );
      });
    });

    group('watchAnimalsInHeat', () {
      test('should emit only in-heat records', () async {
        await addBreedingRecordToDb(
          createTestBreedingRecord(
            id: 'b1',
            farmId: 'farm-1',
            status: BreedingStatus.inHeat,
          ),
        );
        await addBreedingRecordToDb(
          createTestBreedingRecord(
            id: 'b2',
            farmId: 'farm-1',
            status: BreedingStatus.pregnant,
            expectedFarrowDate: DateTime.now().add(const Duration(days: 30)),
          ),
        );

        final stream = repository.watchAnimalsInHeat('farm-1');

        await expectLater(
          stream.first,
          completion(
            isA<List<BreedingRecord>>().having(
              (list) => list.every((r) => r.status == BreedingStatus.inHeat),
              'all in heat',
              isTrue,
            ),
          ),
        );
      });
    });

    group('getUpcomingFarrowings', () {
      test(
        'should return pregnant animals due within specified days',
        () async {
          final now = DateTime.now();
          final inTwentyDays = now.add(const Duration(days: 20));
          final inSixtyDays = now.add(const Duration(days: 60));

          await addBreedingRecordToDb(
            createTestBreedingRecord(
              id: 'b1',
              farmId: 'farm-1',
              status: BreedingStatus.pregnant,
              expectedFarrowDate: inTwentyDays,
            ),
          );
          await addBreedingRecordToDb(
            createTestBreedingRecord(
              id: 'b2',
              farmId: 'farm-1',
              status: BreedingStatus.pregnant,
              expectedFarrowDate: inSixtyDays,
            ),
          );

          final result = await repository.getUpcomingFarrowings('farm-1', 30);

          expect(result.length, 1);
          expect(result.first.id, 'b1');
        },
      );

      test('should return empty list when no upcoming farrowings', () async {
        await addBreedingRecordToDb(
          createTestBreedingRecord(
            id: 'b1',
            farmId: 'farm-1',
            status: BreedingStatus.inHeat,
          ),
        );

        final result = await repository.getUpcomingFarrowings('farm-1', 30);

        expect(result, isEmpty);
      });
    });
  });
}
