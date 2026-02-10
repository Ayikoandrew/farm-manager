import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction.dart';
import '../config/supabase_config.dart';

class FinancialRepository {
  final SupabaseClient _client;
  static const String _transactionsTable = 'transactions';
  static const String _budgetsTable = 'budgets';

  FinancialRepository({SupabaseClient? client})
    : _client = client ?? SupabaseConfig.client;

  // ==================== TRANSACTIONS ====================

  Stream<List<Transaction>> watchTransactions(String farmId) {
    return _client
        .from(_transactionsTable)
        .stream(primaryKey: ['id'])
        .eq('farm_id', farmId)
        .order('date', ascending: false)
        .map(
          (data) => data.map((json) => Transaction.fromSupabase(json)).toList(),
        );
  }

  /// Watch transactions by type (income or expense)
  Stream<List<Transaction>> watchTransactionsByType(
    String farmId,
    TransactionType type,
  ) {
    return _client
        .from(_transactionsTable)
        .stream(primaryKey: ['id'])
        .eq('farm_id', farmId)
        .order('date', ascending: false)
        .map(
          (data) => data
              .where((json) => json['type'] == type.name)
              .map((json) => Transaction.fromSupabase(json))
              .toList(),
        );
  }

  Stream<List<Transaction>> watchAnimalTransactions(String animalId) {
    return _client
        .from(_transactionsTable)
        .stream(primaryKey: ['id'])
        .eq('animal_id', animalId)
        .order('date', ascending: false)
        .map(
          (data) => data.map((json) => Transaction.fromSupabase(json)).toList(),
        );
  }

  Stream<List<Transaction>> watchTransactionsInRange(
    String farmId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _client
        .from(_transactionsTable)
        .stream(primaryKey: ['id'])
        .eq('farm_id', farmId)
        .order('date', ascending: false)
        .map(
          (data) => data
              .where((json) {
                final date = DateTime.parse(json['date']);
                return date.isAfter(
                      startDate.subtract(const Duration(seconds: 1)),
                    ) &&
                    date.isBefore(endDate.add(const Duration(seconds: 1)));
              })
              .map((json) => Transaction.fromSupabase(json))
              .toList(),
        );
  }

  Future<List<Transaction>> getTransactions(String farmId) async {
    final response = await _client
        .from(_transactionsTable)
        .select()
        .eq('farm_id', farmId)
        .order('date', ascending: false);
    return (response as List)
        .map((json) => Transaction.fromSupabase(json))
        .toList();
  }

  Future<Transaction?> getTransaction(String id) async {
    final response = await _client
        .from(_transactionsTable)
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return Transaction.fromSupabase(response);
  }

  Future<String> addTransaction(Transaction transaction) async {
    final response = await _client
        .from(_transactionsTable)
        .insert(transaction.toSupabase())
        .select('id')
        .single();
    return response['id'] as String;
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _client
        .from(_transactionsTable)
        .update(transaction.toSupabase())
        .eq('id', transaction.id);
  }

  Future<void> deleteTransaction(String id) async {
    await _client.from(_transactionsTable).delete().eq('id', id);
  }

  // ==================== FINANCIAL SUMMARIES ====================

  Stream<FinancialSummary> watchFinancialSummary(
    String farmId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return watchTransactions(farmId).map((transactions) {
      // Filter by date range if specified
      var filtered = transactions;
      if (startDate != null) {
        filtered = filtered
            .where(
              (t) => t.date.isAfter(
                startDate.subtract(const Duration(seconds: 1)),
              ),
            )
            .toList();
      }
      if (endDate != null) {
        filtered = filtered
            .where(
              (t) => t.date.isBefore(endDate.add(const Duration(seconds: 1))),
            )
            .toList();
      }

      return _calculateSummary(filtered);
    });
  }

