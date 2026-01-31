import 'package:flutter_test/flutter_test.dart';
import 'package:manage/models/breeding_record.dart';

void main() {
  group('BreedingRecord Model', () {
    late BreedingRecord breedingRecord;
    late DateTime heatDate;
    late DateTime breedingDate;
    late DateTime expectedFarrowDate;
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 1, 10);
      heatDate = DateTime(2025, 10, 1);
      breedingDate = DateTime(2025, 10, 3);
      expectedFarrowDate = breedingDate.add(
        const Duration(days: BreedingRecord.gestationDays),
      );

      breedingRecord = BreedingRecord(
        id: 'breeding-001',
        farmId: 'farm-001',
        animalId: 'animal-001',
        sireId: 'sire-001',
        heatDate: heatDate,
        breedingDate: breedingDate,
        expectedFarrowDate: expectedFarrowDate,
        actualFarrowDate: null,
        status: BreedingStatus.pregnant,
        litterSize: null,
        notes: 'First breeding',
        createdAt: now,
        updatedAt: now,
      );
    });

    test('should create a BreedingRecord instance with all properties', () {
      expect(breedingRecord.id, 'breeding-001');
      expect(breedingRecord.animalId, 'animal-001');
      expect(breedingRecord.sireId, 'sire-001');
      expect(breedingRecord.heatDate, heatDate);
      expect(breedingRecord.breedingDate, breedingDate);
      expect(breedingRecord.expectedFarrowDate, expectedFarrowDate);
      expect(breedingRecord.status, BreedingStatus.pregnant);
      expect(breedingRecord.notes, 'First breeding');
    });

    test('gestationDays constant should be 114', () {
      expect(BreedingRecord.gestationDays, 114);
    });

    test('should calculate daysPregnant when status is pregnant', () {
      // Create a record with a known breeding date
      final daysAgo = 50;
      final pregnantRecord = BreedingRecord(
        id: 'test',
        farmId: 'farm-001',
        animalId: 'animal',
        heatDate: DateTime.now().subtract(Duration(days: daysAgo + 2)),
        breedingDate: DateTime.now().subtract(Duration(days: daysAgo)),
        status: BreedingStatus.pregnant,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(pregnantRecord.daysPregnant, daysAgo);
    });

    test('daysPregnant should return null when status is not pregnant', () {
      final inHeatRecord = BreedingRecord(
        id: 'test',
        farmId: 'farm-001',
        animalId: 'animal',
        heatDate: DateTime.now(),
        status: BreedingStatus.inHeat,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(inHeatRecord.daysPregnant, isNull);
    });

    test('daysPregnant should return null when breedingDate is null', () {
      final noBreedingDateRecord = BreedingRecord(
        id: 'test',
        farmId: 'farm-001',
        animalId: 'animal',
        heatDate: DateTime.now(),
        breedingDate: null,
        status: BreedingStatus.pregnant,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(noBreedingDateRecord.daysPregnant, isNull);
    });

    test('should calculate daysUntilFarrowing correctly', () {
      final daysUntil = 30;
      final pregnantRecord = BreedingRecord(
        id: 'test',
        farmId: 'farm-001',
        animalId: 'animal',
        heatDate: DateTime.now().subtract(const Duration(days: 86)),
        breedingDate: DateTime.now().subtract(const Duration(days: 84)),
        expectedFarrowDate: DateTime.now().add(Duration(days: daysUntil)),
        status: BreedingStatus.pregnant,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Use closeTo to handle timing edge cases
      expect(pregnantRecord.daysUntilFarrowing, closeTo(daysUntil, 1));
    });

    test('daysUntilFarrowing should return null when not pregnant', () {
      final bredRecord = BreedingRecord(
        id: 'test',
        farmId: 'farm-001',
        animalId: 'animal',
        heatDate: DateTime.now(),
        expectedFarrowDate: DateTime.now().add(const Duration(days: 100)),
        status: BreedingStatus.bred,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(bredRecord.daysUntilFarrowing, isNull);
    });

    test('should convert to Supabase map correctly', () {
      final supabaseData = breedingRecord.toSupabase();

      expect(supabaseData['animal_id'], 'animal-001');
      expect(supabaseData['sire_id'], 'sire-001');
      expect(supabaseData['status'], 'pregnant');
      expect(supabaseData['notes'], 'First breeding');
      expect(supabaseData.containsKey('heat_date'), isTrue);
      expect(supabaseData.containsKey('breeding_date'), isTrue);
      expect(supabaseData.containsKey('expected_farrow_date'), isTrue);
    });

    test('should create a copy with modified properties', () {
      final actualFarrow = DateTime(2026, 1, 25);
      final updatedRecord = breedingRecord.copyWith(
        status: BreedingStatus.farrowed,
        actualFarrowDate: actualFarrow,
        litterSize: 12,
      );

      expect(updatedRecord.status, BreedingStatus.farrowed);
      expect(updatedRecord.actualFarrowDate, actualFarrow);
      expect(updatedRecord.litterSize, 12);
      // Original should remain unchanged
      expect(breedingRecord.status, BreedingStatus.pregnant);
      expect(breedingRecord.actualFarrowDate, isNull);
      expect(breedingRecord.litterSize, isNull);
    });

    test('copyWith should preserve original values when not specified', () {
      final copied = breedingRecord.copyWith();

      expect(copied.id, breedingRecord.id);
      expect(copied.animalId, breedingRecord.animalId);
      expect(copied.sireId, breedingRecord.sireId);
      expect(copied.heatDate, breedingRecord.heatDate);
      expect(copied.breedingDate, breedingRecord.breedingDate);
      expect(copied.status, breedingRecord.status);
    });
  });

  group('BreedingStatus Enum', () {
    test('should have all expected values', () {
      expect(BreedingStatus.values.length, 5);
      expect(BreedingStatus.values, contains(BreedingStatus.inHeat));
      expect(BreedingStatus.values, contains(BreedingStatus.bred));
      expect(BreedingStatus.values, contains(BreedingStatus.pregnant));
      expect(BreedingStatus.values, contains(BreedingStatus.farrowed));
      expect(BreedingStatus.values, contains(BreedingStatus.failed));
    });
  });
}
