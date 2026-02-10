import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manage/providers/providers.dart';
import 'package:manage/models/health_record.dart';

void main() {
  group('DashboardStats', () {
    test('creates instance with all required fields', () {
      final stats = DashboardStats(
        totalAnimals: 100,
        healthyAnimals: 80,
        sickAnimals: 5,
        pregnantAnimals: 10,
        animalsInHeat: 5,
        maleCount: 40,
        femaleCount: 60,
      );

      expect(stats.totalAnimals, 100);
      expect(stats.healthyAnimals, 80);
      expect(stats.sickAnimals, 5);
      expect(stats.pregnantAnimals, 10);
      expect(stats.animalsInHeat, 5);
      expect(stats.maleCount, 40);
      expect(stats.femaleCount, 60);
    });

    test('can have zero values', () {
      final stats = DashboardStats(
        totalAnimals: 0,
        healthyAnimals: 0,
        sickAnimals: 0,
        pregnantAnimals: 0,
        animalsInHeat: 0,
        maleCount: 0,
        femaleCount: 0,
      );

      expect(stats.totalAnimals, 0);
      expect(stats.healthyAnimals, 0);
      expect(stats.maleCount, 0);
      expect(stats.femaleCount, 0);
    });

    test('male and female counts can sum to total', () {
      final stats = DashboardStats(
        totalAnimals: 100,
        healthyAnimals: 80,
        sickAnimals: 5,
        pregnantAnimals: 10,
        animalsInHeat: 5,
        maleCount: 40,
        femaleCount: 60,
      );

      expect(stats.maleCount + stats.femaleCount, stats.totalAnimals);
    });

    test('healthy and sick animals are subset of total', () {
      final stats = DashboardStats(
        totalAnimals: 100,
        healthyAnimals: 80,
        sickAnimals: 5,
        pregnantAnimals: 10,
        animalsInHeat: 5,
        maleCount: 40,
        femaleCount: 60,
      );

      expect(
        stats.healthyAnimals + stats.sickAnimals,
        lessThanOrEqualTo(stats.totalAnimals),
      );
    });
  });

  group('activeFarmIdProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('returns null when no user is authenticated', () {
      final farmId = container.read(activeFarmIdProvider);
      expect(farmId, isNull);
    });
  });

  group('Provider Type Verification', () {
    test('animalsProvider is a StreamProvider', () {
      expect(animalsProvider, isA<StreamProvider>());
    });

    test('femaleAnimalsProvider is a StreamProvider', () {
      expect(femaleAnimalsProvider, isA<StreamProvider>());
    });

    test('maleAnimalsProvider is a StreamProvider', () {
      expect(maleAnimalsProvider, isA<StreamProvider>());
    });

    test('feedingRecordsProvider is a StreamProvider', () {
      expect(feedingRecordsProvider, isA<StreamProvider>());
    });

    test('weightRecordsProvider is a StreamProvider', () {
      expect(weightRecordsProvider, isA<StreamProvider>());
    });

    test('breedingRecordsProvider is a StreamProvider', () {
      expect(breedingRecordsProvider, isA<StreamProvider>());
    });

    test('healthRecordsProvider is a StreamProvider', () {
      expect(healthRecordsProvider, isA<StreamProvider>());
    });

    test('transactionsProvider is a StreamProvider', () {
      expect(transactionsProvider, isA<StreamProvider>());
    });

    test('incomeTransactionsProvider is a StreamProvider', () {
      expect(incomeTransactionsProvider, isA<StreamProvider>());
    });

    test('expenseTransactionsProvider is a StreamProvider', () {
      expect(expenseTransactionsProvider, isA<StreamProvider>());
    });

    test('pregnantBreedingRecordsProvider is a StreamProvider', () {
      expect(pregnantBreedingRecordsProvider, isA<StreamProvider>());
    });

    test('animalsInHeatProvider is a StreamProvider', () {
      expect(animalsInHeatProvider, isA<StreamProvider>());
    });

    test('upcomingVaccinationsProvider is a StreamProvider', () {
      expect(upcomingVaccinationsProvider, isA<StreamProvider>());
    });

    test('pendingFollowUpsProvider is a StreamProvider', () {
      expect(pendingFollowUpsProvider, isA<StreamProvider>());
    });

    test('animalsInWithdrawalProvider is a StreamProvider', () {
      expect(animalsInWithdrawalProvider, isA<StreamProvider>());
    });
  });

  group('Family Provider Type Verification', () {
    test('animalByIdProvider can be called with an id', () {
      final provider = animalByIdProvider('test-id');
      expect(provider, isNotNull);
    });

    test('feedingRecordsForAnimalProvider can be called with an id', () {
      final provider = feedingRecordsForAnimalProvider('test-id');
      expect(provider, isNotNull);
    });

    test('weightRecordsForAnimalProvider can be called with an id', () {
      final provider = weightRecordsForAnimalProvider('test-id');
      expect(provider, isNotNull);
    });

    test('breedingRecordsForAnimalProvider can be called with an id', () {
      final provider = breedingRecordsForAnimalProvider('test-id');
      expect(provider, isNotNull);
    });

    test('healthRecordsForAnimalProvider can be called with an id', () {
      final provider = healthRecordsForAnimalProvider('test-id');
      expect(provider, isNotNull);
    });

    test('animalTransactionsProvider can be called with an id', () {
      final provider = animalTransactionsProvider('test-id');
      expect(provider, isNotNull);
    });

    test('animalHealthSummaryProvider can be called with an id', () {
      final provider = animalHealthSummaryProvider('test-id');
      expect(provider, isNotNull);
    });

    test('healthRecordsByTypeProvider can be called with a type', () {
      final provider = healthRecordsByTypeProvider(
        HealthRecordType.vaccination,
      );
      expect(provider, isNotNull);
    });
  });

  group('Computed Provider Type Verification', () {
    test('pregnantAnimalsCountProvider is a Provider', () {
      expect(pregnantAnimalsCountProvider, isA<Provider>());
    });

    test('dashboardStatsProvider is a Provider', () {
      expect(dashboardStatsProvider, isA<Provider>());
    });

    test('farmHealthStatsProvider is a FutureProvider', () {
      expect(farmHealthStatsProvider, isA<FutureProvider>());
    });

    test('financialSummaryProvider is a StreamProvider', () {
      expect(financialSummaryProvider, isA<StreamProvider>());
    });
  });

  group('Repository Provider Type Verification', () {
    test('animalRepositoryProvider is a Provider', () {
      expect(animalRepositoryProvider, isA<Provider>());
    });

    test('feedingRepositoryProvider is a Provider', () {
      expect(feedingRepositoryProvider, isA<Provider>());
    });

    test('weightRepositoryProvider is a Provider', () {
      expect(weightRepositoryProvider, isA<Provider>());
    });

    test('breedingRepositoryProvider is a Provider', () {
      expect(breedingRepositoryProvider, isA<Provider>());
    });

    test('healthRepositoryProvider is a Provider', () {
      expect(healthRepositoryProvider, isA<Provider>());
    });

    test('financialRepositoryProvider is a Provider', () {
      expect(financialRepositoryProvider, isA<Provider>());
    });
  });
}
