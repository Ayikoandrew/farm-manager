import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/responsive_layout.dart';
import '../../utils/seo_helper.dart';
import 'add_breeding_dialog.dart';
import 'breeding_detail_dialog.dart';

class BreedingScreen extends ConsumerStatefulWidget {
  const BreedingScreen({super.key});

  @override
  ConsumerState<BreedingScreen> createState() => _BreedingScreenState();
}

class _BreedingScreenState extends ConsumerState<BreedingScreen> {
  @override
  void initState() {
    super.initState();
    SeoHelper.configureBreedingPage();
  }

  @override
  Widget build(BuildContext context) {
    final breedingAsync = ref.watch(breedingRecordsProvider);
    final animalsAsync = ref.watch(animalsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Breeding Management'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'In Heat'),
              Tab(text: 'Pregnant'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRecordsList(context, ref, breedingAsync, animalsAsync),
            _buildInHeatList(context, ref, animalsAsync),
            _buildPregnantList(context, ref, animalsAsync),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddBreedingDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('New Record'),
        ),
      ),
    );
  }

  Widget _buildRecordsList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<BreedingRecord>> breedingAsync,
    AsyncValue<List<Animal>> animalsAsync,
  ) {
    return breedingAsync.when(
      data: (records) => records.isEmpty
          ? _buildEmptyState(context, 'No breeding records yet')
          : animalsAsync.when(
              data: (animals) {
                final animalMap = {for (var a in animals) a.id: a};
                return _buildResponsiveBreedingList(
                  records: records,
                  animalMap: animalMap,
                  isPregnancy: false,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildResponsiveBreedingList({
    required List<BreedingRecord> records,
    required Map<String, Animal> animalMap,
    required bool isPregnancy,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > Breakpoints.tablet;
        final columns = constraints.maxWidth > Breakpoints.desktop ? 3 : 2;

        if (isWide) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: isPregnancy ? 2.0 : 2.5,
                ),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  final animal = animalMap[record.animalId];
                  if (isPregnancy) {
                    return _PregnancyCard(
                      record: record,
                      animal: animal,
                      onTap: () => _showBreedingDetail(context, record, animal),
                    );
                  }
                  return _BreedingCard(
                    record: record,
                    animal: animal,
                    onTap: () => _showBreedingDetail(context, record, animal),
                  );
                },
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            final animal = animalMap[record.animalId];
            if (isPregnancy) {
              return _PregnancyCard(
                record: record,
                animal: animal,
                onTap: () => _showBreedingDetail(context, record, animal),
              );
            }
            return _BreedingCard(
              record: record,
              animal: animal,
              onTap: () => _showBreedingDetail(context, record, animal),
            );
          },
        );
      },
    );
  }

  Widget _buildInHeatList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Animal>> animalsAsync,
  ) {
    final inHeatAsync = ref.watch(animalsInHeatProvider);

    return inHeatAsync.when(
      data: (records) => records.isEmpty
          ? _buildEmptyState(context, 'No animals in heat')
          : animalsAsync.when(
              data: (animals) {
                final animalMap = {for (var a in animals) a.id: a};
                return _buildResponsiveBreedingList(
                  records: records,
                  animalMap: animalMap,
                  isPregnancy: false,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildPregnantList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Animal>> animalsAsync,
  ) {
    final pregnantRecordsAsync = ref.watch(pregnantBreedingRecordsProvider);
    final allPregnantAnimalsAsync = ref.watch(allPregnantAnimalsProvider);

    return allPregnantAnimalsAsync.when(
      data: (pregnantAnimals) {
        if (pregnantAnimals.isEmpty) {
          return _buildEmptyState(context, 'No pregnant animals');
        }

        return pregnantRecordsAsync.when(
          data: (breedingRecords) {
            // Create a map of animal_id to breeding record
            final breedingMap = {for (var r in breedingRecords) r.animalId: r};

            return _buildPregnantAnimalsList(
              pregnantAnimals: pregnantAnimals,
              breedingMap: breedingMap,
            );
          },
          loading: () => _buildPregnantAnimalsList(
            pregnantAnimals: pregnantAnimals,
            breedingMap: {},
          ),
          error: (e, st) => _buildPregnantAnimalsList(
            pregnantAnimals: pregnantAnimals,
            breedingMap: {},
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildPregnantAnimalsList({
    required List<Animal> pregnantAnimals,
    required Map<String, BreedingRecord> breedingMap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > Breakpoints.tablet;
        final columns = constraints.maxWidth > Breakpoints.desktop ? 3 : 2;

        if (isWide) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  childAspectRatio: 1.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: pregnantAnimals.length,
                itemBuilder: (context, index) {
                  final animal = pregnantAnimals[index];
                  final breedingRecord = breedingMap[animal.id];
                  return _PregnantAnimalCard(
                    animal: animal,
                    breedingRecord: breedingRecord,
                    onTap: () {
                      if (breedingRecord != null) {
                        _showBreedingDetail(context, breedingRecord, animal);
                      } else {
                        // Show a dialog to create a breeding record for this animal
                        _showCreateBreedingRecordDialog(context, animal);
                      }
                    },
                  );
                },
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pregnantAnimals.length,
          itemBuilder: (context, index) {
            final animal = pregnantAnimals[index];
            final breedingRecord = breedingMap[animal.id];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PregnantAnimalCard(
                animal: animal,
                breedingRecord: breedingRecord,
                onTap: () {
                  if (breedingRecord != null) {
                    _showBreedingDetail(context, breedingRecord, animal);
                  } else {
                    _showCreateBreedingRecordDialog(context, animal);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateBreedingRecordDialog(BuildContext context, Animal animal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) =>
            AddBreedingDialog(preselectedAnimal: animal),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.family_restroom, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }

  void _showAddBreedingDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => const AddBreedingDialog(),
      ),
    );
  }

  void _showBreedingDetail(
    BuildContext context,
    BreedingRecord record,
    Animal? animal,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) =>
            BreedingDetailDialog(record: record, animal: animal),
      ),
    );
  }
}

class _BreedingCard extends StatelessWidget {
  final BreedingRecord record;
  final Animal? animal;
  final VoidCallback onTap;

  const _BreedingCard({required this.record, this.animal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(
            record.status,
          ).withValues(alpha: 0.2),
          child: Icon(
            _getStatusIcon(record.status),
            color: _getStatusColor(record.status),
          ),
        ),
        title: Text(
          animal?.tagId ?? 'Unknown Animal',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Heat: ${DateFormat.yMMMd().format(record.heatDate)}'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(record.status).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                record.status.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(record.status),
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
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

class _PregnancyCard extends StatelessWidget {
  final BreedingRecord record;
  final Animal? animal;
  final VoidCallback onTap;

  const _PregnancyCard({
    required this.record,
    this.animal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final daysPregnant = record.daysPregnant ?? 0;
    final daysUntilDelivery = record.daysUntilDelivery ?? 0;
    final gestationDays = animal != null
        ? GestationPeriods.forSpecies(animal!.species)
        : GestationPeriods.pig;
    final progress = daysPregnant / gestationDays;
    final deliveryTerm = GestationPeriods.deliveryTermForSpecies(
      animal?.species,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.pink.withValues(alpha: 0.2),
                    child: const Icon(Icons.child_friendly, color: Colors.pink),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          animal?.tagId ?? 'Unknown Animal',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Expected $deliveryTerm: ${DateFormat.yMMMd().format(record.expectedDeliveryDate!)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$daysPregnant days',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.pink,
                        ),
                      ),
                      Text(
                        '$daysUntilDelivery days left',
                        style: TextStyle(
                          fontSize: 12,
                          color: daysUntilDelivery <= 7
                              ? Colors.red
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  daysUntilDelivery <= 7 ? Colors.red : Colors.pink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toStringAsFixed(0)}% of gestation',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card for displaying pregnant animals
/// Shows breeding record details if available, otherwise shows basic info
class _PregnantAnimalCard extends StatelessWidget {
  final Animal animal;
  final BreedingRecord? breedingRecord;
  final VoidCallback onTap;

  const _PregnantAnimalCard({
    required this.animal,
    this.breedingRecord,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasBreedingRecord = breedingRecord != null;
    final daysPregnant = breedingRecord?.daysPregnant;
    final daysUntilDelivery = breedingRecord?.daysUntilDelivery;
    final gestationDays = GestationPeriods.forSpecies(animal.species);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.pink.withValues(alpha: 0.2),
                    child: const Icon(Icons.child_friendly, color: Colors.pink),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          animal.name ?? animal.tagId,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${animal.species.name.toUpperCase()} • ${animal.breed ?? "Unknown breed"}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!hasBreedingRecord)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'No Record',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (hasBreedingRecord && daysPregnant != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$daysPregnant days pregnant',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),
                    if (daysUntilDelivery != null)
                      Text(
                        '$daysUntilDelivery days left',
                        style: TextStyle(
                          fontSize: 12,
                          color: daysUntilDelivery <= 7
                              ? Colors.red
                              : Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (breedingRecord!.expectedDeliveryDate != null)
                  LinearProgressIndicator(
                    value: (daysPregnant / gestationDays).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      daysUntilDelivery != null && daysUntilDelivery <= 7
                          ? Colors.red
                          : Colors.pink,
                    ),
                  ),
              ] else ...[
                Text(
                  'Tap to add breeding details',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
