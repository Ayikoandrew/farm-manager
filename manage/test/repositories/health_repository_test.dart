/// Health Repository Tests - Migrated to Supabase Mock Testing
/// Uses MockSupabaseDatabase instead of FakeFirebaseFirestore

import 'package:flutter_test/flutter_test.dart';
import 'package:manage/models/health_record.dart';
import '../mocks/mock_supabase.dart';

/// Mock HealthRepository for testing with MockSupabaseDatabase
class MockHealthRepository {
  final MockSupabaseDatabase db;
  static const String _table = 'health_records';

  MockHealthRepository({required this.db});

  /// Add a health record
  Future<String> addHealthRecord(HealthRecord record) async {
    final data = record.toSupabase();
    final inserted = db.insert(_table, data);
    return inserted['id'] as String;
  }

  /// Get a single health record by ID
  Future<HealthRecord?> getHealthRecord(String id) async {
    final data = db.selectSingle(_table, where: {'id': id});
    if (data == null) return null;
    return HealthRecord.fromSupabase(data);
  }

  /// Get all health records for a farm
  Future<List<HealthRecord>> getHealthRecords(String farmId) async {
    final data = db.select(_table, where: {'farm_id': farmId});
    return data.map((json) => HealthRecord.fromSupabase(json)).toList();
  }

  /// Get health records for an animal
  Future<List<HealthRecord>> getAnimalHealthRecords(String animalId) async {
    final data = db.select(_table, where: {'animal_id': animalId});
    return data.map((json) => HealthRecord.fromSupabase(json)).toList();
  }

  /// Update a health record
  Future<void> updateHealthRecord(HealthRecord record) async {
    db.update(_table, record.toSupabase(), where: {'id': record.id});
  }

  /// Delete a health record
  Future<void> deleteHealthRecord(String id) async {
    db.delete(_table, where: {'id': id});
  }

  /// Watch health records for a farm
  Stream<List<HealthRecord>> watchHealthRecords(String farmId) {
    return db
        .stream(_table, where: {'farm_id': farmId})
        .map(
          (data) =>
              data.map((json) => HealthRecord.fromSupabase(json)).toList(),
        );
  }

  /// Watch health records for an animal
  Stream<List<HealthRecord>> watchAnimalHealthRecords(String animalId) {
    return db
        .stream(_table, where: {'animal_id': animalId})
        .map(
          (data) =>
              data.map((json) => HealthRecord.fromSupabase(json)).toList(),
        );
  }

  /// Watch health records by type
  Stream<List<HealthRecord>> watchHealthRecordsByType(
    String farmId,
    HealthRecordType type,
  ) {
    return db
        .stream(_table, where: {'farm_id': farmId})
        .map(
          (data) => data
              .where((json) => json['type'] == type.name)
              .map((json) => HealthRecord.fromSupabase(json))
              .toList(),
        );
  }

  /// Watch upcoming vaccinations
  Stream<List<HealthRecord>> watchUpcomingVaccinations(
    String farmId, {
    int withinDays = 30,
  }) {
    final now = DateTime.now();
    final cutoffDate = now.add(Duration(days: withinDays));

    return db
        .stream(_table, where: {'farm_id': farmId})
        .map(
          (data) => data
              .where((json) {
                if (json['type'] != HealthRecordType.vaccination.name)
                  return false;
                if (json['next_due_date'] == null) return false;
                final nextDue = DateTime.parse(json['next_due_date']);
                return nextDue.isAfter(now) && nextDue.isBefore(cutoffDate);
              })
              .map((json) => HealthRecord.fromSupabase(json))
              .toList(),
        );
  }

  /// Watch animals in withdrawal period
  Stream<List<HealthRecord>> watchAnimalsInWithdrawal(String farmId) {
    final now = DateTime.now();

    return db
        .stream(_table, where: {'farm_id': farmId})
        .map(
          (data) => data
              .where((json) {
                if (json['withdrawal_end_date'] == null) return false;
                final withdrawalEnd = DateTime.parse(
                  json['withdrawal_end_date'],
                );
                return withdrawalEnd.isAfter(now);
              })
              .map((json) => HealthRecord.fromSupabase(json))
              .toList(),
        );
  }
}

