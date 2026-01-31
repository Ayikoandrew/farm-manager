import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

class AddTransactionDialog extends ConsumerStatefulWidget {
  final String? animalId;

  const AddTransactionDialog({super.key, this.animalId});

  @override
  ConsumerState<AddTransactionDialog> createState() =>
      _AddTransactionDialogState();
}

class _AddTransactionDialogState extends ConsumerState<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  ExpenseCategory? _expenseCategory;
  IncomeCategory? _incomeCategory;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  DateTime _date = DateTime.now();
  String? _selectedAnimalId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedAnimalId = widget.animalId;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Color get _themeColor =>
      _type == TransactionType.income ? Colors.green : Colors.red;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final animalsAsync = ref.watch(animalsProvider);

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
                  colors: [_themeColor, _themeColor.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _themeColor.withValues(alpha: 0.3),
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
                      _type == TransactionType.income
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
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
                          'Add Transaction',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _type == TransactionType.income
                              ? 'Record farm income'
                              : 'Record farm expense',
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
                    // Transaction Type Toggle
                    _buildSectionHeader(
                      context,
                      icon: Icons.swap_horiz_rounded,
                      title: 'Transaction Type',
                      color: _themeColor,
                    ),
                    const SizedBox(height: 12),
                    _buildTransactionTypeSelector(colorScheme),
                    const SizedBox(height: 24),

                    // Description & Amount
                    _buildSectionHeader(
                      context,
                      icon: Icons.edit_note_rounded,
                      title: 'Details',
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildModernTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'e.g., Monthly feed purchase',
                      icon: Icons.description_outlined,
                      colorScheme: colorScheme,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildModernTextField(
                      controller: _amountController,
                      label: 'Amount',
                      hint: '0.00',
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

                    // Category
                    _buildSectionHeader(
                      context,
                      icon: Icons.category_rounded,
                      title: 'Category',
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 12),
                    _buildCategorySelector(colorScheme),
                    const SizedBox(height: 24),

                    // Date & Payment
                    _buildSectionHeader(
                      context,
                      icon: Icons.calendar_today_rounded,
                      title: 'Date & Payment',
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(height: 12),
                    _buildDateSelector(colorScheme),
                    const SizedBox(height: 12),
                    _buildPaymentMethodSelector(colorScheme),
                    const SizedBox(height: 24),

                    // Additional Details
                    _buildSectionHeader(
                      context,
                      icon: Icons.more_horiz_rounded,
                      title: 'Additional Details',
                      color: Colors.teal,
                    ),
                    const SizedBox(height: 12),
                    _buildModernTextField(
                      controller: _referenceController,
                      label: 'Reference Number',
                      hint: 'e.g., Invoice #12345',
                      icon: Icons.receipt_long_outlined,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 12),
                    _buildAnimalSelector(animalsAsync, colorScheme),
                    const SizedBox(height: 12),
                    _buildModernTextField(
                      controller: _notesController,
                      label: 'Notes (Optional)',
                      hint: 'Add any additional notes...',
                      icon: Icons.notes_outlined,
                      colorScheme: colorScheme,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    _buildSubmitButton(colorScheme),
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

  Widget _buildTransactionTypeSelector(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildTypeCard(
            type: TransactionType.expense,
            icon: Icons.trending_down_rounded,
            label: 'Expense',
            color: Colors.red,
            colorScheme: colorScheme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTypeCard(
            type: TransactionType.income,
            icon: Icons.trending_up_rounded,
            label: 'Income',
            color: Colors.green,
            colorScheme: colorScheme,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required TransactionType type,
    required IconData icon,
    required String label,
    required Color color,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _type == type;
    return InkWell(
      onTap: () {
        setState(() {
          _type = type;
          _expenseCategory = null;
          _incomeCategory = null;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : colorScheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
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
          borderSide: BorderSide(color: _themeColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _themeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: _themeColor),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(ColorScheme colorScheme) {
    if (_type == TransactionType.expense) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: ExpenseCategory.values.map((category) {
          final isSelected = _expenseCategory == category;
          return FilterChip(
            label: Text(_formatExpenseCategory(category)),
            selected: isSelected,
            onSelected: (selected) {
              setState(() => _expenseCategory = selected ? category : null);
            },
            selectedColor: Colors.red.withValues(alpha: 0.2),
            checkmarkColor: Colors.red,
            side: BorderSide(
              color: isSelected ? Colors.red : Colors.transparent,
            ),
            avatar: isSelected
                ? null
                : Icon(
                    _getExpenseCategoryIcon(category),
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
          );
        }).toList(),
      );
    } else {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: IncomeCategory.values.map((category) {
          final isSelected = _incomeCategory == category;
          return FilterChip(
            label: Text(_formatIncomeCategory(category)),
            selected: isSelected,
            onSelected: (selected) {
              setState(() => _incomeCategory = selected ? category : null);
            },
            selectedColor: Colors.green.withValues(alpha: 0.2),
            checkmarkColor: Colors.green,
            side: BorderSide(
              color: isSelected ? Colors.green : Colors.transparent,
            ),
            avatar: isSelected
                ? null
                : Icon(
                    _getIncomeCategoryIcon(category),
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
          );
        }).toList(),
      );
    }
  }

  Widget _buildDateSelector(ColorScheme colorScheme) {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                color: Colors.amber.shade700,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction Date',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMMM d, y').format(_date),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<PaymentMethod>(
        initialValue: _paymentMethod,
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.payment_rounded,
              size: 20,
              color: Colors.indigo,
            ),
          ),
          labelText: 'Payment Method',
        ),
        isExpanded: true,
        items: PaymentMethod.values
            .map(
              (m) => DropdownMenuItem(
                value: m,
                child: Row(
                  children: [
                    Icon(
                      _getPaymentMethodIcon(m),
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Text(_formatPaymentMethod(m)),
                  ],
                ),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => _paymentMethod = v ?? _paymentMethod),
      ),
    );
  }

  Widget _buildAnimalSelector(
    AsyncValue<List<Animal>> animalsAsync,
    ColorScheme colorScheme,
  ) {
    return animalsAsync.when(
      data: (animals) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonFormField<String>(
          initialValue: _selectedAnimalId,
          decoration: InputDecoration(
            border: InputBorder.none,
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.pets_rounded,
                size: 20,
                color: Colors.teal,
              ),
            ),
            labelText: 'Related Animal (Optional)',
          ),
          isExpanded: true,
          items: [
            const DropdownMenuItem(value: null, child: Text('None')),
            ...animals.map(
              (a) => DropdownMenuItem(
                value: a.id,
                child: Text(
                  '${a.tagId} (${a.breed ?? a.species.displayName})',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _selectedAnimalId = v),
        ),
      ),
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => const SizedBox(),
    );
  }

  Widget _buildSubmitButton(ColorScheme colorScheme) {
    return FilledButton(
      onPressed: _isSubmitting ? null : _submitForm,
      style: FilledButton.styleFrom(
        backgroundColor: _themeColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  _type == TransactionType.income
                      ? Icons.add_circle_outline_rounded
                      : Icons.remove_circle_outline_rounded,
                ),
                const SizedBox(width: 8),
                Text(
                  'Save ${_type == TransactionType.income ? 'Income' : 'Expense'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  IconData _getExpenseCategoryIcon(ExpenseCategory category) {
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

  IconData _getIncomeCategoryIcon(IncomeCategory category) {
    switch (category) {
      case IncomeCategory.animalSale:
        return Icons.pets_rounded;
      case IncomeCategory.breedingService:
        return Icons.favorite_rounded;
      case IncomeCategory.milkSale:
        return Icons.water_drop_rounded;
      case IncomeCategory.eggSale:
        return Icons.egg_rounded;
      case IncomeCategory.manureSale:
        return Icons.compost_rounded;
      case IncomeCategory.byProductSale:
        return Icons.category_rounded;
      case IncomeCategory.subsidyGrant:
        return Icons.account_balance_rounded;
      case IncomeCategory.other:
        return Icons.more_horiz_rounded;
    }
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.payments_rounded;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance_rounded;
      case PaymentMethod.mobileMoney:
        return Icons.phone_android_rounded;
      case PaymentMethod.cheque:
        return Icons.receipt_rounded;
      case PaymentMethod.credit:
        return Icons.credit_card_rounded;
      case PaymentMethod.other:
        return Icons.more_horiz_rounded;
    }
  }

  String _formatExpenseCategory(ExpenseCategory category) {
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

  String _formatIncomeCategory(IncomeCategory category) {
    switch (category) {
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
  }

  String _formatPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.cheque:
        return 'Cheque';
      case PaymentMethod.credit:
        return 'Credit';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  Future<void> _submitForm() async {
    // Validate category is selected
    if (_type == TransactionType.expense && _expenseCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade100,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text('Please select a category'),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (_type == TransactionType.income && _incomeCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade100,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text('Please select a category'),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final farmId = ref.read(activeFarmIdProvider);
      if (farmId == null) throw Exception('No farm selected');

      // Determine the category string
      final category = _type == TransactionType.expense
          ? _expenseCategory!.name
          : _incomeCategory!.name;

      final transaction = Transaction(
        id: '',
        farmId: farmId,
        type: _type,
        category: category,
        amount: double.parse(_amountController.text),
        description: _descriptionController.text.trim(),
        date: _date,
        paymentMethod: _paymentMethod,
        animalId:
            _selectedAnimalId, // Optional - only if expense is for specific animal
        referenceNumber: _referenceController.text.isNotEmpty
            ? _referenceController.text.trim()
            : null,
        notes: _notesController.text.isNotEmpty
            ? _notesController.text.trim()
            : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final repository = ref.read(financialRepositoryProvider);
      await repository.addTransaction(transaction);

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
                  _type == TransactionType.income
                      ? 'Income recorded successfully!'
                      : 'Expense recorded successfully!',
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
