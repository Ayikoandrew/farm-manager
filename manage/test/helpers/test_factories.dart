/// Test helpers and factory functions for creating test data
library;

import 'package:manage/models/animal.dart';
import 'package:manage/models/breeding_record.dart';
import 'package:manage/models/feeding_record.dart';
import 'package:manage/models/health_record.dart';
import 'package:manage/models/weight_record.dart';
import 'package:manage/models/transaction.dart';
import 'package:manage/models/user.dart';

/// Factory for creating test Animal instances
class TestAnimalFactory {
  static int _counter = 0;

  static Animal create({
    String? id,
    String farmId = 'test-farm-1',
    String? tagId,
    String? name,
    AnimalType species = AnimalType.pig,
    String breed = 'Large White',
    Gender gender = Gender.female,
    DateTime? birthDate,
    double? currentWeight = 100.0,
    AnimalStatus status = AnimalStatus.healthy,
    String? notes,
    String? motherId,
    String? fatherId,
  }) {
    _counter++;
    final now = DateTime.now();
    return Animal(
      id: id ?? 'animal-$_counter',
      farmId: farmId,
      tagId: tagId ?? 'TAG-${_counter.toString().padLeft(4, '0')}',
      name: name,
      species: species,
      breed: breed,
      gender: gender,
      birthDate: birthDate ?? DateTime(2023, 6, 1),
      currentWeight: currentWeight,
      status: status,
      notes: notes,
      motherId: motherId,
      fatherId: fatherId,
      createdAt: now,
      updatedAt: now,
    );
  }

  static Animal createMale({
    String? id,
    String farmId = 'test-farm-1',
    String? tagId,
    String? name,
  }) {
    return create(
      id: id,
      farmId: farmId,
      tagId: tagId,
      name: name,
      gender: Gender.male,
    );
  }

  static Animal createFemale({
    String? id,
    String farmId = 'test-farm-1',
    String? tagId,
    String? name,
  }) {
    return create(
      id: id,
      farmId: farmId,
      tagId: tagId,
      name: name,
      gender: Gender.female,
    );
  }

  static Animal createPregnant({
    String? id,
    String farmId = 'test-farm-1',
    String? tagId,
    String? name,
  }) {
    return create(
      id: id,
      farmId: farmId,
      tagId: tagId,
      name: name,
      gender: Gender.female,
      status: AnimalStatus.pregnant,
    );
  }

  static Animal createSick({
    String? id,
    String farmId = 'test-farm-1',
    String? tagId,
    String? name,
  }) {
    return create(
      id: id,
      farmId: farmId,
      tagId: tagId,
      name: name,
      status: AnimalStatus.sick,
    );
  }

  static void resetCounter() => _counter = 0;
}

/// Factory for creating test WeightRecord instances
class TestWeightRecordFactory {
  static int _counter = 0;

  static WeightRecord create({
    String? id,
    String farmId = 'test-farm-1',
    String animalId = 'animal-1',
    double weight = 100.0,
    DateTime? date,
    String? notes,
  }) {
    _counter++;
    final now = DateTime.now();
    return WeightRecord(
      id: id ?? 'weight-$_counter',
      farmId: farmId,
      animalId: animalId,
      weight: weight,
      date: date ?? now,
      notes: notes,
      createdAt: now,
    );
  }

  static void resetCounter() => _counter = 0;
}

/// Factory for creating test FeedingRecord instances
class TestFeedingRecordFactory {
  static int _counter = 0;

  static FeedingRecord create({
    String? id,
    String farmId = 'test-farm-1',
    String animalId = 'animal-1',
    String feedType = 'Grower',
    double quantity = 2.5,
    DateTime? date,
    String? notes,
  }) {
    _counter++;
    final now = DateTime.now();
    return FeedingRecord(
      id: id ?? 'feeding-$_counter',
      farmId: farmId,
      animalId: animalId,
      feedType: feedType,
      quantity: quantity,
      date: date ?? now,
      notes: notes,
      createdAt: now,
    );
  }

  static void resetCounter() => _counter = 0;
}

/// Factory for creating test BreedingRecord instances
class TestBreedingRecordFactory {
  static int _counter = 0;

