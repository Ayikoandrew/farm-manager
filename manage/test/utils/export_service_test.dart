import 'package:flutter_test/flutter_test.dart';
import 'package:manage/utils/export_service.dart';
import 'package:manage/utils/currency_utils.dart';
import 'package:manage/models/models.dart';

void main() {
  late ExportService exportService;
  late CurrencyFormatter currencyFormatter;

  setUp(() {
    final config = CurrencyConfig.fromCurrency(Currency.ugx);
    currencyFormatter = CurrencyFormatter(config);
    exportService = ExportService(
      currencyFormatter: currencyFormatter,
      farmName: 'Test Farm',
    );
  });

  group('ExportService Initialization', () {
    test('creates instance with required parameters', () {
      expect(exportService, isNotNull);
    });

    test('can create with different currencies', () {
      final usdConfig = CurrencyConfig.fromCurrency(Currency.usd);
      final usdFormatter = CurrencyFormatter(usdConfig);
      final usdService = ExportService(
        currencyFormatter: usdFormatter,
        farmName: 'USD Farm',
      );
      expect(usdService, isNotNull);
    });

    test('can create with EUR currency', () {
      final eurConfig = CurrencyConfig.fromCurrency(Currency.eur);
      final eurFormatter = CurrencyFormatter(eurConfig);
      final eurService = ExportService(
        currencyFormatter: eurFormatter,
        farmName: 'EUR Farm',
      );
      expect(eurService, isNotNull);
    });
  });

  group('Empty List CSV Generation', () {
    test('generateInventoryCsv generates headers for empty list', () {
      final csv = exportService.generateInventoryCsv([]);

      expect(csv, contains('Tag ID'));
      expect(csv, contains('Breed'));
      expect(csv, contains('Gender'));
      expect(csv, contains('Status'));
      expect(csv, contains('Birth Date'));
      expect(csv, contains('Age'));
      expect(csv, contains('Current Weight'));
      expect(csv, contains('Notes'));
    });

    test('generateFinancialCsv generates headers for empty list', () {
      final csv = exportService.generateFinancialCsv([]);

      expect(csv, contains('Date'));
      expect(csv, contains('Type'));
      expect(csv, contains('Category'));
      expect(csv, contains('Amount'));
      expect(csv, contains('Description'));
    });

    test('generateHealthCsv generates headers for empty list', () {
      final csv = exportService.generateHealthCsv([]);

      expect(csv, contains('Date'));
      expect(csv, contains('Type'));
      expect(csv, contains('Title'));
      expect(csv, contains('Status'));
    });

    test('generateBreedingCsv generates headers for empty list', () {
      final csv = exportService.generateBreedingCsv([]);

      expect(csv, contains('Heat Date'));
      expect(csv, contains('Status'));
    });

    test('generateGrowthCsv generates headers for empty list', () {
      final csv = exportService.generateGrowthCsv([], {});

      expect(csv, contains('Animal Tag ID'));
      expect(csv, contains('Animal Breed'));
      expect(csv, contains('Date'));
      expect(csv, contains('Weight'));
    });
  });

  group('Animal CSV Generation', () {
    test('generates CSV with animal data', () {
      final animals = [
        Animal(
          id: '1',
          farmId: 'farm-1',
          tagId: 'COW-001',
          species: AnimalType.cattle,
          breed: 'Holstein',
          gender: Gender.female,
          birthDate: DateTime(2022, 1, 15),
          currentWeight: 450.5,
          status: AnimalStatus.healthy,
          notes: 'Good milker',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final csv = exportService.generateInventoryCsv(animals);

      expect(csv, contains('COW-001'));
      expect(csv, contains('Holstein'));
      expect(csv, contains('female'));
      expect(csv, contains('healthy'));
      expect(csv, contains('450.5'));
      expect(csv, contains('Good milker'));
    });

    test('generates CSV for multiple animals', () {
      final animals = [
        Animal(
          id: '1',
          farmId: 'farm-1',
          tagId: 'COW-001',
          species: AnimalType.cattle,
          breed: 'Holstein',
          gender: Gender.female,
          birthDate: DateTime(2022, 1, 15),
          currentWeight: 450.0,
          status: AnimalStatus.healthy,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Animal(
          id: '2',
          farmId: 'farm-1',
          tagId: 'COW-002',
          species: AnimalType.cattle,
          breed: 'Jersey',
          gender: Gender.male,
          birthDate: DateTime(2023, 3, 20),
          currentWeight: 380.0,
          status: AnimalStatus.sick,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final csv = exportService.generateInventoryCsv(animals);

      expect(csv, contains('COW-001'));
      expect(csv, contains('COW-002'));
      expect(csv, contains('Holstein'));
      expect(csv, contains('Jersey'));
    });

    test('handles empty notes', () {
      final animals = [
        Animal(
          id: '1',
          farmId: 'farm-1',
          tagId: 'PIG-001',
          species: AnimalType.pig,
          breed: 'Large White',
          gender: Gender.female,
          birthDate: DateTime(2023, 6, 1),
          currentWeight: 120.0,
          status: AnimalStatus.healthy,
          notes: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final csv = exportService.generateInventoryCsv(animals);

      expect(csv, contains('PIG-001'));
      expect(csv, isNotEmpty);
    });

    test('formats birth date correctly', () {
      final animals = [
        Animal(
          id: '1',
          farmId: 'farm-1',
          tagId: 'SHEEP-001',
          species: AnimalType.sheep,
          breed: 'Merino',
          gender: Gender.female,
          birthDate: DateTime(2023, 12, 25),
          currentWeight: 65.0,
          status: AnimalStatus.healthy,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final csv = exportService.generateInventoryCsv(animals);

      expect(csv, contains('2023-12-25'));
    });
  });

  group('Empty PDF Generation', () {
    test('generateInventoryPdf handles empty list', () async {
      final pdf = await exportService.generateInventoryPdf([]);
      expect(pdf, isNotEmpty);
      expect(pdf.length, greaterThan(100));
    });

    test('generateHealthPdf handles empty list', () async {
      final pdf = await exportService.generateHealthPdf([]);
      expect(pdf, isNotEmpty);
    });

    test('generateBreedingPdf handles empty list', () async {
      final pdf = await exportService.generateBreedingPdf([]);
      expect(pdf, isNotEmpty);
    });

    test('generateGrowthPdf handles empty data', () async {
      final pdf = await exportService.generateGrowthPdf([], {});
      expect(pdf, isNotEmpty);
    });
  });

  group('Animal PDF Generation', () {
    test('generateInventoryPdf returns Uint8List with data', () async {
      final animals = [
        Animal(
          id: '1',
          farmId: 'farm-1',
          tagId: 'COW-001',
          species: AnimalType.cattle,
          breed: 'Holstein',
          gender: Gender.female,
          birthDate: DateTime(2022, 1, 15),
          currentWeight: 450.0,
          status: AnimalStatus.healthy,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final pdf = await exportService.generateInventoryPdf(animals);

      expect(pdf, isNotEmpty);
      expect(pdf.length, greaterThan(0));
    });
  });

  group('Empty Excel Generation', () {
    test('generateInventoryExcel handles empty list', () {
      final excel = exportService.generateInventoryExcel([]);
      expect(excel, isNotEmpty);
    });

    test('generateFinancialExcel handles empty list', () {
      final excel = exportService.generateFinancialExcel([]);
      expect(excel, isNotEmpty);
    });

    test('generateHealthExcel handles empty list', () {
      final excel = exportService.generateHealthExcel([]);
      expect(excel, isNotEmpty);
    });

    test('generateBreedingExcel handles empty list', () {
      final excel = exportService.generateBreedingExcel([]);
      expect(excel, isNotEmpty);
    });

    test('generateGrowthExcel handles empty data', () {
      final excel = exportService.generateGrowthExcel([], {});
      expect(excel, isNotEmpty);
    });
  });

  group('Animal Excel Generation', () {
    test('generateInventoryExcel returns Uint8List with data', () {
      final animals = [
        Animal(
          id: '1',
          farmId: 'farm-1',
          tagId: 'COW-001',
          species: AnimalType.cattle,
          breed: 'Holstein',
          gender: Gender.female,
          birthDate: DateTime(2022, 1, 15),
          currentWeight: 450.0,
          status: AnimalStatus.healthy,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final excel = exportService.generateInventoryExcel(animals);

      expect(excel, isNotEmpty);
    });
  });

  group('Empty JSON Generation', () {
    test('generateInventoryJson handles empty list', () {
      final json = exportService.generateInventoryJson([]);
      expect(json, isNotEmpty);
    });

    test('generateHealthJson handles empty list', () {
      final json = exportService.generateHealthJson([]);
      expect(json, isNotEmpty);
    });

    test('generateBreedingJson handles empty list', () {
      final json = exportService.generateBreedingJson([]);
      expect(json, isNotEmpty);
    });

    test('generateGrowthJson handles empty data', () {
      final json = exportService.generateGrowthJson([], {});
      expect(json, isNotEmpty);
    });
  });

  group('Animal JSON Generation', () {
    test('generateInventoryJson returns valid JSON string', () {
      final animals = [
        Animal(
          id: '1',
          farmId: 'farm-1',
          tagId: 'COW-001',
          species: AnimalType.cattle,
          breed: 'Holstein',
          gender: Gender.female,
          birthDate: DateTime(2022, 1, 15),
          currentWeight: 450.0,
          status: AnimalStatus.healthy,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final json = exportService.generateInventoryJson(animals);

      expect(json, isNotEmpty);
      expect(json, contains('COW-001'));
      expect(json, contains('Holstein'));
    });
  });

  group('Breeding Record CSV', () {
    test('generates CSV with breeding record', () {
      final records = <BreedingRecord>[
        BreedingRecord(
          id: '1',
          farmId: 'farm-1',
          animalId: 'animal-1',
          heatDate: DateTime(2024, 1, 10),
          status: BreedingStatus.pregnant,
          breedingDate: DateTime(2024, 1, 12),
          sireId: 'boar-1',
          expectedFarrowDate: DateTime(2024, 5, 5),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final csv = exportService.generateBreedingCsv(records);

      expect(csv, contains('animal-1'));
      expect(csv, contains('pregnant'));
      expect(csv, contains('boar-1'));
    });
  });

  group('Breeding Record PDF', () {
    test('generates PDF with breeding record', () async {
      final records = <BreedingRecord>[
        BreedingRecord(
          id: '1',
          farmId: 'farm-1',
          animalId: 'animal-1',
          heatDate: DateTime(2024, 1, 10),
          status: BreedingStatus.pregnant,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final pdf = await exportService.generateBreedingPdf(records);

      expect(pdf, isNotEmpty);
    });
  });

  group('Growth/Weight Data', () {
    test('generates growth CSV with animal and weight data', () {
      final animals = [
        Animal(
          id: 'animal-1',
          farmId: 'farm-1',
          tagId: 'PIG-001',
          species: AnimalType.pig,
          breed: 'Large White',
          gender: Gender.male,
          birthDate: DateTime(2023, 6, 1),
          currentWeight: 100.0,
          status: AnimalStatus.healthy,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final weightsByAnimal = <String, List<WeightRecord>>{
        'animal-1': [
          WeightRecord(
            id: '1',
            farmId: 'farm-1',
            animalId: 'animal-1',
            weight: 85.5,
            date: DateTime(2024, 3, 15),
            notes: 'Normal growth',
            createdAt: DateTime.now(),
          ),
          WeightRecord(
            id: '2',
            farmId: 'farm-1',
            animalId: 'animal-1',
            weight: 75.0,
            date: DateTime(2024, 2, 15),
            createdAt: DateTime.now(),
          ),
        ],
      };

      final csv = exportService.generateGrowthCsv(animals, weightsByAnimal);

      expect(csv, contains('PIG-001'));
      expect(csv, contains('Large White'));
      expect(csv, contains('85.5'));
      expect(csv, contains('75.0'));
    });

    test('handles animals with no weight records', () {
      final animals = [
        Animal(
          id: 'animal-1',
          farmId: 'farm-1',
          tagId: 'COW-001',
          species: AnimalType.cattle,
          breed: 'Holstein',
          gender: Gender.female,
          birthDate: DateTime(2022, 1, 15),
          currentWeight: 450.0,
          status: AnimalStatus.healthy,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final csv = exportService.generateGrowthCsv(
        animals,
        <String, List<WeightRecord>>{},
      );

      // Should only have headers
      expect(csv, contains('Animal Tag ID'));
      expect(csv, isNot(contains('COW-001')));
    });
  });

  group('Growth PDF Generation', () {
    test('generates growth PDF with data', () async {
      final animals = [
        Animal(
          id: 'animal-1',
          farmId: 'farm-1',
          tagId: 'PIG-001',
          species: AnimalType.pig,
          breed: 'Large White',
          gender: Gender.male,
          birthDate: DateTime(2023, 6, 1),
          currentWeight: 100.0,
          status: AnimalStatus.healthy,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final weightsByAnimal = <String, List<WeightRecord>>{
        'animal-1': [
          WeightRecord(
            id: '1',
            farmId: 'farm-1',
            animalId: 'animal-1',
            weight: 100.0,
            date: DateTime(2024, 3, 1),
            createdAt: DateTime.now(),
          ),
          WeightRecord(
            id: '2',
            farmId: 'farm-1',
            animalId: 'animal-1',
            weight: 80.0,
            date: DateTime(2024, 1, 1),
            createdAt: DateTime.now(),
          ),
        ],
      };

      final pdf = await exportService.generateGrowthPdf(
        animals,
        weightsByAnimal,
      );

      expect(pdf, isNotEmpty);
    });
  });

  group('Transaction CSV Generation', () {
    test('generates CSV with transaction data', () {
      final transactions = [
        Transaction(
          id: '1',
          farmId: 'farm-1',
          date: DateTime(2024, 1, 15),
          type: TransactionType.income,
          category: 'Animal Sales',
          amount: 1500000.0,
          description: 'Sold pig',
          recordedBy: 'test-user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final csv = exportService.generateFinancialCsv(transactions);

      expect(csv, contains('Animal Sales'));
      expect(csv, contains('income'));
      expect(csv, contains('Sold pig'));
    });

    test('generates CSV for multiple transactions', () {
      final transactions = [
        Transaction(
          id: '1',
          farmId: 'farm-1',
          date: DateTime(2024, 1, 15),
          type: TransactionType.income,
          category: 'Animal Sales',
          amount: 1500000.0,
          description: 'Sold pig',
          recordedBy: 'test-user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          id: '2',
          farmId: 'farm-1',
          date: DateTime(2024, 1, 16),
          type: TransactionType.expense,
          category: 'Feed',
          amount: 200000.0,
          description: 'Bought pig feed',
          recordedBy: 'test-user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final csv = exportService.generateFinancialCsv(transactions);

      expect(csv, contains('Animal Sales'));
      expect(csv, contains('Feed'));
      expect(csv, contains('income'));
      expect(csv, contains('expense'));
    });
  });

  group('Financial PDF Generation', () {
    test('generateFinancialPdf handles empty list', () async {
      final summary = FinancialSummary(
        totalIncome: 0,
        totalExpenses: 0,
        netProfit: 0,
        incomeByCategory: {},
        expensesByCategory: {},
        transactionCount: 0,
      );

      final pdf = await exportService.generateFinancialPdf(
        summary: summary,
        transactions: [],
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );
      expect(pdf, isNotEmpty);
    });

    test('generateFinancialPdf returns Uint8List with data', () async {
      final transactions = [
        Transaction(
          id: '1',
          farmId: 'farm-1',
          date: DateTime(2024, 1, 15),
          type: TransactionType.income,
          category: 'Animal Sales',
          amount: 1500000.0,
          description: 'Sold pig',
          recordedBy: 'test-user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final summary = FinancialSummary(
        totalIncome: 1500000.0,
        totalExpenses: 0,
        netProfit: 1500000.0,
        incomeByCategory: {'Animal Sales': 1500000.0},
        expensesByCategory: {},
        transactionCount: 1,
      );

      final pdf = await exportService.generateFinancialPdf(
        summary: summary,
        transactions: transactions,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );

      expect(pdf, isNotEmpty);
    });
  });

  group('Financial Excel Generation', () {
    test('generateFinancialExcel returns Uint8List with data', () {
      final transactions = [
        Transaction(
          id: '1',
          farmId: 'farm-1',
          date: DateTime(2024, 1, 15),
          type: TransactionType.income,
          category: 'Animal Sales',
          amount: 1500000.0,
          description: 'Sold pig',
          recordedBy: 'test-user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final excel = exportService.generateFinancialExcel(transactions);

      expect(excel, isNotEmpty);
    });
  });

  group('Financial JSON Generation', () {
    test('generateFinancialJson returns valid JSON string', () {
      final transactions = [
        Transaction(
          id: '1',
          farmId: 'farm-1',
          date: DateTime(2024, 1, 15),
          type: TransactionType.income,
          category: 'Animal Sales',
          amount: 1500000.0,
          description: 'Sold pig',
          recordedBy: 'test-user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final summary = FinancialSummary(
        totalIncome: 1500000.0,
        totalExpenses: 0,
        netProfit: 1500000.0,
        incomeByCategory: {'Animal Sales': 1500000.0},
        expensesByCategory: {},
        transactionCount: 1,
      );

      final json = exportService.generateFinancialJson(
        summary: summary,
        transactions: transactions,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );

      expect(json, isNotEmpty);
      expect(json, contains('Animal Sales'));
      expect(json, contains('income'));
    });
  });

  group('Health Record CSV', () {
    test('generates CSV with health record', () {
      final records = <HealthRecord>[
        HealthRecord(
          id: '1',
          farmId: 'farm-1',
          animalId: 'animal-1',
          type: HealthRecordType.vaccination,
          date: DateTime(2024, 1, 10),
          title: 'Annual Vaccination',
          description: 'FMD vaccine administered',
          veterinarianName: 'Dr. Smith',
          status: HealthStatus.completed,
          recordedBy: 'test-user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final csv = exportService.generateHealthCsv(records);

      expect(csv, contains('Annual Vaccination'));
      expect(csv, contains('vaccination'));
      expect(csv, contains('completed'));
    });
  });

  group('Health Record PDF', () {
    test('generates PDF with health record', () async {
      final records = <HealthRecord>[
        HealthRecord(
          id: '1',
          farmId: 'farm-1',
          animalId: 'animal-1',
          type: HealthRecordType.vaccination,
          date: DateTime(2024, 1, 10),
          title: 'Annual Vaccination',
          status: HealthStatus.completed,
          recordedBy: 'test-user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final pdf = await exportService.generateHealthPdf(records);

      expect(pdf, isNotEmpty);
    });
  });

  group('Health Record Excel', () {
    test('generateHealthExcel returns Uint8List with data', () {
      final records = <HealthRecord>[
        HealthRecord(
          id: '1',
          farmId: 'farm-1',
          animalId: 'animal-1',
          type: HealthRecordType.vaccination,
          date: DateTime(2024, 1, 10),
          title: 'Annual Vaccination',
          status: HealthStatus.completed,
          recordedBy: 'test-user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final excel = exportService.generateHealthExcel(records);

      expect(excel, isNotEmpty);
    });
  });

  group('Health Record JSON', () {
    test('generateHealthJson returns valid JSON string', () {
      final records = <HealthRecord>[
        HealthRecord(
          id: '1',
          farmId: 'farm-1',
          animalId: 'animal-1',
          type: HealthRecordType.vaccination,
          date: DateTime(2024, 1, 10),
          title: 'Annual Vaccination',
          status: HealthStatus.completed,
          recordedBy: 'test-user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final json = exportService.generateHealthJson(records);

      expect(json, isNotEmpty);
      expect(json, contains('Annual Vaccination'));
      expect(json, contains('vaccination'));
    });
  });

  group('Breeding Record Excel', () {
    test('generateBreedingExcel returns Uint8List with data', () {
      final records = <BreedingRecord>[
        BreedingRecord(
          id: '1',
          farmId: 'farm-1',
          animalId: 'animal-1',
          heatDate: DateTime(2024, 1, 10),
          status: BreedingStatus.pregnant,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final excel = exportService.generateBreedingExcel(records);

      expect(excel, isNotEmpty);
    });
  });

  group('Breeding Record JSON', () {
    test('generateBreedingJson returns valid JSON string', () {
      final records = <BreedingRecord>[
        BreedingRecord(
          id: '1',
          farmId: 'farm-1',
          animalId: 'animal-1',
          heatDate: DateTime(2024, 1, 10),
          status: BreedingStatus.pregnant,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final json = exportService.generateBreedingJson(records);

      expect(json, isNotEmpty);
      expect(json, contains('pregnant'));
    });
  });

  group('Growth Excel Generation', () {
    test('generateGrowthExcel returns Uint8List with data', () {
      final animals = [
        Animal(
          id: 'animal-1',
          farmId: 'farm-1',
          tagId: 'PIG-001',
          species: AnimalType.pig,
          breed: 'Large White',
          gender: Gender.male,
          birthDate: DateTime(2023, 6, 1),
          currentWeight: 100.0,
          status: AnimalStatus.healthy,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final weightsByAnimal = <String, List<WeightRecord>>{
        'animal-1': [
          WeightRecord(
            id: '1',
            farmId: 'farm-1',
            animalId: 'animal-1',
            weight: 100.0,
            date: DateTime(2024, 3, 1),
            createdAt: DateTime.now(),
          ),
        ],
      };

      final excel = exportService.generateGrowthExcel(animals, weightsByAnimal);

      expect(excel, isNotEmpty);
    });
  });

  group('Growth JSON Generation', () {
    test('generateGrowthJson returns valid JSON string', () {
      final animals = [
        Animal(
          id: 'animal-1',
          farmId: 'farm-1',
          tagId: 'PIG-001',
          species: AnimalType.pig,
          breed: 'Large White',
          gender: Gender.male,
          birthDate: DateTime(2023, 6, 1),
          currentWeight: 100.0,
          status: AnimalStatus.healthy,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final weightsByAnimal = <String, List<WeightRecord>>{
        'animal-1': [
          WeightRecord(
            id: '1',
            farmId: 'farm-1',
            animalId: 'animal-1',
            weight: 100.0,
            date: DateTime(2024, 3, 1),
            createdAt: DateTime.now(),
          ),
        ],
      };

      final json = exportService.generateGrowthJson(animals, weightsByAnimal);

      expect(json, isNotEmpty);
      expect(json, contains('PIG-001'));
      expect(json, contains('Large White'));
    });
  });

  group('Edge Cases', () {
    test('handles special characters in notes', () {
      final animals = [
        Animal(
          id: '1',
          farmId: 'farm-1',
          tagId: 'COW-001',
          species: AnimalType.cattle,
          breed: 'Holstein',
          gender: Gender.female,
          birthDate: DateTime(2022, 1, 15),
          currentWeight: 450.0,
          status: AnimalStatus.healthy,
          notes: 'Special chars: "quotes", commas, newlines\ntest',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final csv = exportService.generateInventoryCsv(animals);

      expect(csv, isNotEmpty);
      expect(csv, contains('COW-001'));
    });

    test('handles very large weight values', () {
      final animals = [
        Animal(
          id: '1',
          farmId: 'farm-1',
          tagId: 'ELEPHANT-001',
          species: AnimalType.other,
          breed: 'African',
          gender: Gender.male,
          birthDate: DateTime(2020, 1, 1),
          currentWeight: 6000.0,
          status: AnimalStatus.healthy,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final csv = exportService.generateInventoryCsv(animals);

      expect(csv, contains('6000.0'));
    });

    test('handles zero weight', () {
      final animals = [
        Animal(
          id: '1',
          farmId: 'farm-1',
          tagId: 'CALF-001',
          species: AnimalType.cattle,
          breed: 'Holstein',
          gender: Gender.female,
          birthDate: DateTime.now(),
          currentWeight: 0.0,
          status: AnimalStatus.healthy,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final csv = exportService.generateInventoryCsv(animals);

      expect(csv, contains('CALF-001'));
    });
  });
}
