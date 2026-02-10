import 'package:flutter_test/flutter_test.dart';
import 'package:manage/models/transaction.dart';

void main() {
  group('TransactionType', () {
    test('all types are defined', () {
      expect(TransactionType.values.length, 2);
      expect(TransactionType.values, contains(TransactionType.income));
      expect(TransactionType.values, contains(TransactionType.expense));
    });
  });

  group('ExpenseCategory', () {
    test('all categories are defined', () {
      expect(ExpenseCategory.values.length, 12);
      expect(ExpenseCategory.values, contains(ExpenseCategory.feed));
      expect(ExpenseCategory.values, contains(ExpenseCategory.veterinary));
      expect(ExpenseCategory.values, contains(ExpenseCategory.medication));
      expect(ExpenseCategory.values, contains(ExpenseCategory.equipment));
      expect(ExpenseCategory.values, contains(ExpenseCategory.supplies));
      expect(ExpenseCategory.values, contains(ExpenseCategory.labor));
      expect(ExpenseCategory.values, contains(ExpenseCategory.utilities));
      expect(ExpenseCategory.values, contains(ExpenseCategory.transport));
      expect(ExpenseCategory.values, contains(ExpenseCategory.maintenance));
      expect(ExpenseCategory.values, contains(ExpenseCategory.insurance));
      expect(ExpenseCategory.values, contains(ExpenseCategory.taxes));
      expect(ExpenseCategory.values, contains(ExpenseCategory.other));
    });

    test('name property returns correct values', () {
      expect(ExpenseCategory.feed.name, 'feed');
      expect(ExpenseCategory.veterinary.name, 'veterinary');
      expect(ExpenseCategory.medication.name, 'medication');
      expect(ExpenseCategory.equipment.name, 'equipment');
    });
  });

  group('IncomeCategory', () {
    test('all categories are defined', () {
      expect(IncomeCategory.values.length, 8);
      expect(IncomeCategory.values, contains(IncomeCategory.animalSale));
      expect(IncomeCategory.values, contains(IncomeCategory.breedingService));
      expect(IncomeCategory.values, contains(IncomeCategory.milkSale));
      expect(IncomeCategory.values, contains(IncomeCategory.eggSale));
      expect(IncomeCategory.values, contains(IncomeCategory.manureSale));
      expect(IncomeCategory.values, contains(IncomeCategory.byProductSale));
      expect(IncomeCategory.values, contains(IncomeCategory.subsidyGrant));
      expect(IncomeCategory.values, contains(IncomeCategory.other));
    });

    test('name property returns correct values', () {
      expect(IncomeCategory.animalSale.name, 'animalSale');
      expect(IncomeCategory.breedingService.name, 'breedingService');
      expect(IncomeCategory.milkSale.name, 'milkSale');
      expect(IncomeCategory.subsidyGrant.name, 'subsidyGrant');
    });
  });

  group('PaymentMethod', () {
    test('all methods are defined', () {
      expect(PaymentMethod.values.length, 6);
      expect(PaymentMethod.values, contains(PaymentMethod.cash));
      expect(PaymentMethod.values, contains(PaymentMethod.bankTransfer));
      expect(PaymentMethod.values, contains(PaymentMethod.mobileMoney));
      expect(PaymentMethod.values, contains(PaymentMethod.cheque));
      expect(PaymentMethod.values, contains(PaymentMethod.credit));
      expect(PaymentMethod.values, contains(PaymentMethod.other));
    });

    test('name property returns correct values', () {
      expect(PaymentMethod.cash.name, 'cash');
      expect(PaymentMethod.mobileMoney.name, 'mobileMoney');
      expect(PaymentMethod.bankTransfer.name, 'bankTransfer');
    });
  });

  group('Transaction Model', () {
    late Transaction expenseTransaction;
    late Transaction incomeTransaction;
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 1, 10);
      expenseTransaction = Transaction(
        id: 'txn-001',
        farmId: 'farm-001',
        date: now,
        type: TransactionType.expense,
        category: ExpenseCategory.feed.name,
        amount: 500000.0,
        description: 'Monthly pig feed purchase',
        paymentMethod: PaymentMethod.mobileMoney,
        referenceNumber: 'INV-2026-001',
        notes: 'Bulk purchase discount applied',
        createdAt: now,
        updatedAt: now,
      );

      incomeTransaction = Transaction(
        id: 'txn-002',
        farmId: 'farm-001',
        date: now,
        type: TransactionType.income,
        category: IncomeCategory.animalSale.name,
        amount: 1500000.0,
        animalId: 'animal-001',
        description: 'Sale of mature pig',
        paymentMethod: PaymentMethod.cash,
        createdAt: now,
        updatedAt: now,
      );
    });

    test('should create expense transaction with all properties', () {
      expect(expenseTransaction.id, 'txn-001');
      expect(expenseTransaction.type, TransactionType.expense);
      expect(expenseTransaction.category, 'feed');
      expect(expenseTransaction.amount, 500000.0);
      expect(expenseTransaction.paymentMethod, PaymentMethod.mobileMoney);
      expect(expenseTransaction.referenceNumber, 'INV-2026-001');
    });

    test('should create income transaction with animal link', () {
      expect(incomeTransaction.id, 'txn-002');
      expect(incomeTransaction.type, TransactionType.income);
      expect(incomeTransaction.category, 'animalSale');
      expect(incomeTransaction.amount, 1500000.0);
      expect(incomeTransaction.animalId, 'animal-001');
    });

    test('isExpense returns correct value', () {
      expect(expenseTransaction.isExpense, true);
      expect(incomeTransaction.isExpense, false);
    });

    test('isIncome returns correct value', () {
      expect(expenseTransaction.isIncome, false);
      expect(incomeTransaction.isIncome, true);
    });

    test('categoryDisplayName returns formatted name', () {
      expect(expenseTransaction.categoryDisplayName, 'Feed');
      expect(incomeTransaction.categoryDisplayName, 'Animal Sale');
    });

    test('toSupabase should convert to map correctly', () {
      final map = expenseTransaction.toSupabase();

      expect(map['farm_id'], 'farm-001');
      expect(map['type'], 'expense');
      expect(map['category'], 'feed');
      expect(map['amount'], 500000.0);
      expect(map['description'], 'Monthly pig feed purchase');
      expect(map['payment_method'], 'mobileMoney');
    });

    test('copyWith should create new instance with updated values', () {
      final updatedTransaction = expenseTransaction.copyWith(
        amount: 600000.0,
        notes: 'Updated notes',
      );

      expect(updatedTransaction.amount, 600000.0);
      expect(updatedTransaction.notes, 'Updated notes');
      expect(updatedTransaction.id, expenseTransaction.id);
      expect(updatedTransaction.category, expenseTransaction.category);
    });

    test('should handle transaction without optional fields', () {
      final minimalTransaction = Transaction(
        id: 'txn-003',
        farmId: 'farm-001',
        date: now,
        type: TransactionType.expense,
        category: ExpenseCategory.other.name,
        amount: 10000.0,
        description: 'Miscellaneous expense',
        createdAt: now,
        updatedAt: now,
      );

      expect(minimalTransaction.animalId, isNull);
      expect(minimalTransaction.paymentMethod, isNull);
    });

    test('formattedAmount includes sign for income and expense', () {
      expect(expenseTransaction.formattedAmount.startsWith('-'), true);
      expect(incomeTransaction.formattedAmount.startsWith('+'), true);
    });
  });

  group('Budget Model', () {
    late Budget budget;

    setUp(() {
      budget = Budget(
        id: 'budget-001',
        farmId: 'farm-001',
        year: 2026,
        month: 1,
        totalBudget: 2000000.0,
        categoryBudgets: {
          ExpenseCategory.feed.name: 1000000.0,
          ExpenseCategory.veterinary.name: 300000.0,
          ExpenseCategory.labor.name: 500000.0,
          ExpenseCategory.utilities.name: 200000.0,
        },
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
    });

    test('should create budget with all properties', () {
      expect(budget.id, 'budget-001');
      expect(budget.year, 2026);
      expect(budget.month, 1);
      expect(budget.totalBudget, 2000000.0);
      expect(budget.categoryBudgets.length, 4);
    });

    test('should get category budget correctly', () {
      expect(budget.categoryBudgets['feed'], 1000000.0);
      expect(budget.categoryBudgets['veterinary'], 300000.0);
      expect(budget.categoryBudgets['labor'], 500000.0);
    });

    test('toSupabase should convert to map correctly', () {
      final map = budget.toSupabase();

      expect(map['farm_id'], 'farm-001');
      expect(map['year'], 2026);
      expect(map['month'], 1);
      expect(map['total_budget'], 2000000.0);
      expect(map['category_budgets'], isA<Map<String, dynamic>>());
    });
  });

  group('FinancialSummary Model', () {
    test('should create financial summary with all properties', () {
      final summary = FinancialSummary(
        totalIncome: 5000000.0,
        totalExpenses: 3000000.0,
        netProfit: 2000000.0,
        incomeByCategory: {
          IncomeCategory.animalSale.name: 4000000.0,
          IncomeCategory.milkSale.name: 1000000.0,
        },
        expensesByCategory: {
          ExpenseCategory.feed.name: 2000000.0,
          ExpenseCategory.veterinary.name: 500000.0,
          ExpenseCategory.labor.name: 500000.0,
        },
        transactionCount: 25,
      );

      expect(summary.totalIncome, 5000000.0);
      expect(summary.totalExpenses, 3000000.0);
      expect(summary.netProfit, 2000000.0);
      expect(summary.transactionCount, 25);
    });

    test('should calculate profit margin correctly', () {
      final summary = FinancialSummary(
        totalIncome: 5000000.0,
        totalExpenses: 3000000.0,
        netProfit: 2000000.0,
        incomeByCategory: {},
        expensesByCategory: {},
        transactionCount: 25,
      );

      expect(summary.profitMargin, 40.0); // (2000000 / 5000000) * 100
    });

    test('isProfitable returns correct value', () {
      final profitableSummary = FinancialSummary(
        totalIncome: 5000000.0,
        totalExpenses: 3000000.0,
        netProfit: 2000000.0,
        incomeByCategory: {},
        expensesByCategory: {},
        transactionCount: 25,
      );

      final lossSummary = FinancialSummary(
        totalIncome: 1000000.0,
        totalExpenses: 1500000.0,
        netProfit: -500000.0,
        incomeByCategory: {},
        expensesByCategory: {},
        transactionCount: 10,
      );

      expect(profitableSummary.isProfitable, true);
      expect(lossSummary.isProfitable, false);
    });

    test('should handle zero transactions', () {
      final summary = FinancialSummary(
        totalIncome: 0.0,
        totalExpenses: 0.0,
        netProfit: 0.0,
        incomeByCategory: {},
        expensesByCategory: {},
        transactionCount: 0,
      );

      expect(summary.netProfit, 0.0);
      expect(summary.transactionCount, 0);
      expect(summary.profitMargin, 0.0);
    });
  });

  group('AnimalFinancials Model', () {
    test('should create animal financials with all properties', () {
      final financials = AnimalFinancials(
        animalId: 'animal-001',
        totalInvestment: 500000.0,
        totalIncome: 1500000.0,
        feedCosts: 300000.0,
        medicalCosts: 100000.0,
        otherCosts: 100000.0,
        netValue: 1000000.0,
      );

      expect(financials.animalId, 'animal-001');
      expect(financials.totalInvestment, 500000.0);
      expect(financials.totalIncome, 1500000.0);
      expect(financials.netValue, 1000000.0);
    });

    test('should calculate ROI correctly', () {
      final financials = AnimalFinancials(
        animalId: 'animal-001',
        totalInvestment: 500000.0,
        totalIncome: 1500000.0,
        feedCosts: 300000.0,
        medicalCosts: 100000.0,
        otherCosts: 100000.0,
        netValue: 1000000.0,
      );

      // ROI = ((1500000 - 500000) / 500000) * 100 = 200%
      expect(financials.roi, 200.0);
    });

    test('isProfitable returns correct value', () {
      final profitableAnimal = AnimalFinancials(
        animalId: 'animal-001',
        totalInvestment: 500000.0,
        totalIncome: 1500000.0,
        feedCosts: 300000.0,
        medicalCosts: 100000.0,
        otherCosts: 100000.0,
        netValue: 1000000.0,
      );

      final unprofitableAnimal = AnimalFinancials(
        animalId: 'animal-002',
        totalInvestment: 500000.0,
        totalIncome: 300000.0,
        feedCosts: 300000.0,
        medicalCosts: 100000.0,
        otherCosts: 100000.0,
        netValue: -200000.0,
      );

      expect(profitableAnimal.isProfitable, true);
      expect(unprofitableAnimal.isProfitable, false);
    });
  });
}