  Stream<FinancialSummary> watchMonthlyFinancialSummary(
    String farmId,
    int year,
    int month,
  ) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    return watchFinancialSummary(
      farmId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Stream<BudgetComparison> watchBudgetComparison(
    String farmId,
    int year,
    int month,
  ) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    return watchBudget(farmId, year, month).asyncMap((budget) async {
      final summary = await getFinancialSummary(
        farmId,
        startDate: startDate,
        endDate: endDate,
      );
      return BudgetComparison(
        budget: budget,
        actualExpenses: summary.totalExpenses,
        expensesByCategory: summary.expensesByCategory,
      );
    });
  }

  FinancialSummary _calculateSummary(List<Transaction> transactions) {
    double totalIncome = 0;
    double totalExpenses = 0;
    Map<String, double> incomeByCategory = {};
    Map<String, double> expensesByCategory = {};

    for (final t in transactions) {
      if (t.isIncome) {
        totalIncome += t.amount;
        incomeByCategory[t.category] =
            (incomeByCategory[t.category] ?? 0) + t.amount;
      } else {
        totalExpenses += t.amount;
        expensesByCategory[t.category] =
            (expensesByCategory[t.category] ?? 0) + t.amount;
      }
    }

    return FinancialSummary(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netProfit: totalIncome - totalExpenses,
      incomeByCategory: incomeByCategory,
      expensesByCategory: expensesByCategory,
      transactionCount: transactions.length,
    );
  }

  /// Get financial summary for a farm
  Future<FinancialSummary> getFinancialSummary(
    String farmId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client.from(_transactionsTable).select().eq('farm_id', farmId);

    if (startDate != null) {
      query = query.gte('date', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('date', endDate.toIso8601String());
    }

    final response = await query;
    final transactions = (response as List)
        .map((json) => Transaction.fromSupabase(json))
        .toList();

    double totalIncome = 0;
    double totalExpenses = 0;
    Map<String, double> incomeByCategory = {};
    Map<String, double> expensesByCategory = {};

    for (final t in transactions) {
      if (t.isIncome) {
        totalIncome += t.amount;
        incomeByCategory[t.category] =
            (incomeByCategory[t.category] ?? 0) + t.amount;
      } else {
        totalExpenses += t.amount;
        expensesByCategory[t.category] =
            (expensesByCategory[t.category] ?? 0) + t.amount;
      }
    }

    return FinancialSummary(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netProfit: totalIncome - totalExpenses,
      incomeByCategory: incomeByCategory,
      expensesByCategory: expensesByCategory,
      transactionCount: transactions.length,
    );
  }

  /// Get monthly summaries for a year
  Future<List<FinancialSummary>> getMonthlySummaries(
    String farmId,
    int year,
  ) async {
    final summaries = <FinancialSummary>[];

    for (int month = 1; month <= 12; month++) {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      final summary = await getFinancialSummary(
        farmId,
        startDate: startDate,
        endDate: endDate,
      );
      summaries.add(summary);
    }

    return summaries;
  }

  /// Get per-animal financial tracking
  Future<AnimalFinancials> getAnimalFinancials(
    String animalId,
  ) async {
    final response = await _client
        .from(_transactionsTable)
        .select()
        .eq('animal_id', animalId);
    final transactions = (response as List)
        .map((json) => Transaction.fromSupabase(json))
        .toList();

    double totalIncome = 0;
    double totalInvestment = 0;
    double feedCosts = 0;
    double medicalCosts = 0;
    double otherCosts = 0;

    for (final t in transactions) {
      if (t.isIncome) {
        totalIncome += t.amount;
      } else {
        totalInvestment += t.amount;

        // Categorize expenses
        if (t.category == ExpenseCategory.feed.name) {
          feedCosts += t.amount;
        } else if (t.category == ExpenseCategory.veterinary.name ||
            t.category == ExpenseCategory.medication.name) {
          medicalCosts += t.amount;
        } else {
          otherCosts += t.amount;
        }
      }
    }

    return AnimalFinancials(
      animalId: animalId,
      totalInvestment: totalInvestment,
      totalIncome: totalIncome,
      feedCosts: feedCosts,
      medicalCosts: medicalCosts,
      otherCosts: otherCosts,
      netValue: totalIncome - totalInvestment,
    );
  }

  /// Get top expense categories
  Future<Map<String, double>> getTopExpenseCategories(
    String farmId, {
    int limit = 5,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final summary = await getFinancialSummary(
      farmId,
      startDate: startDate,
      endDate: endDate,
    );

    final sorted = summary.expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sorted.take(limit));
  }

  // ==================== BUDGETS ====================

  /// Watch budget for a specific month
  Stream<Budget?> watchBudget(String farmId, int year, int month) {
    return _client
        .from(_budgetsTable)
        .stream(primaryKey: ['id'])
        .eq('farm_id', farmId)
        .asyncMap((data) async {
          final response = await _client
              .from(_budgetsTable)
              .select()
              .eq('farm_id', farmId)
              .eq('year', year)
              .eq('month', month)
              .maybeSingle();

          if (response == null) return null;
          return Budget.fromSupabase(response);
        });
  }

  /// Get budget for a specific month
  Future<Budget?> getBudget(String farmId, int year, int month) async {
    final response = await _client
        .from(_budgetsTable)
        .select()
        .eq('farm_id', farmId)
        .eq('year', year)
        .eq('month', month)
        .maybeSingle();

    if (response == null) return null;
    return Budget.fromSupabase(response);
  }

  /// Set budget for a month
  Future<void> setBudget(Budget budget) async {
    final existing = await getBudget(budget.farmId, budget.year, budget.month);

    if (existing != null) {
      await _client
          .from(_budgetsTable)
          .update(budget.toSupabase())
          .eq('id', existing.id);
    } else {
      await _client.from(_budgetsTable).insert(budget.toSupabase());
    }
  }

  /// Get budget vs actual comparison
  Future<BudgetComparison> getBudgetComparison(
    String farmId,
    int year,
    int month,
  ) async {
    final budget = await getBudget(farmId, year, month);
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final summary = await getFinancialSummary(
      farmId,
      startDate: startDate,
      endDate: endDate,
    );

    return BudgetComparison(
      budget: budget,
      actualExpenses: summary.totalExpenses,
      expensesByCategory: summary.expensesByCategory,
    );
  }
}

/// Budget vs actual comparison
class BudgetComparison {
  final Budget? budget;
  final double actualExpenses;
  final Map<String, double> expensesByCategory;

