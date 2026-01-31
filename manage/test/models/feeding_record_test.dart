import 'package:flutter_test/flutter_test.dart';
import 'package:manage/models/feeding_record.dart';

void main() {
  group('FeedingRecord Model', () {
    late FeedingRecord feedingRecord;
    late DateTime feedingDate;
    late DateTime createdAt;

    setUp(() {
      feedingDate = DateTime(2026, 1, 10, 8, 0);
      createdAt = DateTime(2026, 1, 10, 8, 30);
      feedingRecord = FeedingRecord(
        id: 'feeding-001',
        farmId: 'farm-001',
        animalId: 'animal-001',
        date: feedingDate,
        feedType: 'Grower Feed',
        quantity: 2.5,
        notes: 'Morning feeding',
        createdAt: createdAt,
      );
    });

    test('should create a FeedingRecord instance with all properties', () {
      expect(feedingRecord.id, 'feeding-001');
      expect(feedingRecord.animalId, 'animal-001');
      expect(feedingRecord.date, feedingDate);
      expect(feedingRecord.feedType, 'Grower Feed');
      expect(feedingRecord.quantity, 2.5);
      expect(feedingRecord.notes, 'Morning feeding');
      expect(feedingRecord.createdAt, createdAt);
    });

    test('should create FeedingRecord without optional notes', () {
      final recordWithoutNotes = FeedingRecord(
        id: 'feeding-002',
        farmId: 'farm-001',
        animalId: 'animal-002',
        date: feedingDate,
        feedType: 'Starter Feed',
        quantity: 1.0,
        createdAt: createdAt,
      );

      expect(recordWithoutNotes.notes, isNull);
      expect(recordWithoutNotes.feedType, 'Starter Feed');
    });

    test('should convert to Supabase map correctly', () {
      final supabaseData = feedingRecord.toSupabase();

      expect(supabaseData['animal_id'], 'animal-001');
      expect(supabaseData['feed_type'], 'Grower Feed');
      expect(supabaseData['quantity'], 2.5);
      expect(supabaseData['notes'], 'Morning feeding');
      expect(supabaseData.containsKey('date'), isTrue);
      expect(supabaseData.containsKey('created_at'), isTrue);
    });

    test('should create a copy with modified properties', () {
      final updatedRecord = feedingRecord.copyWith(
        feedType: 'Finisher Feed',
        quantity: 3.0,
      );

      expect(updatedRecord.id, feedingRecord.id);
      expect(updatedRecord.animalId, feedingRecord.animalId);
      expect(updatedRecord.feedType, 'Finisher Feed');
      expect(updatedRecord.quantity, 3.0);
      // Original should remain unchanged
      expect(feedingRecord.feedType, 'Grower Feed');
      expect(feedingRecord.quantity, 2.5);
    });

    test('copyWith should preserve original values when not specified', () {
      final copied = feedingRecord.copyWith();

      expect(copied.id, feedingRecord.id);
      expect(copied.animalId, feedingRecord.animalId);
      expect(copied.date, feedingRecord.date);
      expect(copied.feedType, feedingRecord.feedType);
      expect(copied.quantity, feedingRecord.quantity);
      expect(copied.notes, feedingRecord.notes);
      expect(copied.createdAt, feedingRecord.createdAt);
    });

    test('should handle various feed types', () {
      final feedTypes = [
        'Starter Feed',
        'Grower Feed',
        'Finisher Feed',
        'Supplement',
      ];

      for (final feedType in feedTypes) {
        final record = FeedingRecord(
          id: 'test',
          farmId: 'farm-001',
          animalId: 'animal',
          date: feedingDate,
          feedType: feedType,
          quantity: 1.0,
          createdAt: createdAt,
        );
        expect(record.feedType, feedType);
      }
    });

    test('should handle decimal quantities correctly', () {
      final preciseRecord = FeedingRecord(
        id: 'feeding-003',
        farmId: 'farm-001',
        animalId: 'animal-003',
        date: feedingDate,
        feedType: 'Grower Feed',
        quantity: 2.75,
        createdAt: createdAt,
      );

      expect(preciseRecord.quantity, 2.75);
      expect(preciseRecord.toSupabase()['quantity'], 2.75);
    });
  });
}
