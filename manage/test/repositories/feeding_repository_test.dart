/// Feeding Repository Tests - Migrated to Supabase Mock Testing
/// Uses MockSupabaseDatabase instead of FakeFirebaseFirestore

import 'package:flutter_test/flutter_test.dart';
import 'package:manage/models/feeding_record.dart';
import '../mocks/mock_supabase.dart';

/// Mock FeedingRepository for testing with MockSupabaseDatabase
class MockFeedingRepository {
  final MockSupabaseDatabase db;
  static const String _table = 'feeding_records';

  MockFeedingRepository({required this.db});

  /// Add a feeding record
  Future<String> addFeedingRecord(FeedingRecord record) async {
    final data = record.toSupabase();
    final inserted = db.insert(_table, data);
    return inserted['id'] as String;
  }

  /// Update a feeding record
  Future<void> updateFeedingRecord(FeedingRecord record) async {
    db.update(_table, record.toSupabase(), where: {'id': record.id});
  }

  /// Delete a feeding record
  Future<void> deleteFeedingRecord(String id) async {
    db.delete(_table, where: {'id': id});
  }

  /// Watch feeding records for a farm
  Stream<List<FeedingRecord>> watchFeedingRecords(String farmId) {
    return db
        .stream(_table, where: {'farm_id': farmId})
        .map(
          (data) =>
              data.map((json) => FeedingRecord.fromSupabase(json)).toList(),
        );
  }

  /// Watch feeding records for an animal
  Stream<List<FeedingRecord>> watchFeedingRecordsForAnimal(String animalId) {
    return db
        .stream(_table, where: {'animal_id': animalId})
        .map(
          (data) =>
              data.map((json) => FeedingRecord.fromSupabase(json)).toList(),
        );
  }

  /// Get feeding records for a date range
  Future<List<FeedingRecord>> getFeedingRecordsForDateRange(
    String farmId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final allRecords = db.select(_table, where: {'farm_id': farmId});
    return allRecords
        .where((json) {
          final date = DateTime.parse(json['date']);
          return date.isAfter(startDate) && date.isBefore(endDate);
        })
        .map((json) => FeedingRecord.fromSupabase(json))
        .toList();
  }

  /// Get total feed quantity for an animal
  Future<double> getTotalFeedForAnimal(String animalId) async {
    final records = db.select(_table, where: {'animal_id': animalId});
    if (records.isEmpty) return 0.0;
    return records.fold<double>(
      0.0,
      (sum, json) => sum + (json['quantity'] as num).toDouble(),
    );
  }

  /// Get total feed for a specific date
  Future<double> getTotalFeedForDate(String farmId, DateTime date) async {
    final allRecords = db.select(_table, where: {'farm_id': farmId});
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final dayRecords = allRecords.where((json) {
      final recordDate = DateTime.parse(json['date']);
      return recordDate.isAfter(
            dayStart.subtract(const Duration(seconds: 1)),
          ) &&
          recordDate.isBefore(dayEnd);
    }).toList();

    if (dayRecords.isEmpty) return 0.0;
    return dayRecords.fold<double>(
      0.0,
      (sum, json) => sum + (json['quantity'] as num).toDouble(),
    );
  }
}

