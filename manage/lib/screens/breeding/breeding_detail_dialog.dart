import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

class BreedingDetailDialog extends ConsumerStatefulWidget {
  final BreedingRecord record;
  final Animal? animal;

  const BreedingDetailDialog({super.key, required this.record, this.animal});

  @override
  ConsumerState<BreedingDetailDialog> createState() =>
      _BreedingDetailDialogState();
}

class _BreedingDetailDialogState extends ConsumerState<BreedingDetailDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maleAnimalsAsync = ref.watch(maleAnimalsProvider);
    final statusColor = _getStatusColor(widget.record.status);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
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

            // Header with gradient
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor, statusColor.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getStatusIcon(widget.record.status),
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.animal?.tagId ?? 'Unknown Animal',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.record.status.name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
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

            // Details Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    context,
                    'Timeline',
                    Icons.timeline,
                    Colors.indigo,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailCard(context, [
                    _buildDetailItem(
                      context,
                      'Heat Date',
                      DateFormat.yMMMd().format(widget.record.heatDate),
                      Icons.whatshot,
                      Colors.orange,
                    ),
                    if (widget.record.breedingDate != null)
                      _buildDetailItem(
                        context,
                        'Breeding Date',
                        DateFormat.yMMMd().format(widget.record.breedingDate!),
                        Icons.favorite,
                        Colors.pink,
                      ),
                    if (widget.record.expectedFarrowDate != null)
                      _buildDetailItem(
                        context,
                        'Expected Farrow',
                        DateFormat.yMMMd().format(
                          widget.record.expectedFarrowDate!,
                        ),
                        Icons.event,
                        Colors.teal,
                      ),
                  ]),

                  if (widget.record.daysPregnant != null ||
                      widget.record.daysUntilFarrowing != null ||
                      widget.record.litterSize != null) ...[
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                      context,
                      'Progress',
                      Icons.insights,
                      Colors.purple,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailCard(context, [
                      if (widget.record.daysPregnant != null)
                        _buildDetailItem(
                          context,
                          'Days Pregnant',
                          '${widget.record.daysPregnant} days',
                          Icons.child_friendly,
                          Colors.pink,
                        ),
                      if (widget.record.daysUntilFarrowing != null)
                        _buildDetailItem(
                          context,
                          'Days Until Farrowing',
                          '${widget.record.daysUntilFarrowing} days',
                          Icons.timer,
                          widget.record.daysUntilFarrowing! <= 7
                              ? Colors.red
                              : Colors.green,
                        ),
                      if (widget.record.litterSize != null)
                        _buildDetailItem(
                          context,
                          'Litter Size',
                          '${widget.record.litterSize} piglets',
                          Icons.pets,
                          Colors.amber,
                        ),
                    ]),
                  ],

                  if (widget.record.notes != null &&
                      widget.record.notes!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                      context,
                      'Notes',
                      Icons.notes,
                      Colors.blueGrey,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.format_quote,
                            color: colorScheme.primary.withValues(alpha: 0.5),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.record.notes!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons based on status
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildActionButtons(context, maleAnimalsAsync),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Row(
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
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDetailCard(BuildContext context, List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    AsyncValue<List<Animal>> maleAnimalsAsync,
  ) {
    switch (widget.record.status) {
      case BreedingStatus.inHeat:
        return Column(
          children: [
            FilledButton(
              onPressed: () => _showBreedDialog(context, maleAnimalsAsync),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite),
                  SizedBox(width: 8),
                  Text(
                    'Mark as Bred',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _markAsFailed,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel),
                  SizedBox(width: 8),
                  Text('Mark as Failed'),
                ],
              ),
            ),
          ],
        );

      case BreedingStatus.bred:
        return Column(
          children: [
            FilledButton(
              onPressed: _confirmPregnancy,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.pink,
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
                    'Confirm Pregnancy',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _markAsFailed,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel),
                  SizedBox(width: 8),
                  Text('Not Pregnant'),
                ],
              ),
            ),
          ],
        );

      case BreedingStatus.pregnant:
        return FilledButton(
          onPressed: () => _showFarrowDialog(context),
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
              Icon(Icons.celebration),
              SizedBox(width: 8),
              Text(
                'Record Delivery',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );

      case BreedingStatus.delivered:
      case BreedingStatus.failed:
        return OutlinedButton(
          onPressed: _deleteRecord,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete),
              SizedBox(width: 8),
              Text('Delete Record'),
            ],
          ),
        );
    }
  }

  void _showBreedDialog(
    BuildContext context,
    AsyncValue<List<Animal>> maleAnimalsAsync,
  ) {
    String? selectedSireId;
    DateTime breedingDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Mark as Bred'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              maleAnimalsAsync.when(
                data: (males) => DropdownButtonFormField<String>(
                  initialValue: selectedSireId,
                  decoration: const InputDecoration(
                    labelText: 'Select Sire (optional)',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Unknown / AI'),
                    ),
                    ...males.map(
                      (m) => DropdownMenuItem(
                        value: m.id,
                        child: Text('${m.tagId} - ${m.breed}'),
                      ),
                    ),
                  ],
                  onChanged: (v) => setDialogState(() => selectedSireId = v),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, st) => Text('Error: $e'),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Breeding Date'),
                subtitle: Text(DateFormat.yMMMd().format(breedingDate)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: breedingDate,
                    firstDate: widget.record.heatDate,
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setDialogState(() => breedingDate = date);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _markAsBred(breedingDate, selectedSireId);
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFarrowDialog(BuildContext context) {
    DateTime farrowDate = DateTime.now();
    final litterController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Record Farrowing'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Farrow Date'),
                subtitle: Text(DateFormat.yMMMd().format(farrowDate)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: farrowDate,
                    firstDate:
                        widget.record.breedingDate ?? widget.record.heatDate,
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setDialogState(() => farrowDate = date);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: litterController,
                decoration: const InputDecoration(
                  labelText: 'Litter Size',
                  hintText: 'Number of piglets',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final litterSize = int.tryParse(litterController.text) ?? 0;
                Navigator.pop(context);
                await _recordFarrowing(farrowDate, litterSize);
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsBred(DateTime breedingDate, String? sireId) async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(breedingRepositoryProvider)
          .markAsBred(widget.record.id, breedingDate, sireId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmPregnancy() async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(breedingRepositoryProvider)
          .confirmPregnancy(widget.record.id);

      // Also update animal status
      await ref
          .read(animalRepositoryProvider)
          .updateAnimalStatus(widget.record.animalId, AnimalStatus.pregnant);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _recordFarrowing(DateTime farrowDate, int litterSize) async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(breedingRepositoryProvider)
          .recordFarrowing(widget.record.id, farrowDate, litterSize);

      // Update animal status to nursing
      await ref
          .read(animalRepositoryProvider)
          .updateAnimalStatus(widget.record.animalId, AnimalStatus.nursing);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsFailed() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(breedingRepositoryProvider).markAsFailed(widget.record.id);

      // Reset animal status to healthy
      await ref
          .read(animalRepositoryProvider)
          .updateAnimalStatus(widget.record.animalId, AnimalStatus.healthy);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRecord() async {
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
          'Are you sure you want to delete this breeding record?',
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

    setState(() => _isLoading = true);
    try {
      await ref
          .read(breedingRepositoryProvider)
          .deleteBreedingRecord(widget.record.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  Color _getStatusColor(BreedingStatus status) {
    switch (status) {
      case BreedingStatus.inHeat:
        return Colors.orange;
      case BreedingStatus.bred:
        return Colors.blue;
      case BreedingStatus.pregnant:
        return Colors.pink;
      case BreedingStatus.delivered:
        return Colors.green;
      case BreedingStatus.failed:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(BreedingStatus status) {
    switch (status) {
      case BreedingStatus.inHeat:
        return Icons.whatshot;
      case BreedingStatus.bred:
        return Icons.favorite;
      case BreedingStatus.pregnant:
        return Icons.child_friendly;
      case BreedingStatus.delivered:
        return Icons.celebration;
      case BreedingStatus.failed:
        return Icons.cancel;
    }
  }
}
