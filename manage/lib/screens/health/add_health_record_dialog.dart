import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

class AddHealthRecordDialog extends ConsumerStatefulWidget {
  final String? preselectedAnimalId;
  final HealthRecordType? preselectedType;

  const AddHealthRecordDialog({
    super.key,
    this.preselectedAnimalId,
    this.preselectedType,
  });

  @override
  ConsumerState<AddHealthRecordDialog> createState() =>
      _AddHealthRecordDialogState();
}

class _AddHealthRecordDialogState extends ConsumerState<AddHealthRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notesController;
  late TextEditingController _vaccineNameController;
  late TextEditingController _batchNumberController;
  late TextEditingController _medicationNameController;
  late TextEditingController _dosageController;
  late TextEditingController _frequencyController;
  late TextEditingController _diagnosisController;
  late TextEditingController _treatmentController;
  late TextEditingController _vetNameController;
  late TextEditingController _vetContactController;
  late TextEditingController _costController;

  String? _selectedAnimalId;
  HealthRecordType _recordType = HealthRecordType.vaccination;
  DateTime _recordDate = DateTime.now();
  DateTime? _nextDueDate;
  DateTime? _followUpDate;
  DateTime? _withdrawalEndDate;
  HealthStatus _status = HealthStatus.completed;
  Severity _severity = Severity.low;
  final List<String> _selectedSymptoms = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedAnimalId = widget.preselectedAnimalId;
    if (widget.preselectedType != null) {
      _recordType = widget.preselectedType!;
    }
    _notesController = TextEditingController();
    _vaccineNameController = TextEditingController();
    _batchNumberController = TextEditingController();
    _medicationNameController = TextEditingController();
    _dosageController = TextEditingController();
    _frequencyController = TextEditingController();
    _diagnosisController = TextEditingController();
    _treatmentController = TextEditingController();
    _vetNameController = TextEditingController();
    _vetContactController = TextEditingController();
    _costController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _vaccineNameController.dispose();
    _batchNumberController.dispose();
    _medicationNameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _vetNameController.dispose();
    _vetContactController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animalsAsync = ref.watch(animalsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
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

            // Modern Header with Gradient
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getTypeColor(_recordType),
                    _getTypeColor(_recordType).withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _getTypeColor(_recordType).withValues(alpha: 0.3),
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
                      _getTypeIcon(_recordType),
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
                          'Add Health Record',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Track your animal\'s health',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Record Type Selection
                      _buildSectionHeader(
                        context,
                        icon: Icons.category,
                        title: 'Record Type',
                        color: Colors.purple,
                      ),
                      const SizedBox(height: 12),
                      _buildTypeSelector(),
                      const SizedBox(height: 20),

                      // Animal Selection
                      _buildSectionHeader(
                        context,
                        icon: Icons.pets,
                        title: 'Select Animal',
                        color: Colors.teal,
                      ),
                      const SizedBox(height: 12),
                      animalsAsync.when(
                        data: (animals) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
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
                                  Icons.pets,
                                  size: 20,
                                  color: Colors.teal,
                                ),
                              ),
                            ),
                            hint: const Text('Choose an animal'),
                            isExpanded: true,
                            items: animals
                                .map(
                                  (a) => DropdownMenuItem(
                                    value: a.id,
                                    child: Text(
                                      '${a.tagId} - ${a.breed ?? a.species.displayName}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedAnimalId = v),
                            validator: (v) =>
                                v == null ? 'Select an animal' : null,
                          ),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (e, st) => Text('Error loading animals: $e'),
                      ),
                      const SizedBox(height: 20),

                      // Date Selection
                      _buildSectionHeader(
                        context,
                        icon: Icons.calendar_today,
                        title: 'Date',
                        color: Colors.amber,
                      ),
                      const SizedBox(height: 12),
                      _buildDateSelector(
                        'Record Date',
                        _recordDate,
                        (date) => setState(() => _recordDate = date),
                        Icons.calendar_today,
                      ),
                      const SizedBox(height: 20),

                      // Type-specific fields
                      _buildSectionHeader(
                        context,
                        icon: Icons.assignment,
                        title: '${_formatType(_recordType)} Details',
                        color: _getTypeColor(_recordType),
                      ),
                      const SizedBox(height: 12),
                      ..._buildTypeSpecificFields(),

                      // Status Selection
                      const SizedBox(height: 20),
                      _buildSectionHeader(
                        context,
                        icon: Icons.flag,
                        title: 'Status',
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<HealthStatus>(
                          initialValue: _status,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.flag,
                                size: 20,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          items: HealthStatus.values
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(_formatStatus(s)),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _status = v!),
                        ),
                      ),

                      // Veterinarian Info (optional)
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        context,
                        icon: Icons.person,
                        title: 'Veterinarian (Optional)',
                        color: Colors.cyan,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildModernTextField(
                              context,
                              controller: _vetNameController,
                              label: 'Vet Name',
                              icon: Icons.person,
                              iconColor: Colors.cyan,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildModernTextField(
                              context,
                              controller: _vetContactController,
                              label: 'Vet Contact',
                              icon: Icons.phone,
                              iconColor: Colors.cyan,
                            ),
                          ),
                        ],
                      ),

                      // Cost (optional)
                      const SizedBox(height: 16),
                      _buildModernTextField(
                        context,
                        controller: _costController,
                        label: 'Cost (Optional)',
                        icon: Icons.attach_money,
                        iconColor: Colors.green,
                        keyboardType: TextInputType.number,
                      ),

                      // Notes
                      const SizedBox(height: 16),
                      _buildModernTextField(
                        context,
                        controller: _notesController,
                        label: 'Notes (Optional)',
                        icon: Icons.notes,
                        iconColor: Colors.grey,
                        maxLines: 3,
                      ),

                      // Submit Button
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _isLoading ? null : _saveRecord,
                        style: FilledButton.styleFrom(
                          backgroundColor: _getTypeColor(_recordType),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
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
                                  const Icon(Icons.save),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Save ${_formatType(_recordType)} Record',
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
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildModernTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? hintText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
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
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: HealthRecordType.values.map((type) {
          final isSelected = _recordType == type;
          final color = _getTypeColor(type);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_formatType(type)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _recordType = type);
              },
              avatar: Icon(
                _getTypeIcon(type),
                size: 18,
                color: isSelected ? Colors.white : color,
              ),
              selectedColor: color,
              backgroundColor: colorScheme.surfaceContainerHighest,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? color : Colors.transparent,
                  width: 1.5,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildTypeSpecificFields() {
    switch (_recordType) {
      case HealthRecordType.vaccination:
        return _buildVaccinationFields();
      case HealthRecordType.medication:
        return _buildMedicationFields();
      case HealthRecordType.checkup:
        return _buildCheckupFields();
      case HealthRecordType.treatment:
      case HealthRecordType.surgery:
        return _buildTreatmentFields();
      case HealthRecordType.observation:
        return _buildObservationFields();
    }
  }

  List<Widget> _buildVaccinationFields() {
    return [
      TextFormField(
        controller: _vaccineNameController,
        decoration: const InputDecoration(
          labelText: 'Vaccine Name *',
          prefixIcon: Icon(Icons.vaccines),
          border: OutlineInputBorder(),
          hintText: 'e.g., FMD, Rabies, etc.',
        ),
        validator: (v) => v?.isEmpty ?? true ? 'Enter vaccine name' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _batchNumberController,
        decoration: const InputDecoration(
          labelText: 'Batch Number (Optional)',
          prefixIcon: Icon(Icons.numbers),
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 16),
      _buildDateSelector(
        'Next Due Date (Optional)',
        _nextDueDate,
        (date) => setState(() => _nextDueDate = date),
        Icons.event,
        isOptional: true,
      ),
    ];
  }

  List<Widget> _buildMedicationFields() {
    return [
      TextFormField(
        controller: _medicationNameController,
        decoration: const InputDecoration(
          labelText: 'Medication Name *',
          prefixIcon: Icon(Icons.medication),
          border: OutlineInputBorder(),
        ),
        validator: (v) => v?.isEmpty ?? true ? 'Enter medication name' : null,
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage',
                prefixIcon: Icon(Icons.scale),
                border: OutlineInputBorder(),
                hintText: 'e.g., 10ml',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: _frequencyController,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                prefixIcon: Icon(Icons.schedule),
                border: OutlineInputBorder(),
                hintText: 'e.g., 2x daily',
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _buildDateSelector(
        'Withdrawal End Date (Optional)',
        _withdrawalEndDate,
        (date) => setState(() => _withdrawalEndDate = date),
        Icons.warning_amber,
        isOptional: true,
      ),
    ];
  }

  List<Widget> _buildCheckupFields() {
    return [
      _buildDateSelector(
        'Follow-up Date (Optional)',
        _followUpDate,
        (date) => setState(() => _followUpDate = date),
        Icons.event_repeat,
        isOptional: true,
      ),
    ];
  }

  List<Widget> _buildTreatmentFields() {
    return [
      // Severity
      DropdownButtonFormField<Severity>(
        initialValue: _severity,
        decoration: const InputDecoration(
          labelText: 'Severity',
          prefixIcon: Icon(Icons.priority_high),
          border: OutlineInputBorder(),
        ),
        items: Severity.values
            .map(
              (s) =>
                  DropdownMenuItem(value: s, child: Text(_formatSeverity(s))),
            )
            .toList(),
        onChanged: (v) => setState(() => _severity = v!),
      ),
      const SizedBox(height: 16),

      // Symptoms
      _buildSymptomsSelector(),
      const SizedBox(height: 16),

      // Diagnosis
      TextFormField(
        controller: _diagnosisController,
        decoration: const InputDecoration(
          labelText: 'Diagnosis',
          prefixIcon: Icon(Icons.medical_information),
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
      ),
      const SizedBox(height: 16),

      // Treatment
      TextFormField(
        controller: _treatmentController,
        decoration: const InputDecoration(
          labelText: 'Treatment Given',
          prefixIcon: Icon(Icons.healing),
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
      ),
      const SizedBox(height: 16),

      // Follow-up Date
      _buildDateSelector(
        'Follow-up Date (Optional)',
        _followUpDate,
        (date) => setState(() => _followUpDate = date),
        Icons.event_repeat,
        isOptional: true,
      ),
    ];
  }

  List<Widget> _buildObservationFields() {
    return [_buildSymptomsSelector()];
  }

  Widget _buildSymptomsSelector() {
    final allSymptoms = CommonSymptoms.general;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Symptoms', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: allSymptoms.map((symptom) {
            final isSelected = _selectedSymptoms.contains(symptom);
            return FilterChip(
              label: Text(symptom),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSymptoms.add(symptom);
                  } else {
                    _selectedSymptoms.remove(symptom);
                  }
                });
              },
              selectedColor: Colors.orange.withValues(alpha: 0.3),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateSelector(
    String label,
    DateTime? date,
    Function(DateTime) onChanged,
    IconData icon, {
    bool isOptional = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(
        date != null ? DateFormat.yMMMd().format(date) : 'Not set',
        style: TextStyle(color: date != null ? null : Colors.grey),
      ),
      trailing: date != null && isOptional
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => onChanged(DateTime.now()),
            )
          : null,
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (selectedDate != null) {
          onChanged(selectedDate);
        }
      },
    );
  }

  String _formatType(HealthRecordType type) {
    switch (type) {
      case HealthRecordType.vaccination:
        return 'Vaccination';
      case HealthRecordType.medication:
        return 'Medication';
      case HealthRecordType.checkup:
        return 'Checkup';
      case HealthRecordType.treatment:
        return 'Treatment';
      case HealthRecordType.surgery:
        return 'Surgery';
      case HealthRecordType.observation:
        return 'Observation';
    }
  }

  String _formatStatus(HealthStatus status) {
    switch (status) {
      case HealthStatus.pending:
        return 'Pending';
      case HealthStatus.inProgress:
        return 'In Progress';
      case HealthStatus.completed:
        return 'Completed';
      case HealthStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatSeverity(Severity severity) {
    switch (severity) {
      case Severity.low:
        return 'Low';
      case Severity.medium:
        return 'Medium';
      case Severity.high:
        return 'High';
      case Severity.critical:
        return 'Critical';
    }
  }

  IconData _getTypeIcon(HealthRecordType type) {
    switch (type) {
      case HealthRecordType.vaccination:
        return Icons.vaccines;
      case HealthRecordType.medication:
        return Icons.medication;
      case HealthRecordType.checkup:
        return Icons.health_and_safety;
      case HealthRecordType.treatment:
        return Icons.healing;
      case HealthRecordType.surgery:
        return Icons.local_hospital;
      case HealthRecordType.observation:
        return Icons.visibility;
    }
  }

  Color _getTypeColor(HealthRecordType type) {
    switch (type) {
      case HealthRecordType.vaccination:
        return Colors.blue;
      case HealthRecordType.medication:
        return Colors.purple;
      case HealthRecordType.checkup:
        return Colors.teal;
      case HealthRecordType.treatment:
        return Colors.orange;
      case HealthRecordType.surgery:
        return Colors.red;
      case HealthRecordType.observation:
        return Colors.grey;
    }
  }

  String _buildRecordTitle() {
    switch (_recordType) {
      case HealthRecordType.vaccination:
        return _vaccineNameController.text.trim().isNotEmpty
            ? _vaccineNameController.text.trim()
            : 'Vaccination';
      case HealthRecordType.medication:
        return _medicationNameController.text.trim().isNotEmpty
            ? _medicationNameController.text.trim()
            : 'Medication';
      case HealthRecordType.checkup:
        return 'Health Checkup';
      case HealthRecordType.treatment:
        return _diagnosisController.text.trim().isNotEmpty
            ? _diagnosisController.text.trim()
            : 'Treatment';
      case HealthRecordType.surgery:
        return _diagnosisController.text.trim().isNotEmpty
            ? _diagnosisController.text.trim()
            : 'Surgery';
      case HealthRecordType.observation:
        return 'Health Observation';
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final farmId = ref.read(activeFarmIdProvider);
    if (farmId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a farm first')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(healthRepositoryProvider);
      final now = DateTime.now();

      final record = HealthRecord(
        id: '',
        farmId: farmId,
        animalId: _selectedAnimalId!,
        type: _recordType,
        title: _buildRecordTitle(),
        date: _recordDate,
        status: _status,
        // Vaccination fields
        vaccineName: _vaccineNameController.text.trim().isEmpty
            ? null
            : _vaccineNameController.text.trim(),
        batchNumber: _batchNumberController.text.trim().isEmpty
            ? null
            : _batchNumberController.text.trim(),
        nextDueDate: _nextDueDate,
        // Medication fields
        medicationName: _medicationNameController.text.trim().isEmpty
            ? null
            : _medicationNameController.text.trim(),
        dosage: _dosageController.text.trim().isEmpty
            ? null
            : _dosageController.text.trim(),
        frequency: _frequencyController.text.trim().isEmpty
            ? null
            : _frequencyController.text.trim(),
        withdrawalEndDate: _withdrawalEndDate,
        // Treatment fields
        symptoms: _selectedSymptoms,
        diagnosis: _diagnosisController.text.trim().isEmpty
            ? null
            : _diagnosisController.text.trim(),
        treatment: _treatmentController.text.trim().isEmpty
            ? null
            : _treatmentController.text.trim(),
        severity: _severity,
        // Vet info
        veterinarianName: _vetNameController.text.trim().isEmpty
            ? null
            : _vetNameController.text.trim(),
        veterinarianContact: _vetContactController.text.trim().isEmpty
            ? null
            : _vetContactController.text.trim(),
        // Other
        followUpDate: _followUpDate,
        cost: double.tryParse(_costController.text.trim()),
        description: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        recordedBy: '',
        createdAt: now,
        updatedAt: now,
      );

      await repository.addHealthRecord(record);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_formatType(_recordType)} record added successfully',
            ),
            backgroundColor: _getTypeColor(_recordType),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