void main() {
  late MockSupabaseDatabase mockDb;
  late MockHealthRepository repository;

  setUp(() {
    mockDb = MockSupabaseDatabase();
    repository = MockHealthRepository(db: mockDb);
  });

  tearDown(() {
    mockDb.dispose();
  });

  HealthRecord createTestHealthRecord({
    String id = 'health-1',
    String farmId = 'farm-1',
    String animalId = 'animal-1',
    HealthRecordType type = HealthRecordType.vaccination,
    DateTime? date,
    String title = 'Test Health Record',
    String? description,
    HealthStatus status = HealthStatus.completed,
    DateTime? nextDueDate,
    DateTime? followUpDate,
    DateTime? withdrawalEndDate,
    String recordedBy = 'user-1',
  }) {
    return HealthRecord(
      id: id,
      farmId: farmId,
      animalId: animalId,
      type: type,
      date: date ?? DateTime.now(),
      title: title,
      description: description,
      status: status,
      nextDueDate: nextDueDate,
      followUpDate: followUpDate,
      withdrawalEndDate: withdrawalEndDate,
      recordedBy: recordedBy,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> addHealthRecordToDb(HealthRecord record) async {
    final data = record.toSupabase();
    data['id'] = record.id;
    mockDb.insert('health_records', data);
  }

  group('HealthRepository', () {
    group('addHealthRecord', () {
      test('should add a health record and return document ID', () async {
        final record = createTestHealthRecord();

        final docId = await repository.addHealthRecord(record);

        expect(docId, isNotEmpty);
        final data = mockDb.selectSingle(
          'health_records',
          where: {'id': docId},
        );
        expect(data, isNotNull);
      });

      test('should store vaccination data correctly', () async {
        final record = createTestHealthRecord(
          type: HealthRecordType.vaccination,
          title: 'FMD Vaccine',
          description: 'Annual FMD vaccination',
        );

        final docId = await repository.addHealthRecord(record);

        final data = mockDb.selectSingle(
          'health_records',
          where: {'id': docId},
        );
        expect(data!['type'], 'vaccination');
        expect(data['title'], 'FMD Vaccine');
        expect(data['description'], 'Annual FMD vaccination');
      });
    });

    group('getHealthRecord', () {
      test('should return health record when exists', () async {
        final record = createTestHealthRecord();
        await addHealthRecordToDb(record);

        final result = await repository.getHealthRecord(record.id);

        expect(result, isNotNull);
        expect(result!.title, record.title);
      });

      test('should return null when health record does not exist', () async {
        final result = await repository.getHealthRecord('non-existent');

        expect(result, isNull);
      });
    });

    group('getHealthRecords', () {
      test('should return all health records for a farm', () async {
        await addHealthRecordToDb(
          createTestHealthRecord(id: 'h1', farmId: 'farm-1', title: 'Record 1'),
        );
        await addHealthRecordToDb(
          createTestHealthRecord(id: 'h2', farmId: 'farm-1', title: 'Record 2'),
        );
        await addHealthRecordToDb(
          createTestHealthRecord(id: 'h3', farmId: 'farm-2', title: 'Record 3'),
        );

        final result = await repository.getHealthRecords('farm-1');

        expect(result.length, 2);
      });

      test('should return empty list when no records exist', () async {
        final result = await repository.getHealthRecords('empty-farm');

        expect(result, isEmpty);
      });
    });

    group('getAnimalHealthRecords', () {
      test('should return all health records for an animal', () async {
        await addHealthRecordToDb(
          createTestHealthRecord(id: 'h1', animalId: 'animal-1'),
        );
        await addHealthRecordToDb(
          createTestHealthRecord(id: 'h2', animalId: 'animal-1'),
        );
        await addHealthRecordToDb(
          createTestHealthRecord(id: 'h3', animalId: 'animal-2'),
        );

        final result = await repository.getAnimalHealthRecords('animal-1');

        expect(result.length, 2);
        expect(result.every((r) => r.animalId == 'animal-1'), isTrue);
      });
    });

    group('updateHealthRecord', () {
      test('should update health record data', () async {
        final record = createTestHealthRecord();
        await addHealthRecordToDb(record);

        final updatedRecord = record.copyWith(
          title: 'Updated Title',
          status: HealthStatus.completed,
        );
        await repository.updateHealthRecord(updatedRecord);

        final data = mockDb.selectSingle(
          'health_records',
          where: {'id': record.id},
        );
        expect(data!['title'], 'Updated Title');
        expect(data['status'], 'completed');
      });
    });

    group('deleteHealthRecord', () {
      test('should delete health record', () async {
        final record = createTestHealthRecord();
        await addHealthRecordToDb(record);

        await repository.deleteHealthRecord(record.id);

        final data = mockDb.selectSingle(
          'health_records',
          where: {'id': record.id},
        );
        expect(data, isNull);
      });
    });

    group('watchHealthRecords', () {
      test('should emit health records for farm', () async {
        await addHealthRecordToDb(
          createTestHealthRecord(id: 'h1', farmId: 'farm-1'),
        );

        final stream = repository.watchHealthRecords('farm-1');

        await expectLater(
          stream.first,
          completion(
            isA<List<HealthRecord>>().having(
              (list) => list.length,
              'length',
              1,
            ),
          ),
        );
      });

      test('should emit empty list for farm with no records', () async {
        final stream = repository.watchHealthRecords('empty-farm');

        await expectLater(stream.first, completion(isEmpty));
      });
    });

    group('watchAnimalHealthRecords', () {
      test('should emit only records for specific animal', () async {
        await addHealthRecordToDb(
          createTestHealthRecord(id: 'h1', animalId: 'animal-1'),
        );
        await addHealthRecordToDb(
          createTestHealthRecord(id: 'h2', animalId: 'animal-2'),
        );

        final stream = repository.watchAnimalHealthRecords('animal-1');

        await expectLater(
          stream.first,
          completion(
            isA<List<HealthRecord>>().having(
              (list) => list.every((r) => r.animalId == 'animal-1'),
              'all for animal-1',
              isTrue,
            ),
          ),
        );
      });
    });

    group('watchHealthRecordsByType', () {
      test('should emit only records of specified type', () async {
        await addHealthRecordToDb(
          createTestHealthRecord(
            id: 'h1',
            farmId: 'farm-1',
            type: HealthRecordType.vaccination,
          ),
        );
        await addHealthRecordToDb(
          createTestHealthRecord(
            id: 'h2',
            farmId: 'farm-1',
            type: HealthRecordType.medication,
          ),
        );

        final stream = repository.watchHealthRecordsByType(
          'farm-1',
          HealthRecordType.vaccination,
        );

        await expectLater(
          stream.first,
          completion(
            isA<List<HealthRecord>>().having(
              (list) =>
                  list.every((r) => r.type == HealthRecordType.vaccination),
              'all vaccinations',
              isTrue,
            ),
          ),
        );
      });
    });

    group('watchUpcomingVaccinations', () {
      test('should emit vaccinations due within specified days', () async {
        final now = DateTime.now();
        final inTenDays = now.add(const Duration(days: 10));
        final inSixtyDays = now.add(const Duration(days: 60));

        await addHealthRecordToDb(
          createTestHealthRecord(
            id: 'h1',
            farmId: 'farm-1',
            type: HealthRecordType.vaccination,
            nextDueDate: inTenDays,
          ),
        );
        await addHealthRecordToDb(
          createTestHealthRecord(
            id: 'h2',
            farmId: 'farm-1',
            type: HealthRecordType.vaccination,
            nextDueDate: inSixtyDays,
          ),
        );

        final stream = repository.watchUpcomingVaccinations(
          'farm-1',
          withinDays: 30,
        );

        await expectLater(
          stream.first,
          completion(
            isA<List<HealthRecord>>().having(
              (list) => list.length,
              'length',
              1,
            ),
          ),
        );
      });
    });

    group('watchAnimalsInWithdrawal', () {
      test('should emit records with active withdrawal period', () async {
        final now = DateTime.now();
        final futureWithdrawal = now.add(const Duration(days: 5));
        final pastWithdrawal = now.subtract(const Duration(days: 5));

        await addHealthRecordToDb(
          createTestHealthRecord(
            id: 'h1',
            farmId: 'farm-1',
            type: HealthRecordType.medication,
            withdrawalEndDate: futureWithdrawal,
          ),
        );
        await addHealthRecordToDb(
          createTestHealthRecord(
            id: 'h2',
            farmId: 'farm-1',
            type: HealthRecordType.medication,
            withdrawalEndDate: pastWithdrawal,
          ),
        );

        final stream = repository.watchAnimalsInWithdrawal('farm-1');

        await expectLater(
          stream.first,
          completion(
            isA<List<HealthRecord>>().having(
              (list) => list.length,
              'length',
              1,
            ),
          ),
        );
      });
    });

    group('Record Types', () {
      test('should handle vaccination records', () async {
        final record = createTestHealthRecord(
          type: HealthRecordType.vaccination,
          title: 'FMD Vaccine',
        );

        final docId = await repository.addHealthRecord(record);
        final result = await repository.getHealthRecord(docId);

        expect(result!.type, HealthRecordType.vaccination);
      });

      test('should handle medication records', () async {
        final record = createTestHealthRecord(
          type: HealthRecordType.medication,
          title: 'Dewormer',
        );

        final docId = await repository.addHealthRecord(record);
        final result = await repository.getHealthRecord(docId);

        expect(result!.type, HealthRecordType.medication);
      });

      test('should handle treatment records', () async {
        final record = createTestHealthRecord(
          type: HealthRecordType.treatment,
          title: 'Wound Treatment',
        );

        final docId = await repository.addHealthRecord(record);
        final result = await repository.getHealthRecord(docId);

        expect(result!.type, HealthRecordType.treatment);
      });

      test('should handle checkup records', () async {
        final record = createTestHealthRecord(
          type: HealthRecordType.checkup,
          title: 'Monthly Checkup',
        );

        final docId = await repository.addHealthRecord(record);
        final result = await repository.getHealthRecord(docId);

        expect(result!.type, HealthRecordType.checkup);
      });

      test('should handle surgery records', () async {
        final record = createTestHealthRecord(
          type: HealthRecordType.surgery,
          title: 'Castration',
        );

        final docId = await repository.addHealthRecord(record);
        final result = await repository.getHealthRecord(docId);

        expect(result!.type, HealthRecordType.surgery);
      });

      test('should handle observation records', () async {
        final record = createTestHealthRecord(
          type: HealthRecordType.observation,
          title: 'Behavior Observation',
        );

        final docId = await repository.addHealthRecord(record);
        final result = await repository.getHealthRecord(docId);

        expect(result!.type, HealthRecordType.observation);
      });
    });
  });
}
