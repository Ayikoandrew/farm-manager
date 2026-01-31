import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

class HealthRecordDetailDialog extends ConsumerStatefulWidget {
  final HealthRecord record;
  final Animal? animal;

  const HealthRecordDetailDialog({
    super.key,
    required this.record,
    this.animal,
  });

  @override
  ConsumerState<HealthRecordDetailDialog> createState() =>
      _HealthRecordDetailDialogState();
}

class _HealthRecordDetailDialogState
    extends ConsumerState<HealthRecordDetailDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final record = widget.record;
    final animal = widget.animal;
    final dateFormat = DateFormat('MMM d, yyyy');
    final typeColor = _getTypeColor(record.type);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header with gradient
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [typeColor, typeColor.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: typeColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getTypeIcon(record.type),
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
                          record.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatType(record.type),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                    ),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Status and Severity Badges
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      record.status,
                    ).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(
                        record.status,
                      ).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(record.status),
                        size: 16,
                        color: _getStatusColor(record.status),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        record.status.name.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _getStatusColor(record.status),
                        ),
                      ),
                    ],
                  ),
                ),
                if (record.severity != null &&
                    record.severity != Severity.low) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(
                        record.severity!,
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getSeverityColor(
                          record.severity!,
                        ).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber,
                          size: 16,
                          color: _getSeverityColor(record.severity!),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${record.severity!.name.toUpperCase()} SEVERITY',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: _getSeverityColor(record.severity!),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Withdrawal Warning
            if (record.isInWithdrawalPeriod)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.withValues(alpha: 0.15),
                      Colors.orange.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.warning_amber,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Withdrawal Period Active',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Animal should not be sold/slaughtered until ${dateFormat.format(record.withdrawalEndDate!)}',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Animal Info
            _buildModernInfoCard(
              context,
              'Animal Information',
              Icons.pets,
              Colors.blue,
              [
                _InfoRow('Tag ID', animal?.tagId ?? 'Unknown'),
                if (animal?.breed != null) _InfoRow('Breed', animal!.breed!),
                if (animal != null)
                  _InfoRow('Status', animal.status.name.toUpperCase()),
              ],
            ),
            const SizedBox(height: 12),

            // Date Info
            _buildModernInfoCard(
              context,
              'Dates',
              Icons.calendar_today,
              Colors.teal,
              [
                _InfoRow('Record Date', dateFormat.format(record.date)),
                if (record.nextDueDate != null)
                  _InfoRow('Next Due', dateFormat.format(record.nextDueDate!)),
                if (record.followUpDate != null)
                  _InfoRow(
                    'Follow-up',
                    dateFormat.format(record.followUpDate!),
                  ),
                if (record.withdrawalEndDate != null)
                  _InfoRow(
                    'Withdrawal Ends',
                    dateFormat.format(record.withdrawalEndDate!),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Type-specific Info
            ..._buildTypeSpecificInfo(record),

            // Veterinarian Info
            if (record.veterinarianName != null ||
                record.veterinarianContact != null) ...[
              const SizedBox(height: 12),
              _buildModernInfoCard(
                context,
                'Veterinarian',
                Icons.medical_services,
                Colors.purple,
                [
                  if (record.veterinarianName != null)
                    _InfoRow('Name', record.veterinarianName!),
                  if (record.veterinarianContact != null)
                    _InfoRow('Contact', record.veterinarianContact!),
                ],
              ),
            ],

            // Cost
            if (record.cost != null) ...[
              const SizedBox(height: 12),
              _buildModernInfoCard(
                context,
                'Cost',
                Icons.attach_money,
                Colors.green,
                [_InfoRow('Amount', '\$${record.cost!.toStringAsFixed(2)}')],
              ),
            ],

            // Notes
            if (record.description != null) ...[
              const SizedBox(height: 12),
              _buildModernInfoCard(
                context,
                'Notes',
                Icons.notes,
                Colors.blueGrey,
                [_InfoRow('', record.description!)],
              ),
            ],

            // Action Buttons
            const SizedBox(height: 24),
            if (record.status != HealthStatus.completed)
              FilledButton(
                onPressed: () => _markAsCompleted(context),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle),
                    SizedBox(width: 8),
                    Text(
                      'Mark Complete',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            if (record.status != HealthStatus.completed)
              const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isDeleting ? null : () => _deleteRecord(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.red,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete),
                        SizedBox(width: 8),
                        Text('Delete Record'),
                      ],
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(HealthStatus status) {
    switch (status) {
      case HealthStatus.pending:
        return Icons.schedule;
      case HealthStatus.inProgress:
        return Icons.play_circle;
      case HealthStatus.completed:
        return Icons.check_circle;
      case HealthStatus.cancelled:
        return Icons.cancel;
    }
  }

  Widget _buildModernInfoCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<_InfoRow> rows,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16).copyWith(bottom: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            height: 1,
          ),
          Padding(
            padding: const EdgeInsets.all(16).copyWith(top: 8),
            child: Column(
              children: rows
                  .map(
                    (row) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (row.label.isNotEmpty) ...[
                            Expanded(
                              flex: 2,
                              child: Text(
                                row.label,
                                style: TextStyle(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                row.value,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ] else
                            Expanded(
                              child: Text(
                                row.value,
                                style: TextStyle(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTypeSpecificInfo(HealthRecord record) {
    switch (record.type) {
      case HealthRecordType.vaccination:
        return [
          if (record.vaccineName != null || record.batchNumber != null)
            _buildModernInfoCard(
              context,
              'Vaccination Details',
              Icons.vaccines,
              Colors.indigo,
              [
                if (record.vaccineName != null)
                  _InfoRow('Vaccine', record.vaccineName!),
                if (record.batchNumber != null)
                  _InfoRow('Batch #', record.batchNumber!),
              ],
            ),
        ];

      case HealthRecordType.medication:
        return [
          if (record.medicationName != null ||
              record.dosage != null ||
              record.frequency != null)
            _buildModernInfoCard(
              context,
              'Medication Details',
              Icons.medication,
              Colors.deepPurple,
              [
                if (record.medicationName != null)
                  _InfoRow('Medication', record.medicationName!),
                if (record.dosage != null) _InfoRow('Dosage', record.dosage!),
                if (record.frequency != null)
                  _InfoRow('Frequency', record.frequency!),
              ],
            ),
        ];

      case HealthRecordType.treatment:
      case HealthRecordType.surgery:
        final List<Widget> widgets = [];
        if (record.symptoms.isNotEmpty) {
          widgets.add(
            _buildModernInfoCard(
              context,
              'Symptoms',
              Icons.sick,
              Colors.orange,
              [_InfoRow('', record.symptoms.join(', '))],
            ),
          );
          widgets.add(const SizedBox(height: 12));
        }
        if (record.diagnosis != null || record.treatment != null) {
          widgets.add(
            _buildModernInfoCard(
              context,
              'Diagnosis & Treatment',
              Icons.healing,
              Colors.pink,
              [
                if (record.diagnosis != null)
                  _InfoRow('Diagnosis', record.diagnosis!),
                if (record.treatment != null)
                  _InfoRow('Treatment', record.treatment!),
              ],
            ),
          );
        }
        return widgets;

      case HealthRecordType.checkup:
        return [];

      case HealthRecordType.observation:
        if (record.symptoms.isNotEmpty) {
          return [
            _buildModernInfoCard(
              context,
              'Observed Symptoms',
              Icons.visibility,
              Colors.amber,
              [_InfoRow('', record.symptoms.join(', '))],
            ),
          ];
        }
        return [];
    }
  }

  String _formatType(HealthRecordType type) {
    switch (type) {
      case HealthRecordType.vaccination:
        return 'Vaccination';
      case HealthRecordType.medication:
        return 'Medication';
      case HealthRecordType.checkup:
        return 'Health Checkup';
      case HealthRecordType.treatment:
        return 'Treatment';
      case HealthRecordType.surgery:
        return 'Surgery';
      case HealthRecordType.observation:
        return 'Observation';
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

  Color _getStatusColor(HealthStatus status) {
    switch (status) {
      case HealthStatus.pending:
        return Colors.orange;
      case HealthStatus.inProgress:
        return Colors.blue;
      case HealthStatus.completed:
        return Colors.green;
      case HealthStatus.cancelled:
        return Colors.grey;
    }
  }

  Color _getSeverityColor(Severity severity) {
    switch (severity) {
      case Severity.low:
        return Colors.green;
      case Severity.medium:
        return Colors.yellow[700]!;
      case Severity.high:
        return Colors.orange;
      case Severity.critical:
        return Colors.red;
    }
  }

  Future<void> _markAsCompleted(BuildContext context) async {
    try {
      final repository = ref.read(healthRepositoryProvider);
      final updatedRecord = widget.record.copyWith(
        status: HealthStatus.completed,
        updatedAt: DateTime.now(),
      );
      await repository.updateHealthRecord(updatedRecord);

      if (mounted) {
        Navigator.pop(this.context);
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Record marked as completed')),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: $e');
      }
    }
  }

  Future<void> _deleteRecord(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 12),
            Text('Delete Record'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this health record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    try {
      final repository = ref.read(healthRepositoryProvider);
      await repository.deleteHealthRecord(widget.record.id);

      if (mounted) {
        Navigator.pop(this.context);
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Record deleted successfully')),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: $e');
        setState(() => _isDeleting = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;

  _InfoRow(this.label, this.value);
}