void main() {
  late MockSupabaseDatabase mockDb;
  late MockFeedingRepository repository;

  setUp(() {
    mockDb = MockSupabaseDatabase();
    repository = MockFeedingRepository(db: mockDb);
  });

  tearDown(() {
    mockDb.dispose();
  });

  FeedingRecord createTestFeedingRecord({
    String id = 'feeding-1',
    String farmId = 'farm-1',
    String animalId = 'animal-1',
    String feedType = 'Pig Feed',
    double quantity = 5.0,
    DateTime? date,
    String? notes,
  }) {
    return FeedingRecord(
      id: id,
      farmId: farmId,
      animalId: animalId,
      feedType: feedType,
      quantity: quantity,
      date: date ?? DateTime.now(),
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  Future<void> addFeedingRecordToDb(FeedingRecord record) async {
    final data = record.toSupabase();
    data['id'] = record.id;
    mockDb.insert('feeding_records', data);
  }

  group('FeedingRepository', () {
    group('addFeedingRecord', () {
      test('should add a feeding record and return document ID', () async {
        final record = createTestFeedingRecord();

        final docId = await repository.addFeedingRecord(record);

        expect(docId, isNotEmpty);
        final data = mockDb.selectSingle(
          'feeding_records',
          where: {'id': docId},
        );
        expect(data, isNotNull);
      });

      test('should store feeding record data correctly', () async {
        final record = createTestFeedingRecord(
          feedType: 'Starter Feed',
          quantity: 10.5,
        );

        final docId = await repository.addFeedingRecord(record);

        final data = mockDb.selectSingle(
          'feeding_records',
          where: {'id': docId},
        );
        expect(data!['feed_type'], 'Starter Feed');
        expect(data['quantity'], 10.5);
      });
    });

    group('updateFeedingRecord', () {
      test('should update feeding record data', () async {
        final record = createTestFeedingRecord();
        await addFeedingRecordToDb(record);

        final updatedRecord = record.copyWith(
          quantity: 15.0,
          feedType: 'Grower Feed',
        );
        await repository.updateFeedingRecord(updatedRecord);

        final data = mockDb.selectSingle(
          'feeding_records',
          where: {'id': record.id},
        );
        expect(data!['quantity'], 15.0);
        expect(data['feed_type'], 'Grower Feed');
      });
    });

    group('deleteFeedingRecord', () {
      test('should delete feeding record', () async {
        final record = createTestFeedingRecord();
        await addFeedingRecordToDb(record);

        await repository.deleteFeedingRecord(record.id);

        final data = mockDb.selectSingle(
          'feeding_records',
          where: {'id': record.id},
        );
        expect(data, isNull);
      });
    });

    group('watchFeedingRecords', () {
      test('should emit feeding records for farm', () async {
        await addFeedingRecordToDb(
          createTestFeedingRecord(id: 'f1', farmId: 'farm-1'),
        );
        await addFeedingRecordToDb(
          createTestFeedingRecord(id: 'f2', farmId: 'farm-1'),
        );

        final stream = repository.watchFeedingRecords('farm-1');

        await expectLater(
          stream.first,
          completion(
            isA<List<FeedingRecord>>().having(
              (list) => list.length,
              'length',
              2,
            ),
          ),
        );
      });

      test('should emit empty list for farm with no records', () async {
        final stream = repository.watchFeedingRecords('empty-farm');

        await expectLater(stream.first, completion(isEmpty));
      });

      test('should filter by farm ID', () async {
        await addFeedingRecordToDb(
          createTestFeedingRecord(id: 'f1', farmId: 'farm-1'),
        );
        await addFeedingRecordToDb(
          createTestFeedingRecord(id: 'f2', farmId: 'farm-2'),
        );

        final stream = repository.watchFeedingRecords('farm-1');

        await expectLater(
          stream.first,
          completion(
            isA<List<FeedingRecord>>().having(
              (list) => list.every((r) => r.farmId == 'farm-1'),
              'all for farm-1',
              isTrue,
            ),
          ),
        );
      });
    });

    group('watchFeedingRecordsForAnimal', () {
      test('should emit only records for specific animal', () async {
        await addFeedingRecordToDb(
          createTestFeedingRecord(id: 'f1', animalId: 'animal-1'),
        );
        await addFeedingRecordToDb(
          createTestFeedingRecord(id: 'f2', animalId: 'animal-2'),
        );

        final stream = repository.watchFeedingRecordsForAnimal('animal-1');

        await expectLater(
          stream.first,
          completion(
            isA<List<FeedingRecord>>().having(
              (list) => list.every((r) => r.animalId == 'animal-1'),
              'all for animal-1',
              isTrue,
            ),
          ),
        );
      });

      test('should emit empty list for animal with no records', () async {
        final stream = repository.watchFeedingRecordsForAnimal(
          'unknown-animal',
        );

        await expectLater(stream.first, completion(isEmpty));
      });
    });

    group('getFeedingRecordsForDateRange', () {
      test('should return records within date range', () async {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        final lastWeek = today.subtract(const Duration(days: 7));

        await addFeedingRecordToDb(
          createTestFeedingRecord(id: 'f1', farmId: 'farm-1', date: today),
        );
        await addFeedingRecordToDb(
          createTestFeedingRecord(id: 'f2', farmId: 'farm-1', date: yesterday),
        );
        await addFeedingRecordToDb(
          createTestFeedingRecord(id: 'f3', farmId: 'farm-1', date: lastWeek),
        );

        final results = await repository.getFeedingRecordsForDateRange(
          'farm-1',
          yesterday.subtract(const Duration(hours: 1)),
          today.add(const Duration(hours: 1)),
        );

        expect(results.length, 2);
      });

      test('should return empty list for date range with no records', () async {
        final futureStart = DateTime.now().add(const Duration(days: 30));
        final futureEnd = DateTime.now().add(const Duration(days: 60));

        final results = await repository.getFeedingRecordsForDateRange(
          'farm-1',
          futureStart,
          futureEnd,
        );

        expect(results, isEmpty);
      });
    });

    group('getTotalFeedForAnimal', () {
      test('should return total feed quantity for animal', () async {
        await addFeedingRecordToDb(
          createTestFeedingRecord(
            id: 'f1',
            animalId: 'animal-1',
            quantity: 5.0,
          ),
        );
        await addFeedingRecordToDb(
          createTestFeedingRecord(
            id: 'f2',
            animalId: 'animal-1',
            quantity: 10.0,
          ),
        );
        await addFeedingRecordToDb(
          createTestFeedingRecord(
            id: 'f3',
            animalId: 'animal-2',
            quantity: 20.0,
          ),
        );

        final total = await repository.getTotalFeedForAnimal('animal-1');

        expect(total, 15.0);
      });

      test('should return 0 for animal with no records', () async {
        final total = await repository.getTotalFeedForAnimal('unknown-animal');

        expect(total, 0.0);
      });
    });

    group('getTotalFeedForDate', () {
      test('should return total feed for specific date', () async {
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day, 8, 0);
        final todayEnd = DateTime(today.year, today.month, today.day, 18, 0);

        await addFeedingRecordToDb(
          createTestFeedingRecord(
            id: 'f1',
            farmId: 'farm-1',
            date: todayStart,
            quantity: 5.0,
          ),
        );
        await addFeedingRecordToDb(
          createTestFeedingRecord(
            id: 'f2',
            farmId: 'farm-1',
            date: todayEnd,
            quantity: 10.0,
          ),
        );
        await addFeedingRecordToDb(
          createTestFeedingRecord(
            id: 'f3',
            farmId: 'farm-1',
            date: today.subtract(const Duration(days: 1)),
            quantity: 20.0,
          ),
        );

        final total = await repository.getTotalFeedForDate('farm-1', today);

        expect(total, 15.0);
      });

      test('should return 0 for date with no records', () async {
        final futureDate = DateTime.now().add(const Duration(days: 100));

        final total = await repository.getTotalFeedForDate(
          'farm-1',
          futureDate,
        );

        expect(total, 0.0);
      });
    });

    group('Feed Types', () {
      test('should handle different feed types', () async {
        final feedTypes = [
          'Starter Feed',
          'Grower Feed',
          'Finisher Feed',
          'Supplements',
        ];

        for (final feedType in feedTypes) {
          final record = createTestFeedingRecord(feedType: feedType);
          final docId = await repository.addFeedingRecord(record);
          final data = mockDb.selectSingle(
            'feeding_records',
            where: {'id': docId},
          );
          expect(data!['feed_type'], feedType);
        }
      });
    });

    group('Units', () {
      test('should handle kilograms', () async {
        final record = createTestFeedingRecord(quantity: 25.5);

        final docId = await repository.addFeedingRecord(record);

        final data = mockDb.selectSingle(
          'feeding_records',
          where: {'id': docId},
        );
        expect(data!['quantity'], 25.5);
      });

      test('should handle grams converted to kg', () async {
        final record = createTestFeedingRecord(
          quantity: 0.5, // 500g as 0.5kg
        );

        final docId = await repository.addFeedingRecord(record);

        final data = mockDb.selectSingle(
          'feeding_records',
          where: {'id': docId},
        );
        expect(data!['quantity'], 0.5);
      });

      test('should handle large quantities', () async {
        final record = createTestFeedingRecord(
          feedType: 'Bulk Feed',
          quantity: 100.0,
        );

        final docId = await repository.addFeedingRecord(record);

        final data = mockDb.selectSingle(
          'feeding_records',
          where: {'id': docId},
        );
        expect(data!['quantity'], 100.0);
      });
    });
  });
}
