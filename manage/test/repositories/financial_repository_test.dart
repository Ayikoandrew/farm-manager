/// Financial Repository Tests - Migrated to Supabase Mock Testing
/// Uses MockSupabaseDatabase instead of FakeFirebaseFirestore

import 'package:flutter_test/flutter_test.dart';
import 'package:manage/models/transaction.dart' as models;
import '../mocks/mock_supabase.dart';

/// Financial summary data class for test results
class FinancialSummary {
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final Map<String, double> expensesByCategory;
  final Map<String, double> incomeByCategory;

  FinancialSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
    required this.expensesByCategory,
    required this.incomeByCategory,
  });
}

/// Animal financials data class for test results
class AnimalFinancials {
  final double totalIncome;
  final double totalInvestment;

  AnimalFinancials({required this.totalIncome, required this.totalInvestment});
}

/// Mock FinancialRepository for testing with MockSupabaseDatabase
class MockFinancialRepository {
  final MockSupabaseDatabase db;
  static const String _table = 'transactions';

  MockFinancialRepository({required this.db});

  /// Add a transaction
  Future<String> addTransaction(models.Transaction transaction) async {
    final data = transaction.toSupabase();
    final inserted = db.insert(_table, data);
    return inserted['id'] as String;
  }

  /// Get a single transaction by ID
  Future<models.Transaction?> getTransaction(String id) async {
    final data = db.selectSingle(_table, where: {'id': id});
    if (data == null) return null;
    return models.Transaction.fromSupabase(data);
  }

  /// Get all transactions for a farm
  Future<List<models.Transaction>> getTransactions(String farmId) async {
    final data = db.select(_table, where: {'farm_id': farmId});
    return data.map((json) => models.Transaction.fromSupabase(json)).toList();
  }

  /// Update a transaction
  Future<void> updateTransaction(models.Transaction transaction) async {
    db.update(_table, transaction.toSupabase(), where: {'id': transaction.id});
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String id) async {
    db.delete(_table, where: {'id': id});
  }

  /// Watch transactions for a farm
  Stream<List<models.Transaction>> watchTransactions(String farmId) {
    return db
        .stream(_table, where: {'farm_id': farmId})
        .map(
          (data) => data
              .map((json) => models.Transaction.fromSupabase(json))
              .toList(),
        );
  }

  /// Watch transactions by type
  Stream<List<models.Transaction>> watchTransactionsByType(
    String farmId,
    models.TransactionType type,
  ) {
    return db
        .stream(_table, where: {'farm_id': farmId})
        .map(
          (data) => data
              .where((json) => json['type'] == type.name)
              .map((json) => models.Transaction.fromSupabase(json))
              .toList(),
        );
  }

  /// Watch transactions for an animal
  Stream<List<models.Transaction>> watchAnimalTransactions(String animalId) {
    return db
        .stream(_table, where: {'animal_id': animalId})
        .map(
          (data) => data
              .map((json) => models.Transaction.fromSupabase(json))
              .toList(),
        );
  }

  /// Watch transactions in date range
  Stream<List<models.Transaction>> watchTransactionsInRange(
    String farmId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return db
        .stream(_table, where: {'farm_id': farmId})
        .map(
          (data) => data
              .where((json) {
                final date = DateTime.parse(json['date']);
                return date.isAfter(startDate) && date.isBefore(endDate);
              })
              .map((json) => models.Transaction.fromSupabase(json))
              .toList(),
        );
  }

  /// Get financial summary
  Future<FinancialSummary> getFinancialSummary(
    String farmId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var data = db.select(_table, where: {'farm_id': farmId});

    if (startDate != null && endDate != null) {
      data = data.where((json) {
        final date = DateTime.parse(json['date']);
        return date.isAfter(startDate) && date.isBefore(endDate);
      }).toList();
    }

    double totalIncome = 0;
    double totalExpenses = 0;
    final expensesByCategory = <String, double>{};
    final incomeByCategory = <String, double>{};

    for (final json in data) {
      final amount = (json['amount'] as num).toDouble();
      final category = json['category'] as String;
      final type = json['type'] as String;

      if (type == models.TransactionType.income.name) {
        totalIncome += amount;
        incomeByCategory[category] = (incomeByCategory[category] ?? 0) + amount;
      } else {
        totalExpenses += amount;
        expensesByCategory[category] =
            (expensesByCategory[category] ?? 0) + amount;
      }
    }

    return FinancialSummary(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netProfit: totalIncome - totalExpenses,
      expensesByCategory: expensesByCategory,
      incomeByCategory: incomeByCategory,
    );
  }

