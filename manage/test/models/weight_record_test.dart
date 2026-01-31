import 'package:flutter_test/flutter_test.dart';
import 'package:manage/models/weight_record.dart';

void main() {
  group('WeightRecord Model', () {
    late WeightRecord weightRecord;
    late DateTime recordDate;
    late DateTime createdAt;

    setUp(() {
      recordDate = DateTime(2026, 1, 10);
      createdAt = DateTime(2026, 1, 10, 10, 30);
      weightRecord = WeightRecord(
        id: 'weight-001',
        farmId: 'farm-001',
        animalId: 'animal-001',
        date: recordDate,
        weight: 85.5,
        notes: 'Morning weigh-in',
        createdAt: createdAt,
      );
    });

    test('should create a WeightRecord instance with all properties', () {
      expect(weightRecord.id, 'weight-001');
      expect(weightRecord.animalId, 'animal-001');
      expect(weightRecord.date, recordDate);
      expect(weightRecord.weight, 85.5);
      expect(weightRecord.notes, 'Morning weigh-in');
      expect(weightRecord.createdAt, createdAt);
    });

    test('should create WeightRecord without optional notes', () {
      final recordWithoutNotes = WeightRecord(
        id: 'weight-002',
        farmId: 'farm-001',
        animalId: 'animal-002',
        date: recordDate,
        weight: 90.0,
        createdAt: createdAt,
      );

      expect(recordWithoutNotes.notes, isNull);
      expect(recordWithoutNotes.weight, 90.0);
    });

    test('should convert to Supabase map correctly', () {
      final supabaseData = weightRecord.toSupabase();

      expect(supabaseData['animal_id'], 'animal-001');
      expect(supabaseData['weight'], 85.5);
      expect(supabaseData['notes'], 'Morning weigh-in');
      expect(supabaseData.containsKey('date'), isTrue);
      expect(supabaseData.containsKey('created_at'), isTrue);
    });

    test('should create a copy with modified properties', () {
      final updatedRecord = weightRecord.copyWith(
        weight: 90.0,
        notes: 'Updated weight',
      );

      expect(updatedRecord.id, weightRecord.id);
      expect(updatedRecord.animalId, weightRecord.animalId);
      expect(updatedRecord.weight, 90.0);
      expect(updatedRecord.notes, 'Updated weight');
      // Original should remain unchanged
      expect(weightRecord.weight, 85.5);
      expect(weightRecord.notes, 'Morning weigh-in');
    });

    test('copyWith should preserve original values when not specified', () {
      final copied = weightRecord.copyWith();

      expect(copied.id, weightRecord.id);
      expect(copied.animalId, weightRecord.animalId);
      expect(copied.date, weightRecord.date);
      expect(copied.weight, weightRecord.weight);
      expect(copied.notes, weightRecord.notes);
      expect(copied.createdAt, weightRecord.createdAt);
    });

    test('should handle decimal weights correctly', () {
      final preciseWeight = WeightRecord(
        id: 'weight-003',
        farmId: 'farm-001',
        animalId: 'animal-003',
        date: recordDate,
        weight: 85.75,
        createdAt: createdAt,
      );

      expect(preciseWeight.weight, 85.75);
      expect(preciseWeight.toSupabase()['weight'], 85.75);
    });
  });
}
