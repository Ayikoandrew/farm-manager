import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../repositories/financial_repository.dart';
import '../../utils/seo_helper.dart';

class FinancialReportsScreen extends ConsumerStatefulWidget {
  const FinancialReportsScreen({super.key});

  @override
  ConsumerState<FinancialReportsScreen> createState() =>
      _FinancialReportsScreenState();
}

class _FinancialReportsScreenState
    extends ConsumerState<FinancialReportsScreen> {
  int _selectedBudgetMonth = DateTime.now().month;
  int _selectedBudgetYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    SeoHelper.configureFinancialPage();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the date range from provider
    final dateRange = ref.watch(reportDateRangeProvider);
    // Watch financial summary for the selected date range
    final summaryAsync = ref.watch(dateRangeFinancialSummaryProvider);
    // Watch previous period summary for trend comparison
    final previousSummaryAsync = ref.watch(
      previousPeriodFinancialSummaryProvider,
    );
    // Watch top expenses for the selected date range
    final topExpensesAsync = ref.watch(dateRangeTopExpensesProvider);
    // Watch budget comparison for selected month
    final budgetComparisonAsync = ref.watch(
      monthBudgetComparisonProvider((
        _selectedBudgetYear,
        _selectedBudgetMonth,
      )),
    );
    // Watch monthly summaries for current year
    final monthlySummariesAsync = ref.watch(
      yearlyMonthlySummariesProvider(DateTime.now().year),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Select Date Range',
            onPressed: () => _selectDateRange(context, dateRange),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dateRangeFinancialSummaryProvider);
          ref.invalidate(dateRangeTopExpensesProvider);
          ref.invalidate(
            monthBudgetComparisonProvider((
              _selectedBudgetYear,
              _selectedBudgetMonth,
            )),
          );
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date Range Display
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: const Text('Report Period'),
                subtitle: Text(
                  '${DateFormat('MMM d, yyyy').format(dateRange.start)} - ${DateFormat('MMM d, yyyy').format(dateRange.end)}',
                ),
                trailing: const Icon(Icons.edit),
                onTap: () => _selectDateRange(context, dateRange),
              ),
            ),
            const SizedBox(height: 16),

            // Financial Summary for Date Range
            summaryAsync.when(
              data: (summary) {
                if (summary == null) {
                  return _buildEmptyCard('No transactions in this period');
                }
                // Get previous period data for trend comparison
                final previousSummary = previousSummaryAsync.when(
                  data: (data) => data,
                  loading: () => null,
                  error: (e, st) => null,
                );
                return _buildSummarySection(
                  summary,
                  previousSummary: previousSummary,
                );
              },
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => _buildErrorCard('Error loading summary: $e'),
            ),
            const SizedBox(height: 24),

            // Budget vs Actual Section
            _buildBudgetMonthSelector(),
            const SizedBox(height: 8),
            budgetComparisonAsync.when(
              data: (comparison) =>
                  comparison != null && comparison.budget != null
                  ? _buildBudgetComparison(comparison)
                  : _buildNoBudgetCard(),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => _buildErrorCard('Error loading budget: $e'),
            ),
            const SizedBox(height: 24),

            // Top Expense Categories
            const Text(
              'Top Expense Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            topExpensesAsync.when(
              data: (expenses) => expenses.isNotEmpty
                  ? _buildExpenseCategoriesChart(expenses)
                  : _buildEmptyCard('No expenses in this period'),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => _buildErrorCard('Error loading expenses: $e'),
            ),
            const SizedBox(height: 24),

            // Monthly Trend
            const Text(
              'Monthly Trend (This Year)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            monthlySummariesAsync.when(
              data: (summaries) => summaries.isNotEmpty
                  ? _buildMonthlyTrend(summaries)
                  : _buildEmptyCard('No monthly data available'),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => _buildErrorCard('Error loading trends: $e'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetMonthSelector() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Budget vs Actual',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        // Month/Year selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            onTap: _selectBudgetMonth,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat(
                    'MMM yyyy',
                  ).format(DateTime(_selectedBudgetYear, _selectedBudgetMonth)),
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, color: Colors.blue),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoBudgetCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No budget set for ${DateFormat('MMMM yyyy').format(DateTime(_selectedBudgetYear, _selectedBudgetMonth))}',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                // Navigate to budget screen
                Navigator.pop(context);
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Budget'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(message, style: TextStyle(color: Colors.grey[600])),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      color: Colors.red.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange(
    BuildContext context,
    DateTimeRange currentRange,
  ) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: currentRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: Colors.blue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // Update the provider instead of local state
      ref.read(reportDateRangeProvider.notifier).setDateRange(picked);
    }
  }

  Future<void> _selectBudgetMonth() async {
    final now = DateTime.now();
    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) => _MonthYearPickerDialog(
        initialYear: _selectedBudgetYear,
        initialMonth: _selectedBudgetMonth,
        firstYear: 2020,
        lastYear: now.year,
      ),
    );
    if (result != null) {
      setState(() {
        _selectedBudgetYear = result.year;
        _selectedBudgetMonth = result.month;
      });
    }
  }

  /// Calculate percentage change between current and previous values
  double? _calculatePercentageChange(double current, double previous) {
    if (previous == 0) return current > 0 ? 100 : null;
    return ((current - previous) / previous) * 100;
  }

  /// Build a trend indicator widget
  Widget _buildTrendIndicator(
    double? percentageChange, {
    bool inverseColors = false,
  }) {
    if (percentageChange == null) {
      return const SizedBox.shrink();
    }

    final isPositive = percentageChange >= 0;
    // For expenses, positive (increase) is bad, so we invert colors
    final isGood = inverseColors ? !isPositive : isPositive;
    final color = isGood ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 2),
          Text(
            '${percentageChange.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(
    FinancialSummary summary, {
    FinancialSummary? previousSummary,
  }) {
    final formatter = ref.watch(currencyFormatterProvider);

    // Calculate trend percentages
    final incomeChange = previousSummary != null
        ? _calculatePercentageChange(
            summary.totalIncome,
            previousSummary.totalIncome,
          )
        : null;
    final expenseChange = previousSummary != null
        ? _calculatePercentageChange(
            summary.totalExpenses,
            previousSummary.totalExpenses,
          )
        : null;
    final profitChange =
        previousSummary != null && previousSummary.netProfit != 0
        ? _calculatePercentageChange(
            summary.netProfit,
            previousSummary.netProfit,
          )
        : null;
    final transactionChange = previousSummary != null
        ? _calculatePercentageChange(
            summary.transactionCount.toDouble(),
            previousSummary.transactionCount.toDouble(),
          )
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Financial Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (previousSummary != null)
                  Text(
                    'vs previous period',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
              ],
            ),
            const Divider(),
            _buildSummaryRowWithTrend(
              'Total Income',
              formatter.format(summary.totalIncome),
              Colors.green,
              incomeChange,
              inverseColors: false, // Higher income is good
            ),
            _buildSummaryRowWithTrend(
              'Total Expenses',
              formatter.format(summary.totalExpenses),
              Colors.red,
              expenseChange,
              inverseColors: true, // Higher expenses is bad
            ),
            const Divider(),
            _buildSummaryRowWithTrend(
              'Net Profit',
              formatter.format(summary.netProfit),
              summary.isProfitable ? Colors.green : Colors.red,
              profitChange,
              isBold: true,
              inverseColors: false, // Higher profit is good
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatCardWithTrend(
                    'Transactions',
                    summary.transactionCount.toString(),
                    Icons.receipt_long,
                    Colors.blue,
                    transactionChange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Profit Margin',
                    '${summary.profitMargin.toStringAsFixed(1)}%',
                    summary.isProfitable
                        ? Icons.trending_up
                        : Icons.trending_down,
                    summary.isProfitable ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRowWithTrend(
    String label,
    String value,
    Color color,
    double? percentageChange, {
    bool isBold = false,
    bool inverseColors = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          _buildTrendIndicator(percentageChange, inverseColors: inverseColors),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color,
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardWithTrend(
    String label,
    String value,
    IconData icon,
    Color color,
    double? percentageChange,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          if (percentageChange != null) ...[
            const SizedBox(height: 4),
            _buildTrendIndicator(percentageChange),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBudgetComparison(BudgetComparison comparison) {
    final formatter = ref.watch(currencyFormatterProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Overall Budget Status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budgeted: ${formatter.format(comparison.totalBudget)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        'Actual: ${formatter.format(comparison.actualExpenses)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: comparison.isOverBudget
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: comparison.isOverBudget
                        ? Colors.red.withValues(alpha: 0.2)
                        : Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    comparison.isOverBudget
                        ? '${formatter.format(-comparison.remaining)} Over'
                        : '${formatter.format(comparison.remaining)} Under',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: comparison.isOverBudget
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (comparison.usagePercentage / 100).clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  comparison.isOverBudget ? Colors.red : Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${comparison.usagePercentage.toStringAsFixed(1)}% used',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Category Breakdown
            if (comparison.budget != null &&
                comparison.budget!.categoryBudgets.isNotEmpty) ...[
              const Text(
                'By Category',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...comparison
                  .getCategoryStatuses()
                  .entries
                  .take(5)
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(_formatCategoryString(entry.key)),
                          ),
                          Expanded(
                            flex: 3,
                            child: LinearProgressIndicator(
                              value: (entry.value.usagePercentage / 100).clamp(
                                0.0,
                                1.0,
                              ),
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                entry.value.isOverBudget
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${entry.value.usagePercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: entry.value.isOverBudget
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCategoriesChart(Map<String, double> categories) {
    final formatter = ref.watch(currencyFormatterProvider);

    if (categories.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No expenses in this period'),
        ),
      );
    }

    final total = categories.values.fold(0.0, (sum, v) => sum + v);
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];

    final sortedEntries = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: sortedEntries.asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value.key;
            final amount = entry.value.value;
            final percentage = (amount / total * 100);
            final color = colors[index % colors.length];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(_formatCategoryString(category)),
                  ),
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    child: Text(
                      formatter.formatCompact(amount),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 45,
                    child: Text(
                      '${percentage.toStringAsFixed(0)}%',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMonthlyTrend(List<FinancialSummary> summaries) {
    final formatter = ref.watch(currencyFormatterProvider);

    // Filter to only show months with data
    final monthsWithData = summaries
        .where((s) => s.transactionCount > 0)
        .toList();

    if (monthsWithData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No historical data available'),
        ),
      );
    }

    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    // Find max value for scaling
    final maxValue = summaries.fold(0.0, (max, s) {
      final m = [
        s.totalIncome,
        s.totalExpenses,
      ].reduce((a, b) => a > b ? a : b);
      return m > max ? m : max;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Income', Colors.green),
                const SizedBox(width: 24),
                _buildLegendItem('Expenses', Colors.red),
              ],
            ),
            const SizedBox(height: 16),
            // Chart
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: summaries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final summary = entry.value;
                  final incomeHeight = maxValue > 0
                      ? (summary.totalIncome / maxValue * 150)
                      : 0.0;
                  final expenseHeight = maxValue > 0
                      ? (summary.totalExpenses / maxValue * 150)
                      : 0.0;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Income bar
                              Container(
                                width: 8,
                                height: incomeHeight,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 1),
                              // Expense bar
                              Container(
                                width: 8,
                                height: expenseHeight,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            monthNames[index],
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(),
            // Monthly values (only show months with data)
            if (monthsWithData.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  dataTextStyle: const TextStyle(fontSize: 11),
                  columns: const [
                    DataColumn(label: Text('Month')),
                    DataColumn(label: Text('Income'), numeric: true),
                    DataColumn(label: Text('Expenses'), numeric: true),
                    DataColumn(label: Text('Profit'), numeric: true),
                  ],
                  rows: monthsWithData.asMap().entries.map((entry) {
                    final index = summaries.indexOf(entry.value);
                    final s = entry.value;
                    return DataRow(
                      cells: [
                        DataCell(Text(monthNames[index])),
                        DataCell(
                          Text(
                            formatter.formatCompact(s.totalIncome),
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),
                        DataCell(
                          Text(
                            formatter.formatCompact(s.totalExpenses),
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        DataCell(
                          Text(
                            formatter.formatCompact(s.netProfit),
                            style: TextStyle(
                              color: s.isProfitable ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  String _formatCategoryString(String category) {
    // Try to format expense category
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
    } catch (_) {}

    // Try to format income category
    try {
      final incomeCategory = IncomeCategory.values.firstWhere(
        (e) => e.name == category,
      );
      switch (incomeCategory) {
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
          return 'By-product Sale';
        case IncomeCategory.subsidyGrant:
          return 'Subsidy/Grant';
        case IncomeCategory.other:
          return 'Other';
      }
    } catch (_) {}

    // Return as-is with capitalization
    return category.isNotEmpty
        ? '${category[0].toUpperCase()}${category.substring(1)}'
        : category;
  }
}

/// A dialog for picking a month and year
class _MonthYearPickerDialog extends StatefulWidget {
  final int initialYear;
  final int initialMonth;
  final int firstYear;
  final int lastYear;

  const _MonthYearPickerDialog({
    required this.initialYear,
    required this.initialMonth,
    required this.firstYear,
    required this.lastYear,
  });

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;

  final _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    _selectedMonth = widget.initialMonth;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = List.generate(
      widget.lastYear - widget.firstYear + 1,
      (i) => widget.firstYear + i,
    ).reversed.toList();

    return AlertDialog(
      title: const Text('Select Month'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Year selector
            DropdownButtonFormField<int>(
              initialValue: _selectedYear,
              decoration: const InputDecoration(
                labelText: 'Year',
                border: OutlineInputBorder(),
              ),
              items: years.map((year) {
                return DropdownMenuItem(
                  value: year,
                  child: Text(year.toString()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedYear = value;
                    // If selected year is current year, limit months
                    if (_selectedYear == now.year &&
                        _selectedMonth > now.month) {
                      _selectedMonth = now.month;
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            // Month grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                final isSelected = _selectedMonth == month;
                // Disable future months in current year
                final isDisabled =
                    _selectedYear == now.year && month > now.month;

                return InkWell(
                  onTap: isDisabled
                      ? null
                      : () {
                          setState(() => _selectedMonth = month);
                        },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue
                          : isDisabled
                          ? Colors.grey.withValues(alpha: 0.1)
                          : Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _monthNames[index].substring(0, 3),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isDisabled
                            ? Colors.grey
                            : Colors.blue,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, DateTime(_selectedYear, _selectedMonth));
          },
          child: const Text('Select'),
        ),
      ],
    );
  }
}