  /// Get animal financials
  Future<AnimalFinancials> getAnimalFinancials(
    String animalId,
    String animalTagId,
  ) async {
    final data = db
        .select(_table)
        .where(
          (json) =>
              json['animal_id'] == animalId ||
              json['animal_tag_id'] == animalTagId,
        )
        .toList();

    double totalIncome = 0;
    double totalInvestment = 0;

    for (final json in data) {
      final amount = (json['amount'] as num).toDouble();
      final type = json['type'] as String;

      if (type == models.TransactionType.income.name) {
        totalIncome += amount;
      } else {
        totalInvestment += amount;
      }
    }

    return AnimalFinancials(
      totalIncome: totalIncome,
      totalInvestment: totalInvestment,
    );
  }
}

void main() {
  late MockSupabaseDatabase mockDb;
  late MockFinancialRepository repository;

  setUp(() {
    mockDb = MockSupabaseDatabase();
    repository = MockFinancialRepository(db: mockDb);
  });

  tearDown(() {
    mockDb.dispose();
  });

  models.Transaction createTestTransaction({
    String id = 'transaction-1',
    String farmId = 'farm-1',
    DateTime? date,
    models.TransactionType type = models.TransactionType.expense,
    String category = 'feed',
    double amount = 100.0,
    String? animalId,
    String? animalTagId,
    String description = 'Test Transaction',
    String? vendorOrBuyer,
    models.PaymentMethod? paymentMethod,
    String? referenceNumber,
    String? notes,
    String recordedBy = 'user-1',
  }) {
    return models.Transaction(
      id: id,
      farmId: farmId,
      date: date ?? DateTime.now(),
      type: type,
      category: category,
      amount: amount,
      animalId: animalId,
      animalTagId: animalTagId,
      description: description,
      vendorOrBuyer: vendorOrBuyer,
      paymentMethod: paymentMethod,
      referenceNumber: referenceNumber,
      notes: notes,
      recordedBy: recordedBy,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> addTransactionToDb(models.Transaction transaction) async {
    final data = transaction.toSupabase();
    data['id'] = transaction.id;
    mockDb.insert('transactions', data);
  }

  group('FinancialRepository', () {
    group('addTransaction', () {
      test('should add a transaction and return document ID', () async {
        final transaction = createTestTransaction();

        final docId = await repository.addTransaction(transaction);

        expect(docId, isNotEmpty);
        final data = mockDb.selectSingle('transactions', where: {'id': docId});
        expect(data, isNotNull);
      });

      test('should store transaction data correctly', () async {
        final transaction = createTestTransaction(
          type: models.TransactionType.expense,
          category: 'feed',
          amount: 250.0,
          description: 'Monthly pig feed',
        );

        final docId = await repository.addTransaction(transaction);

        final data = mockDb.selectSingle('transactions', where: {'id': docId});
        expect(data!['type'], 'expense');
        expect(data['category'], 'feed');
        expect(data['amount'], 250.0);
        expect(data['description'], 'Monthly pig feed');
      });
    });

    group('getTransaction', () {
      test('should return transaction when exists', () async {
        final transaction = createTestTransaction();
        await addTransactionToDb(transaction);

        final result = await repository.getTransaction(transaction.id);

        expect(result, isNotNull);
        expect(result!.description, transaction.description);
      });

      test('should return null when transaction does not exist', () async {
        final result = await repository.getTransaction('non-existent');

        expect(result, isNull);
      });
    });

    group('getTransactions', () {
      test('should return all transactions for a farm', () async {
        await addTransactionToDb(
          createTestTransaction(id: 't1', farmId: 'farm-1'),
        );
        await addTransactionToDb(
          createTestTransaction(id: 't2', farmId: 'farm-1'),
        );
        await addTransactionToDb(
          createTestTransaction(id: 't3', farmId: 'farm-2'),
        );

        final results = await repository.getTransactions('farm-1');

        expect(results.length, 2);
        expect(results.every((t) => t.farmId == 'farm-1'), isTrue);
      });

      test('should return empty list when no transactions exist', () async {
        final results = await repository.getTransactions('empty-farm');

        expect(results, isEmpty);
      });
    });

    group('updateTransaction', () {
      test('should update transaction data', () async {
        final transaction = createTestTransaction();
        await addTransactionToDb(transaction);

        final updatedTransaction = transaction.copyWith(
          amount: 300.0,
          description: 'Updated description',
        );
        await repository.updateTransaction(updatedTransaction);

        final data = mockDb.selectSingle(
          'transactions',
          where: {'id': transaction.id},
        );
        expect(data!['amount'], 300.0);
        expect(data['description'], 'Updated description');
      });
    });

    group('deleteTransaction', () {
      test('should delete transaction', () async {
        final transaction = createTestTransaction();
        await addTransactionToDb(transaction);

        await repository.deleteTransaction(transaction.id);

        final data = mockDb.selectSingle(
          'transactions',
          where: {'id': transaction.id},
        );
        expect(data, isNull);
      });
    });

    group('watchTransactions', () {
      test('should emit transactions for farm', () async {
        await addTransactionToDb(
          createTestTransaction(id: 't1', farmId: 'farm-1'),
        );
        await addTransactionToDb(
          createTestTransaction(id: 't2', farmId: 'farm-1'),
        );

        final stream = repository.watchTransactions('farm-1');

        await expectLater(
          stream.first,
          completion(
            isA<List<models.Transaction>>().having(
              (list) => list.length,
              'length',
              2,
            ),
          ),
        );
      });

      test('should emit empty list for farm with no transactions', () async {
        final stream = repository.watchTransactions('empty-farm');

        await expectLater(stream.first, completion(isEmpty));
      });
    });

    group('watchTransactionsByType', () {
      test('should emit only expense transactions', () async {
        await addTransactionToDb(
          createTestTransaction(
            id: 't1',
            farmId: 'farm-1',
            type: models.TransactionType.expense,
          ),
        );
        await addTransactionToDb(
          createTestTransaction(
            id: 't2',
            farmId: 'farm-1',
            type: models.TransactionType.income,
          ),
        );

        final stream = repository.watchTransactionsByType(
          'farm-1',
          models.TransactionType.expense,
        );

        await expectLater(
          stream.first,
          completion(
            isA<List<models.Transaction>>().having(
              (list) =>
                  list.every((t) => t.type == models.TransactionType.expense),
              'all expenses',
              isTrue,
            ),
          ),
        );
      });

      test('should emit only income transactions', () async {
        await addTransactionToDb(
          createTestTransaction(
            id: 't1',
            farmId: 'farm-1',
            type: models.TransactionType.income,
          ),
        );
        await addTransactionToDb(
          createTestTransaction(
            id: 't2',
            farmId: 'farm-1',
            type: models.TransactionType.expense,
          ),
        );

        final stream = repository.watchTransactionsByType(
          'farm-1',
          models.TransactionType.income,
        );

        await expectLater(
          stream.first,
          completion(
            isA<List<models.Transaction>>().having(
              (list) =>
                  list.every((t) => t.type == models.TransactionType.income),
              'all income',
              isTrue,
            ),
          ),
        );
      });
    });

    group('watchAnimalTransactions', () {
      test('should emit only transactions for specific animal', () async {
        await addTransactionToDb(
          createTestTransaction(id: 't1', animalId: 'animal-1'),
        );
        await addTransactionToDb(
          createTestTransaction(id: 't2', animalId: 'animal-2'),
        );

        final stream = repository.watchAnimalTransactions('animal-1');

        await expectLater(
          stream.first,
          completion(
            isA<List<models.Transaction>>().having(
              (list) => list.every((t) => t.animalId == 'animal-1'),
              'all for animal-1',
              isTrue,
            ),
          ),
        );
      });

      test('should emit empty list for animal with no transactions', () async {
        final stream = repository.watchAnimalTransactions('unknown-animal');

        await expectLater(stream.first, completion(isEmpty));
      });
    });

    group('watchTransactionsInRange', () {
      test('should emit only transactions within date range', () async {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        final lastWeek = today.subtract(const Duration(days: 7));

        await addTransactionToDb(
          createTestTransaction(id: 't1', farmId: 'farm-1', date: today),
        );
        await addTransactionToDb(
          createTestTransaction(id: 't2', farmId: 'farm-1', date: yesterday),
        );
        await addTransactionToDb(
          createTestTransaction(id: 't3', farmId: 'farm-1', date: lastWeek),
        );

        final stream = repository.watchTransactionsInRange(
          'farm-1',
          yesterday.subtract(const Duration(hours: 1)),
          today.add(const Duration(hours: 1)),
        );

        await expectLater(
          stream.first,
          completion(
            isA<List<models.Transaction>>().having(
              (list) => list.length,
              'length',
              2,
            ),
          ),
        );
      });
    });

    group('getFinancialSummary', () {
      test('should calculate total income and expenses', () async {
        await addTransactionToDb(
          createTestTransaction(
            id: 't1',
            farmId: 'farm-1',
            type: models.TransactionType.income,
            amount: 1000.0,
          ),
        );
        await addTransactionToDb(
          createTestTransaction(
            id: 't2',
            farmId: 'farm-1',
            type: models.TransactionType.expense,
            amount: 300.0,
          ),
        );
        await addTransactionToDb(
          createTestTransaction(
            id: 't3',
            farmId: 'farm-1',
            type: models.TransactionType.expense,
            amount: 200.0,
          ),
        );

        final summary = await repository.getFinancialSummary('farm-1');

        expect(summary.totalIncome, 1000.0);
        expect(summary.totalExpenses, 500.0);
        expect(summary.netProfit, 500.0);
      });

      test('should group expenses by category', () async {
        await addTransactionToDb(
          createTestTransaction(
            id: 't1',
            farmId: 'farm-1',
            type: models.TransactionType.expense,
            category: 'feed',
            amount: 500.0,
          ),
        );
        await addTransactionToDb(
          createTestTransaction(
            id: 't2',
            farmId: 'farm-1',
            type: models.TransactionType.expense,
            category: 'veterinary',
            amount: 200.0,
          ),
        );
        await addTransactionToDb(
          createTestTransaction(
            id: 't3',
            farmId: 'farm-1',
            type: models.TransactionType.expense,
            category: 'feed',
            amount: 300.0,
          ),
        );

        final summary = await repository.getFinancialSummary('farm-1');

        expect(summary.expensesByCategory['feed'], 800.0);
        expect(summary.expensesByCategory['veterinary'], 200.0);
      });

      test('should filter by date range', () async {
        final today = DateTime.now();
        final lastMonth = today.subtract(const Duration(days: 60));

        await addTransactionToDb(
          createTestTransaction(
            id: 't1',
            farmId: 'farm-1',
            type: models.TransactionType.income,
            amount: 1000.0,
            date: today,
          ),
        );
        await addTransactionToDb(
          createTestTransaction(
            id: 't2',
            farmId: 'farm-1',
            type: models.TransactionType.income,
            amount: 500.0,
            date: lastMonth,
          ),
        );

        final summary = await repository.getFinancialSummary(
          'farm-1',
          startDate: today.subtract(const Duration(days: 30)),
          endDate: today.add(const Duration(days: 1)),
        );

        expect(summary.totalIncome, 1000.0);
      });

      test('should return zero values when no transactions exist', () async {
        final summary = await repository.getFinancialSummary('empty-farm');

        expect(summary.totalIncome, 0.0);
        expect(summary.totalExpenses, 0.0);
        expect(summary.netProfit, 0.0);
      });
    });

    group('getAnimalFinancials', () {
      test('should calculate total investment for animal', () async {
        await addTransactionToDb(
          createTestTransaction(
            id: 't1',
            animalId: 'animal-1',
            animalTagId: 'TAG001',
            type: models.TransactionType.expense,
            category: 'feed',
            amount: 500.0,
          ),
        );
        await addTransactionToDb(
          createTestTransaction(
            id: 't2',
            animalId: 'animal-1',
            animalTagId: 'TAG001',
            type: models.TransactionType.expense,
            category: 'veterinary',
            amount: 200.0,
          ),
        );

        final financials = await repository.getAnimalFinancials(
          'animal-1',
          'TAG001',
        );

        expect(financials.totalInvestment, 700.0);
      });

      test('should calculate total income from animal', () async {
        await addTransactionToDb(
          createTestTransaction(
            id: 't1',
            animalId: 'animal-1',
            animalTagId: 'TAG001',
            type: models.TransactionType.income,
            category: 'animalSale',
            amount: 3000.0,
          ),
        );

        final financials = await repository.getAnimalFinancials(
          'animal-1',
          'TAG001',
        );

        expect(financials.totalIncome, 3000.0);
      });

      test(
        'should return zero values for animal with no transactions',
        () async {
          final financials = await repository.getAnimalFinancials(
            'unknown-animal',
            'TAG999',
          );

          expect(financials.totalIncome, 0.0);
          expect(financials.totalInvestment, 0.0);
        },
      );
    });

    group('Expense Categories', () {
      test('should handle feed expenses', () async {
        final transaction = createTestTransaction(
          type: models.TransactionType.expense,
          category: models.ExpenseCategory.feed.name,
        );

        final docId = await repository.addTransaction(transaction);
        final result = await repository.getTransaction(docId);

        expect(result!.category, 'feed');
      });

      test('should handle veterinary expenses', () async {
        final transaction = createTestTransaction(
          type: models.TransactionType.expense,
          category: models.ExpenseCategory.veterinary.name,
        );

        final docId = await repository.addTransaction(transaction);
        final result = await repository.getTransaction(docId);

        expect(result!.category, 'veterinary');
      });

      test('should handle medication expenses', () async {
        final transaction = createTestTransaction(
          type: models.TransactionType.expense,
          category: models.ExpenseCategory.medication.name,
        );

        final docId = await repository.addTransaction(transaction);
        final result = await repository.getTransaction(docId);

        expect(result!.category, 'medication');
      });

      test('should handle labor expenses', () async {
        final transaction = createTestTransaction(
          type: models.TransactionType.expense,
          category: models.ExpenseCategory.labor.name,
        );

        final docId = await repository.addTransaction(transaction);
        final result = await repository.getTransaction(docId);

        expect(result!.category, 'labor');
      });
    });

    group('Income Categories', () {
      test('should handle animal sale income', () async {
        final transaction = createTestTransaction(
          type: models.TransactionType.income,
          category: models.IncomeCategory.animalSale.name,
        );

        final docId = await repository.addTransaction(transaction);
        final result = await repository.getTransaction(docId);

        expect(result!.category, 'animalSale');
      });

      test('should handle breeding service income', () async {
        final transaction = createTestTransaction(
          type: models.TransactionType.income,
          category: models.IncomeCategory.breedingService.name,
        );

        final docId = await repository.addTransaction(transaction);
        final result = await repository.getTransaction(docId);

        expect(result!.category, 'breedingService');
      });
    });

    group('Payment Methods', () {
      test('should handle cash payments', () async {
        final transaction = createTestTransaction(
          paymentMethod: models.PaymentMethod.cash,
        );

        final docId = await repository.addTransaction(transaction);
        final result = await repository.getTransaction(docId);

        expect(result!.paymentMethod, models.PaymentMethod.cash);
      });

      test('should handle mobile money payments', () async {
        final transaction = createTestTransaction(
          paymentMethod: models.PaymentMethod.mobileMoney,
        );

        final docId = await repository.addTransaction(transaction);
        final result = await repository.getTransaction(docId);

        expect(result!.paymentMethod, models.PaymentMethod.mobileMoney);
      });

      test('should handle bank transfer payments', () async {
        final transaction = createTestTransaction(
          paymentMethod: models.PaymentMethod.bankTransfer,
        );

        final docId = await repository.addTransaction(transaction);
        final result = await repository.getTransaction(docId);

        expect(result!.paymentMethod, models.PaymentMethod.bankTransfer);
      });
    });
  });
}
