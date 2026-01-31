import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../repositories/financial_repository.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    // Use family providers with selected year/month for consistency
    final budgetAsync = ref.watch(
      monthBudgetProvider((_selectedYear, _selectedMonth)),
    );
    final comparisonAsync = ref.watch(
      monthBudgetWithComparisonProvider((_selectedYear, _selectedMonth)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Planning'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create Budget',
            onPressed: () => _showCreateBudgetDialog(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Month Selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _previousMonth,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        DateFormat(
                          'MMMM yyyy',
                        ).format(DateTime(_selectedYear, _selectedMonth)),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Current Budget Status
          budgetAsync.when(
            data: (budget) => budget != null
                ? _buildBudgetCard(budget, comparisonAsync)
                : _buildNoBudgetCard(),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $e'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth--;
      if (_selectedMonth < 1) {
        _selectedMonth = 12;
        _selectedYear--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth++;
      if (_selectedMonth > 12) {
        _selectedMonth = 1;
        _selectedYear++;
      }
    });
  }

  Widget _buildNoBudgetCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No Budget Set',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a budget to track your spending against targets',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _showCreateBudgetDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Budget'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(
    Budget budget,
    AsyncValue<BudgetComparison?> comparisonAsync,
  ) {
    final formatter = ref.watch(currencyFormatterProvider);

    return Column(
      children: [
        // Overall Budget
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Budget',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditBudgetDialog(context, budget),
                    ),
                  ],
                ),
                const Divider(),
                Text(
                  formatter.format(budget.totalBudget),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),

                // Budget vs Actual
                comparisonAsync.when(
                  data: (comparison) {
                    if (comparison == null) {
                      return const Text('No spending data yet');
                    }
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Spent: ${formatter.format(comparison.actualExpenses)}',
                            ),
                            Text(
                              'Remaining: ${formatter.format(comparison.remaining)}',
                              style: TextStyle(
                                color: comparison.isOverBudget
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (comparison.usagePercentage / 100).clamp(
                              0.0,
                              1.0,
                            ),
                            minHeight: 12,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              comparison.isOverBudget
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${comparison.usagePercentage.toStringAsFixed(1)}% used',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Category Budgets
        if (budget.categoryBudgets.isNotEmpty) ...[
          const Text(
            'Category Budgets',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...budget.categoryBudgets.entries.map((entry) {
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.2),
                  child: const Icon(Icons.category, color: Colors.blue),
                ),
                title: Text(_formatCategoryString(entry.key)),
                subtitle: Text(formatter.format(entry.value)),
                trailing: comparisonAsync.whenOrNull(
                  data: (comparison) {
                    if (comparison == null) return null;
                    final statuses = comparison.getCategoryStatuses();
                    final status = statuses[entry.key];
                    if (status == null) return null;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: status.isOverBudget
                            ? Colors.red.withValues(alpha: 0.2)
                            : Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${status.usagePercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: status.isOverBudget
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  void _showCreateBudgetDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _BudgetFormSheet(year: _selectedYear, month: _selectedMonth),
    );
  }

  void _showEditBudgetDialog(BuildContext context, Budget budget) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BudgetFormSheet(
        year: _selectedYear,
        month: _selectedMonth,
        existingBudget: budget,
      ),
    );
  }

  String _formatCategoryString(String category) {
    try {
      final expenseCategory = ExpenseCategory.values.firstWhere(
        (e) => e.name == category,
      );
      switch (expenseCategory) {
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
    } catch (_) {
      return category.isNotEmpty
          ? '${category[0].toUpperCase()}${category.substring(1)}'
          : category;
    }
  }
}

class _BudgetFormSheet extends ConsumerStatefulWidget {
  final int year;
  final int month;
  final Budget? existingBudget;

  const _BudgetFormSheet({
    required this.year,
    required this.month,
    this.existingBudget,
  });

  @override
  ConsumerState<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<_BudgetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _totalBudgetController = TextEditingController();
  final Map<ExpenseCategory, TextEditingController> _categoryControllers = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers for each category
    for (final category in ExpenseCategory.values) {
      _categoryControllers[category] = TextEditingController();
    }

    // Pre-fill if editing
    if (widget.existingBudget != null) {
      _totalBudgetController.text = widget.existingBudget!.totalBudget
          .toString();
      for (final entry in widget.existingBudget!.categoryBudgets.entries) {
        // Find the category by name
        try {
          final category = ExpenseCategory.values.firstWhere(
            (c) => c.name == entry.key,
          );
          _categoryControllers[category]?.text = entry.value.toString();
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _totalBudgetController.dispose();
    for (final controller in _categoryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEditing = widget.existingBudget != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Gradient Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo, Colors.indigo.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEditing
                          ? Icons.edit_calendar_rounded
                          : Icons.add_chart_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Budget' : 'Create Budget',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'MMMM yyyy',
                          ).format(DateTime(widget.year, widget.month)),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Total Budget Section
                    _buildSectionHeader(
                      context,
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Total Budget',
                      color: Colors.indigo,
                    ),
                    const SizedBox(height: 12),
                    _buildModernTextField(
                      controller: _totalBudgetController,
                      label: 'Monthly Budget',
                      hint: 'Enter total monthly budget',
                      icon: Icons.payments_outlined,
                      colorScheme: colorScheme,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final amount = double.tryParse(v);
                        if (amount == null || amount <= 0) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Category Budgets Section
                    _buildSectionHeader(
                      context,
                      icon: Icons.pie_chart_rounded,
                      title: 'Category Budgets',
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.purple.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: Colors.purple.shade300,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Set specific limits for each expense category (optional)',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Budget Fields
                    ...ExpenseCategory.values.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCategoryField(
                          category: category,
                          colorScheme: colorScheme,
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    // Submit Button
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isEditing
                                      ? Icons.update_rounded
                                      : Icons.add_chart_rounded,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isEditing ? 'Update Budget' : 'Create Budget',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ColorScheme colorScheme,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.indigo, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.indigo),
        ),
      ),
    );
  }

  Widget _buildCategoryField({
    required ExpenseCategory category,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getCategoryColor(category).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCategoryIcon(category),
              size: 18,
              color: _getCategoryColor(category),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _formatCategory(category),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(
            width: 120,
            child: TextFormField(
              controller: _categoryControllers[category],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.end,
              decoration: InputDecoration(
                hintText: '0.00',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _getCategoryColor(category),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.feed:
        return Colors.green;
      case ExpenseCategory.veterinary:
        return Colors.red;
      case ExpenseCategory.medication:
        return Colors.pink;
      case ExpenseCategory.equipment:
        return Colors.blue;
      case ExpenseCategory.supplies:
        return Colors.orange;
      case ExpenseCategory.labor:
        return Colors.purple;
      case ExpenseCategory.utilities:
        return Colors.amber;
      case ExpenseCategory.transport:
        return Colors.teal;
      case ExpenseCategory.maintenance:
        return Colors.brown;
      case ExpenseCategory.insurance:
        return Colors.indigo;
      case ExpenseCategory.taxes:
        return Colors.grey;
      case ExpenseCategory.other:
        return Colors.blueGrey;
    }
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.feed:
        return Icons.grass_rounded;
      case ExpenseCategory.veterinary:
        return Icons.medical_services_rounded;
      case ExpenseCategory.medication:
        return Icons.medication_rounded;
      case ExpenseCategory.equipment:
        return Icons.build_rounded;
      case ExpenseCategory.supplies:
        return Icons.inventory_rounded;
      case ExpenseCategory.labor:
        return Icons.person_rounded;
      case ExpenseCategory.utilities:
        return Icons.bolt_rounded;
      case ExpenseCategory.transport:
        return Icons.local_shipping_rounded;
      case ExpenseCategory.maintenance:
        return Icons.settings_rounded;
      case ExpenseCategory.insurance:
        return Icons.shield_rounded;
      case ExpenseCategory.taxes:
        return Icons.receipt_long_rounded;
      case ExpenseCategory.other:
        return Icons.more_horiz_rounded;
    }
  }

  String _formatCategory(ExpenseCategory category) {
    switch (category) {
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final farmId = ref.read(activeFarmIdProvider);
      if (farmId == null) throw Exception('No farm selected');

      // Build category budgets as Map<String, double>
      final categoryBudgets = <String, double>{};
      for (final entry in _categoryControllers.entries) {
        final text = entry.value.text.trim();
        if (text.isNotEmpty) {
          final amount = double.tryParse(text);
          if (amount != null && amount > 0) {
            categoryBudgets[entry.key.name] = amount;
          }
        }
      }

      final budget = Budget(
        id: widget.existingBudget?.id ?? '',
        farmId: farmId,
        year: widget.year,
        month: widget.month,
        totalBudget: double.parse(_totalBudgetController.text),
        categoryBudgets: categoryBudgets,
        createdAt: widget.existingBudget?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final repository = ref.read(financialRepositoryProvider);
      await repository.setBudget(budget);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green.shade100,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.existingBudget != null
                      ? 'Budget updated successfully!'
                      : 'Budget created successfully!',
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_rounded, color: Colors.red.shade100, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }
}