  BudgetComparison({
    this.budget,
    required this.actualExpenses,
    required this.expensesByCategory,
  });

  /// Total budget amount
  double get totalBudget => budget?.totalBudget ?? 0;

  /// Remaining budget
  double get remaining => totalBudget - actualExpenses;

  /// Budget usage percentage
  double get usagePercentage {
    if (totalBudget == 0) return 0;
    return (actualExpenses / totalBudget) * 100;
  }

  /// Check if over budget
  bool get isOverBudget => actualExpenses > totalBudget;

  /// Get category-specific comparison
  Map<String, CategoryBudgetStatus> getCategoryStatuses() {
    if (budget == null) return {};

    final statuses = <String, CategoryBudgetStatus>{};

    for (final entry in budget!.categoryBudgets.entries) {
      final actual = expensesByCategory[entry.key] ?? 0;
      statuses[entry.key] = CategoryBudgetStatus(
        budgeted: entry.value,
        actual: actual,
      );
    }

    return statuses;
  }
}

/// Status of a single budget category
class CategoryBudgetStatus {
  final double budgeted;
  final double actual;

  CategoryBudgetStatus({required this.budgeted, required this.actual});

  double get remaining => budgeted - actual;
  double get usagePercentage => budgeted > 0 ? (actual / budgeted) * 100 : 0;
  bool get isOverBudget => actual > budgeted;
}
