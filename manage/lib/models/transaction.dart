/// Type of financial transaction
enum TransactionType { income, expense }

/// Categories for expense transactions
enum ExpenseCategory {
  feed,
  veterinary,
  medication,
  equipment,
  supplies,
  labor,
  utilities,
  transport,
  maintenance,
  insurance,
  taxes,
  other,
}

/// Categories for income transactions
enum IncomeCategory {
  animalSale,
  breedingService,
  milkSale,
  eggSale,
  manureSale,
  byProductSale,
  subsidyGrant,
  other,
}

/// Payment method for transactions
enum PaymentMethod { cash, bankTransfer, mobileMoney, cheque, credit, other }

/// Financial transaction model
class Transaction {
  final String id;
  final String farmId;
  final DateTime date;
  final TransactionType type;
  final String category; // ExpenseCategory or IncomeCategory as string
  final double amount;
  final String? animalId; // Link to specific animal if applicable (optional)
  final String description;
  final PaymentMethod? paymentMethod;
  final String? referenceNumber; // Invoice/receipt number
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    required this.id,
    required this.farmId,
    required this.date,
    required this.type,
    required this.category,
    required this.amount,
    this.animalId,
    required this.description,
    this.paymentMethod,
    this.referenceNumber,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromSupabase(Map<String, dynamic> data) {
    return Transaction(
      id: data['id'] ?? '',
      farmId: data['farm_id'] ?? '',
      date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
      type: TransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransactionType.expense,
      ),
      category: data['category'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      animalId: data['animal_id'],
      description: data['description'] ?? '',
      paymentMethod: data['payment_method'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.name == data['payment_method'],
              orElse: () => PaymentMethod.other,
            )
          : null,
      referenceNumber: data['reference_number'],
      notes: data['notes'],
      createdAt: DateTime.parse(
        data['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        data['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'farm_id': farmId,
      'date': date.toIso8601String(),
      'type': type.name,
      'category': category,
      'amount': amount,
      if (animalId != null) 'animal_id': animalId,
      'description': description,
      if (paymentMethod != null) 'payment_method': paymentMethod!.name,
      if (referenceNumber != null) 'reference_number': referenceNumber,
      if (notes != null) 'notes': notes,
    };
  }

  Transaction copyWith({
    String? id,
    String? farmId,
    DateTime? date,
    TransactionType? type,
    String? category,
    double? amount,
    String? animalId,
    String? description,
    PaymentMethod? paymentMethod,
    String? referenceNumber,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      date: date ?? this.date,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      animalId: animalId ?? this.animalId,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isIncome => type == TransactionType.income;

  bool get isExpense => type == TransactionType.expense;

  String get formattedAmount {
    final sign = isIncome ? '+' : '-';
    return '$sign\$${amount.toStringAsFixed(2)}';
  }

  String get categoryDisplayName {
    try {
      final expenseCategory = ExpenseCategory.values.firstWhere(
        (e) => e.name == category,
      );
      return _formatExpenseCategory(expenseCategory);
    } catch (_) {}

    try {
      final incomeCategory = IncomeCategory.values.firstWhere(
        (e) => e.name == category,
      );
      return _formatIncomeCategory(incomeCategory);
    } catch (_) {}

    return category;
  }

  String _formatExpenseCategory(ExpenseCategory cat) {
    switch (cat) {
      case ExpenseCategory.feed:
        return 'Feed';
      case ExpenseCategory.veterinary:
        return 'Veterinary';
      case ExpenseCategory.medication:
        return 'Medication';
      case ExpenseCategory.equipment:
        return 'Equipment';
      case ExpenseCategory.supplies:
        return 'Supplies';
      case ExpenseCategory.labor:
        return 'Labor';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.maintenance:
        return 'Maintenance';
      case ExpenseCategory.insurance:
        return 'Insurance';
      case ExpenseCategory.taxes:
        return 'Taxes';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  String _formatIncomeCategory(IncomeCategory cat) {
    switch (cat) {
      case IncomeCategory.animalSale:
        return 'Animal Sale';
      case IncomeCategory.breedingService:
        return 'Breeding Service';
      case IncomeCategory.milkSale:
        return 'Milk Sale';
      case IncomeCategory.eggSale:
        return 'Egg Sale';
      case IncomeCategory.manureSale:
        return 'Manure Sale';
      case IncomeCategory.byProductSale:
        return 'By-Product Sale';
      case IncomeCategory.subsidyGrant:
        return 'Subsidy/Grant';
      case IncomeCategory.other:
        return 'Other';
    }
  }
}

class Budget {
  final String id;
  final String farmId;
  final int year;
  final int month;
  final Map<String, double> categoryBudgets;
  final double totalBudget;
  final DateTime createdAt;
  final DateTime updatedAt;

  Budget({
    required this.id,
    required this.farmId,
    required this.year,
    required this.month,
    required this.categoryBudgets,
    required this.totalBudget,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Budget.fromSupabase(Map<String, dynamic> data) {
    final rawCategoryBudgets =
        data['category_budgets'] as Map<String, dynamic>? ?? {};
    final categoryBudgets = rawCategoryBudgets.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    return Budget(
      id: data['id'] ?? '',
      farmId: data['farm_id'] ?? '',
      year: data['year'] ?? DateTime.now().year,
      month: data['month'] ?? DateTime.now().month,
      categoryBudgets: categoryBudgets,
      totalBudget: (data['total_budget'] ?? 0).toDouble(),
      createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(data['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'farm_id': farmId,
      'year': year,
      'month': month,
      'category_budgets': categoryBudgets,
      'total_budget': totalBudget,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class FinancialSummary {
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final Map<String, double> incomeByCategory;
  final Map<String, double> expensesByCategory;
  final int transactionCount;

  FinancialSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
    required this.incomeByCategory,
    required this.expensesByCategory,
    required this.transactionCount,
  });

  double get profitMargin {
    if (totalIncome == 0) return 0;
    return (netProfit / totalIncome) * 100;
  }

  bool get isProfitable => netProfit > 0;
}

class AnimalFinancials {
  final String animalId;
  final String animalTagId;
  final double totalInvestment;
  final double totalIncome;
  final double feedCosts;
  final double medicalCosts;
  final double otherCosts;
  final double netValue;

  AnimalFinancials({
    required this.animalId,
    required this.animalTagId,
    required this.totalInvestment,
    required this.totalIncome,
    required this.feedCosts,
    required this.medicalCosts,
    required this.otherCosts,
    required this.netValue,
  });

  /// Return on investment percentage
  double get roi {
    if (totalInvestment == 0) return 0;
    return ((totalIncome - totalInvestment) / totalInvestment) * 100;
  }

  bool get isProfitable => netValue > 0;
}