  static BreedingRecord create({
    String? id,
    String farmId = 'test-farm-1',
    String animalId = 'animal-1',
    String? sireId,
    BreedingStatus status = BreedingStatus.inHeat,
    DateTime? heatDate,
    DateTime? breedingDate,
    DateTime? expectedFarrowDate,
    DateTime? actualFarrowDate,
    int? litterSize,
    String? notes,
  }) {
    _counter++;
    final now = DateTime.now();
    return BreedingRecord(
      id: id ?? 'breeding-$_counter',
      farmId: farmId,
      animalId: animalId,
      sireId: sireId,
      status: status,
      heatDate: heatDate ?? now,
      breedingDate: breedingDate,
      expectedFarrowDate: expectedFarrowDate,
      actualFarrowDate: actualFarrowDate,
      litterSize: litterSize,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  static BreedingRecord createPregnant({
    String? id,
    String farmId = 'test-farm-1',
    String animalId = 'animal-1',
    String? sireId,
  }) {
    final now = DateTime.now();
    final heatDate = now.subtract(const Duration(days: 63));
    final breedingDate = now.subtract(const Duration(days: 60));
    final expectedFarrowDate = breedingDate.add(
      const Duration(days: BreedingRecord.gestationDays),
    );

    return create(
      id: id,
      farmId: farmId,
      animalId: animalId,
      sireId: sireId,
      status: BreedingStatus.pregnant,
      heatDate: heatDate,
      breedingDate: breedingDate,
      expectedFarrowDate: expectedFarrowDate,
    );
  }

  static void resetCounter() => _counter = 0;
}

/// Factory for creating test HealthRecord instances
class TestHealthRecordFactory {
  static int _counter = 0;

  static HealthRecord create({
    String? id,
    String farmId = 'test-farm-1',
    String animalId = 'animal-1',
    HealthRecordType type = HealthRecordType.checkup,
    String title = 'Routine Checkup',
    String? description,
    DateTime? date,
    HealthStatus status = HealthStatus.completed,
    String? veterinarianName,
    double? cost,
    DateTime? followUpDate,
    String? diagnosis,
    String? treatment,
  }) {
    _counter++;
    final now = DateTime.now();
    return HealthRecord(
      id: id ?? 'health-$_counter',
      farmId: farmId,
      animalId: animalId,
      type: type,
      title: title,
      description: description,
      date: date ?? now,
      status: status,
      veterinarianName: veterinarianName,
      cost: cost,
      followUpDate: followUpDate,
      diagnosis: diagnosis,
      treatment: treatment,
      recordedBy: 'test-user',
      createdAt: now,
      updatedAt: now,
    );
  }

  static HealthRecord createVaccination({
    String? id,
    String farmId = 'test-farm-1',
    String animalId = 'animal-1',
    String vaccineName = 'Test Vaccine',
    DateTime? nextDueDate,
  }) {
    return create(
      id: id,
      farmId: farmId,
      animalId: animalId,
      type: HealthRecordType.vaccination,
      title: 'Vaccination: $vaccineName',
    );
  }

  static void resetCounter() => _counter = 0;
}

/// Factory for creating test Transaction instances
class TestTransactionFactory {
  static int _counter = 0;

  static Transaction create({
    String? id,
    String farmId = 'test-farm-1',
    TransactionType type = TransactionType.expense,
    String category = 'feed',
    double amount = 50000.0,
    DateTime? date,
    String description = 'Test transaction',
    String? animalId,
    PaymentMethod? paymentMethod,
    String? notes,
  }) {
    _counter++;
    final now = DateTime.now();
    return Transaction(
      id: id ?? 'transaction-$_counter',
      farmId: farmId,
      type: type,
      category: category,
      amount: amount,
      date: date ?? now,
      description: description,
      animalId: animalId,
      paymentMethod: paymentMethod,
      notes: notes,
      recordedBy: 'test-user',
      createdAt: now,
      updatedAt: now,
    );
  }

  static Transaction createIncome({
    String? id,
    String farmId = 'test-farm-1',
    double amount = 500000.0,
    String category = 'animalSale',
    String description = 'Animal sale',
  }) {
    return create(
      id: id,
      farmId: farmId,
      type: TransactionType.income,
      category: category,
      amount: amount,
      description: description,
    );
  }

  static Transaction createExpense({
    String? id,
    String farmId = 'test-farm-1',
    double amount = 50000.0,
    String category = 'feed',
    String description = 'Feed purchase',
  }) {
    return create(
      id: id,
      farmId: farmId,
      type: TransactionType.expense,
      category: category,
      amount: amount,
      description: description,
    );
  }

  static void resetCounter() => _counter = 0;
}

/// Factory for creating test AppUser instances
class TestAppUserFactory {
  static int _counter = 0;

  static AppUser create({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    List<FarmMembership>? farms,
    String? activeFarmId,
  }) {
    _counter++;
    final now = DateTime.now();
    return AppUser(
      id: id ?? 'user-$_counter',
      email: email ?? 'user$_counter@test.com',
      displayName: displayName ?? 'Test User $_counter',
      photoUrl: photoUrl,
      phoneNumber: phoneNumber,
      farms: farms ?? [],
      activeFarmId: activeFarmId,
      createdAt: now,
      lastLoginAt: now,
    );
  }

  static AppUser createWithFarm({
    String? id,
    String? email,
    String farmId = 'test-farm-1',
    String farmName = 'Test Farm',
    UserRole role = UserRole.owner,
  }) {
    final userId = id ?? 'user-${++_counter}';
    final membership = FarmMembership(
      farmId: farmId,
      farmName: farmName,
      role: role,
      joinedAt: DateTime.now(),
    );
    return create(
      id: userId,
      email: email,
      farms: [membership],
      activeFarmId: farmId,
    );
  }

  static void resetCounter() => _counter = 0;
}

/// Reset all factory counters (call in setUp)
void resetAllFactories() {
  TestAnimalFactory.resetCounter();
  TestWeightRecordFactory.resetCounter();
  TestFeedingRecordFactory.resetCounter();
  TestBreedingRecordFactory.resetCounter();
  TestHealthRecordFactory.resetCounter();
  TestTransactionFactory.resetCounter();
  TestAppUserFactory.resetCounter();
}
