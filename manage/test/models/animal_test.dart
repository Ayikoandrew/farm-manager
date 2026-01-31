import 'package:flutter_test/flutter_test.dart';
import 'package:manage/models/animal.dart';

void main() {
  group('Animal Model', () {
    late Animal animal;
    late DateTime birthDate;
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 1, 10);
      birthDate = DateTime(2025, 6, 10); // 7 months ago
      animal = Animal(
        id: 'test-id-1',
        farmId: 'farm-001',
        tagId: 'PIG-001',
        species: AnimalType.pig,
        breed: 'Yorkshire',
        gender: Gender.female,
        birthDate: birthDate,
        currentWeight: 85.5,
        status: AnimalStatus.healthy,
        notes: 'Test animal',
        createdAt: now,
        updatedAt: now,
      );
    });

    test('should create an Animal instance with all properties', () {
      expect(animal.id, 'test-id-1');
      expect(animal.tagId, 'PIG-001');
      expect(animal.breed, 'Yorkshire');
      expect(animal.gender, Gender.female);
      expect(animal.birthDate, birthDate);
      expect(animal.currentWeight, 85.5);
      expect(animal.status, AnimalStatus.healthy);
      expect(animal.notes, 'Test animal');
    });

    test('should calculate ageInDays correctly', () {
      final testAnimal = Animal(
        id: 'test',
        farmId: 'farm-001',
        tagId: 'TEST-001',
        species: AnimalType.pig,
        breed: 'Test',
        gender: Gender.male,
        birthDate: DateTime.now().subtract(const Duration(days: 100)),
        currentWeight: 50.0,
        status: AnimalStatus.healthy,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(testAnimal.ageInDays, 100);
    });

    test('should format age in days when less than 30 days', () {
      final youngAnimal = Animal(
        id: 'young',
        farmId: 'farm-001',
        tagId: 'YOUNG-001',
        species: AnimalType.pig,
        breed: 'Yorkshire',
        gender: Gender.male,
        birthDate: DateTime.now().subtract(const Duration(days: 15)),
        currentWeight: 5.0,
        status: AnimalStatus.healthy,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(youngAnimal.ageFormatted, '15 days');
    });

    test('should format age in months when less than 365 days', () {
      final monthsOldAnimal = Animal(
        id: 'months',
        farmId: 'farm-001',
        tagId: 'MONTHS-001',
        species: AnimalType.pig,
        breed: 'Yorkshire',
        gender: Gender.female,
        birthDate: DateTime.now().subtract(const Duration(days: 90)),
        currentWeight: 30.0,
        status: AnimalStatus.healthy,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(monthsOldAnimal.ageFormatted, '3 months');
    });

    test('should format age in years and months when over 365 days', () {
      final oldAnimal = Animal(
        id: 'old',
        farmId: 'farm-001',
        tagId: 'OLD-001',
        species: AnimalType.pig,
        breed: 'Yorkshire',
        gender: Gender.male,
        birthDate: DateTime.now().subtract(const Duration(days: 450)),
        currentWeight: 150.0,
        status: AnimalStatus.healthy,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(oldAnimal.ageFormatted, contains('yr'));
    });

    test('should convert to Supabase map correctly', () {
      final supabaseData = animal.toSupabase();

      expect(supabaseData['tag_id'], 'PIG-001');
      expect(supabaseData['breed'], 'Yorkshire');
      expect(supabaseData['gender'], 'female');
      expect(supabaseData['current_weight'], 85.5);
      expect(supabaseData['status'], 'healthy');
      expect(supabaseData['notes'], 'Test animal');
    });

    test('should create a copy with modified properties', () {
      final updatedAnimal = animal.copyWith(
        currentWeight: 90.0,
        status: AnimalStatus.pregnant,
      );

      expect(updatedAnimal.id, animal.id);
      expect(updatedAnimal.tagId, animal.tagId);
      expect(updatedAnimal.currentWeight, 90.0);
      expect(updatedAnimal.status, AnimalStatus.pregnant);
      // Original should remain unchanged
      expect(animal.currentWeight, 85.5);
      expect(animal.status, AnimalStatus.healthy);
    });

    test('copyWith should preserve original values when not specified', () {
      final copied = animal.copyWith();

      expect(copied.id, animal.id);
      expect(copied.tagId, animal.tagId);
      expect(copied.breed, animal.breed);
      expect(copied.gender, animal.gender);
      expect(copied.birthDate, animal.birthDate);
      expect(copied.currentWeight, animal.currentWeight);
      expect(copied.status, animal.status);
      expect(copied.notes, animal.notes);
    });
  });

  group('AnimalStatus Enum', () {
    test('should have all expected values', () {
      expect(AnimalStatus.values.length, 6);
      expect(AnimalStatus.values, contains(AnimalStatus.healthy));
      expect(AnimalStatus.values, contains(AnimalStatus.sick));
      expect(AnimalStatus.values, contains(AnimalStatus.pregnant));
      expect(AnimalStatus.values, contains(AnimalStatus.nursing));
      expect(AnimalStatus.values, contains(AnimalStatus.sold));
      expect(AnimalStatus.values, contains(AnimalStatus.deceased));
    });
  });

  group('Gender Enum', () {
    test('should have male and female values', () {
      expect(Gender.values.length, 2);
      expect(Gender.values, contains(Gender.male));
      expect(Gender.values, contains(Gender.female));
    });
  });
}
