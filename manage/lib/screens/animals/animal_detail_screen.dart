import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../router/app_router.dart';
import '../../services/camera_service.dart';
import '../breeding/add_breeding_dialog.dart';
import '../feeding/add_feeding_dialog.dart';
import '../weight/add_weight_dialog.dart';
import 'add_animal_dialog.dart';

/// Optimized Animal Detail Screen with lazy-loaded tabs
class AnimalDetailScreen extends ConsumerStatefulWidget {
  final Animal animal;

  const AnimalDetailScreen({super.key, required this.animal});

  @override
  ConsumerState<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends ConsumerState<AnimalDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Animal get animal => widget.animal;

  @override
  Widget build(BuildContext context) {
    // Watch the animal for real-time updates (e.g., photo changes)
    final animalAsync = ref.watch(watchAnimalByIdProvider(animal.id));
    final currentAnimal = animalAsync.when(
      data: (a) => a ?? animal,
      loading: () => animal,
      error: (_, _) => animal,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(currentAnimal.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editAnimal(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteAnimal(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Info'),
            Tab(text: 'Lineage'),
            Tab(text: 'Feeding'),
            Tab(text: 'Weight'),
            Tab(text: 'Breeding'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Each tab is a separate ConsumerWidget that only loads its data when visible
          _InfoTab(
            animal: currentAnimal,
            onTakePhoto: _takePhoto,
            onPickPhoto: _pickPhoto,
          ),
          _LineageTab(animal: currentAnimal),
          _FeedingTab(
            animal: currentAnimal,
            onAddRecord: () => _addFeedingRecord(context),
          ),
          _WeightTab(
            animal: currentAnimal,
            onAddRecord: () => _addWeightRecord(context),
          ),
          _BreedingTab(
            animal: currentAnimal,
            onAddRecord: () => _addBreedingRecord(context),
          ),
        ],
      ),
    );
  }

  void _editAnimal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => AddAnimalDialog(animal: animal),
      ),
    );
  }

  void _deleteAnimal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Animal'),
        content: Text('Are you sure you want to delete ${animal.tagId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(animalRepositoryProvider).deleteAnimal(animal.id);
              if (context.mounted) {
                Navigator.pop(context);
                coordinator.pop();
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addFeedingRecord(BuildContext context) {
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
            AddFeedingDialog(preselectedAnimalId: animal.id),
      ),
    );
  }

  void _addWeightRecord(BuildContext context) {
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
            AddWeightDialog(preselectedAnimalId: animal.id),
      ),
    );
  }

  void _addBreedingRecord(BuildContext context) {
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
            AddBreedingDialog(preselectedAnimalId: animal.id),
      ),
    );
  }

  Future<void> _takePhoto() async {
    final cameraService = CameraService();
    final image = await cameraService.capturePhoto();
    if (image == null) return;

    if (!mounted) return;
    await _uploadPhoto(image);
  }

  Future<void> _pickPhoto() async {
    final cameraService = CameraService();
    final image = await cameraService.pickFromGallery();
    if (image == null) return;

    if (!mounted) return;
    await _uploadPhoto(image);
  }

  Future<void> _uploadPhoto(dynamic image) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Uploading Photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Please wait...'),
          ],
        ),
      ),
    );

    final cameraService = CameraService();
    final photoUrl = await cameraService.uploadProfilePhoto(
      farmId: animal.farmId,
      animalId: animal.id,
      image: image,
    );

    if (!mounted) return;
    Navigator.of(context).pop();

    if (photoUrl != null) {
      try {
        await ref
            .read(animalRepositoryProvider)
            .updateAnimalPhotoUrl(animal.id, photoUrl);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo uploaded successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Photo uploaded but failed to save: $e')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to upload photo')));
    }
  }
}

// ============================================================================
// INFO TAB - Shows basic animal info and photo
// ============================================================================
class _InfoTab extends StatelessWidget {
  final Animal animal;
  final VoidCallback onTakePhoto;
  final VoidCallback onPickPhoto;

  const _InfoTab({
    required this.animal,
    required this.onTakePhoto,
    required this.onPickPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo Section with CachedNetworkImage for faster loading
          _PhotoSection(
            animal: animal,
            onTakePhoto: onTakePhoto,
            onPickPhoto: onPickPhoto,
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Basic Information',
            children: [
              _InfoRow(label: 'Tag ID', value: animal.tagId),
              if (animal.name != null)
                _InfoRow(label: 'Name', value: animal.name!),
              _InfoRow(
                label: 'Species',
                value: '${animal.species.icon} ${animal.species.displayName}',
              ),
              if (animal.breed != null)
                _InfoRow(label: 'Breed', value: animal.breed!),
              _InfoRow(
                label: 'Gender',
                value: animal.gender.name.toUpperCase(),
              ),
              if (animal.birthDate != null)
                _InfoRow(
                  label: 'Birth Date',
                  value: DateFormat.yMMMd().format(animal.birthDate!),
                ),
              _InfoRow(label: 'Age', value: animal.ageFormatted),
            ],
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Health & Status',
            children: [
              _InfoRow(
                label: 'Status',
                value: animal.status.name.toUpperCase(),
                valueColor: _getStatusColor(animal.status),
              ),
              if (animal.currentWeight != null)
                _InfoRow(
                  label: 'Current Weight',
                  value: '${animal.currentWeight!.toStringAsFixed(1)} kg',
                ),
            ],
          ),
          if (animal.notes != null) ...[
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Notes',
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(animal.notes!),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(AnimalStatus status) {
    return switch (status) {
      AnimalStatus.healthy => Colors.green,
      AnimalStatus.sick => Colors.red,
      AnimalStatus.pregnant => Colors.pink,
      AnimalStatus.nursing => Colors.purple,
      AnimalStatus.sold => Colors.grey,
      AnimalStatus.deceased => Colors.black54,
    };
  }
}

// ============================================================================
// PHOTO SECTION - Uses CachedNetworkImage for performance
// ============================================================================
class _PhotoSection extends StatelessWidget {
  final Animal animal;
  final VoidCallback onTakePhoto;
  final VoidCallback onPickPhoto;

  const _PhotoSection({
    required this.animal,
    required this.onTakePhoto,
    required this.onPickPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: animal.photoUrl != null
                ? CachedNetworkImage(
                    imageUrl: animal.photoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) =>
                        _PhotoPlaceholder(theme: theme),
                  )
                : _PhotoPlaceholder(theme: theme),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: onTakePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                ),
                TextButton.icon(
                  onPressed: onPickPhoto,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ],
            ),
          ),
          if (animal.photoGallery.isNotEmpty) ...[
            const Divider(height: 1),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                itemCount: animal.photoGallery.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: animal.photoGallery[index],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          width: 80,
                          height: 80,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final ThemeData theme;
  const _PhotoPlaceholder({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'No photo',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// LINEAGE TAB - Lazy loads parent/offspring data only when tab is visible
// ============================================================================
class _LineageTab extends ConsumerWidget {
  final Animal animal;

  const _LineageTab({required this.animal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Only watch these when this tab is rendered (lazy loading)
    final offspring = ref.watch(offspringProvider(animal.id));
    final mother = animal.motherId != null
        ? ref.watch(animalByIdProvider(animal.motherId!))
        : null;
    final father = animal.fatherId != null
        ? ref.watch(animalByIdProvider(animal.fatherId!))
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoCard(
            title: 'Parents',
            children: [
              if (animal.motherId == null && animal.fatherId == null)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'No parent information recorded',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else ...[
                if (mother != null)
                  _buildParentRow(
                    context,
                    'Mother (Dam)',
                    mother,
                    animal.motherId,
                  ),
                if (father != null)
                  _buildParentRow(
                    context,
                    'Father (Sire)',
                    father,
                    animal.fatherId,
                  ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Offspring',
            children: [
              offspring.when(
                data: (list) => list.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'No offspring recorded',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              '${list.length} offspring',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          ...list.map(
                            (child) => _OffspringCard(
                              animal: child,
                              parentAnimal: animal,
                              onTap: () => coordinator.push(
                                AnimalDetailRoute(animal: child),
                              ),
                            ),
                          ),
                        ],
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('Error: $e'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParentRow(
    BuildContext context,
    String label,
    AsyncValue<Animal?> parentAsync,
    String? parentId,
  ) {
    return parentAsync.when(
      data: (p) => p != null
          ? _ParentCard(
              label: label,
              animal: p,
              onTap: () => coordinator.push(AnimalDetailRoute(animal: p)),
            )
          : _ParentCard(label: label, animalId: parentId, notFound: true),
      loading: () => Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Text('$label: '),
            const SizedBox(width: 8),
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text('$label: Error - $e'),
      ),
    );
  }
}

// ============================================================================
// FEEDING TAB - Uses stream provider for real-time updates
// ============================================================================
class _FeedingTab extends ConsumerWidget {
  final Animal animal;
  final VoidCallback onAddRecord;

  const _FeedingTab({required this.animal, required this.onAddRecord});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(feedingRecordsForAnimalProvider(animal.id));

    return Column(
      children: [
        Expanded(
          child: recordsAsync.when(
            data: (records) => records.isEmpty
                ? const Center(child: Text('No feeding records'))
                : RefreshIndicator(
                    onRefresh: () => ref.refresh(
                      feedingRecordsForAnimalProvider(animal.id).future,
                    ),
                    child: ListView.builder(
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.restaurant),
                          ),
                          title: Text(record.feedType),
                          subtitle: Text(
                            DateFormat.yMMMd().format(record.date),
                          ),
                          trailing: Text('${record.quantity} kg'),
                        );
                      },
                    ),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: onAddRecord,
            icon: const Icon(Icons.add),
            label: const Text('Add Feeding Record'),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// WEIGHT TAB - Uses stream provider for real-time updates
// ============================================================================
class _WeightTab extends ConsumerWidget {
  final Animal animal;
  final VoidCallback onAddRecord;

  const _WeightTab({required this.animal, required this.onAddRecord});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(weightRecordsForAnimalProvider(animal.id));

    return Column(
      children: [
        Expanded(
          child: recordsAsync.when(
            data: (records) => records.isEmpty
                ? const Center(child: Text('No weight records'))
                : RefreshIndicator(
                    onRefresh: () => ref.refresh(
                      weightRecordsForAnimalProvider(animal.id).future,
                    ),
                    child: ListView.builder(
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.monitor_weight),
                          ),
                          title: Text('${record.weight.toStringAsFixed(1)} kg'),
                          subtitle: Text(
                            DateFormat.yMMMd().format(record.date),
                          ),
                        );
                      },
                    ),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: onAddRecord,
            icon: const Icon(Icons.add),
            label: const Text('Add Weight Record'),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// BREEDING TAB - Uses paginated provider with load more
// ============================================================================
class _BreedingTab extends ConsumerWidget {
  final Animal animal;
  final VoidCallback onAddRecord;

  const _BreedingTab({required this.animal, required this.onAddRecord});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (animal.gender == Gender.male) {
      return const Center(
        child: Text('Breeding records are for female animals only'),
      );
    }

    final recordsAsync = ref.watch(breedingRecordsForAnimalProvider(animal.id));

    return Column(
      children: [
        Expanded(
          child: recordsAsync.when(
            data: (records) => records.isEmpty
                ? const Center(child: Text('No breeding records'))
                : RefreshIndicator(
                    onRefresh: () => ref.refresh(
                      breedingRecordsForAnimalProvider(animal.id).future,
                    ),
                    child: ListView.builder(
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getBreedingStatusColor(
                              record.status,
                            ).withValues(alpha: 0.2),
                            child: Icon(
                              Icons.family_restroom,
                              color: _getBreedingStatusColor(record.status),
                            ),
                          ),
                          title: Text(record.status.name.toUpperCase()),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Heat: ${DateFormat.yMMMd().format(record.heatDate)}',
                              ),
                              if (record.daysPregnant != null)
                                Text('Days Pregnant: ${record.daysPregnant}'),
                              if (record.daysUntilFarrowing != null)
                                Text(
                                  'Days Until Farrowing: ${record.daysUntilFarrowing}',
                                ),
                            ],
                          ),
                          isThreeLine: true,
                        );
                      },
                    ),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: onAddRecord,
            icon: const Icon(Icons.add),
            label: const Text('Add Breeding Record'),
          ),
        ),
      ],
    );
  }

  Color _getBreedingStatusColor(BreedingStatus status) {
    return switch (status) {
      BreedingStatus.inHeat => Colors.orange,
      BreedingStatus.bred => Colors.blue,
      BreedingStatus.pregnant => Colors.pink,
      BreedingStatus.delivered => Colors.green,
      BreedingStatus.failed => Colors.red,
    };
  }
}

// ============================================================================
// SHARED WIDGETS
// ============================================================================
class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w500, color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _ParentCard extends StatelessWidget {
  final String label;
  final Animal? animal;
  final String? animalId;
  final bool notFound;
  final VoidCallback? onTap;

  const _ParentCard({
    required this.label,
    this.animal,
    this.animalId,
    this.notFound = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (notFound) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey,
              child: Icon(Icons.help_outline, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.grey)),
                  Text(
                    'ID: ${animalId ?? 'Unknown'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const Text(
                    'Animal not found',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: animal?.photoUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: animal!.photoUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Text(
                          animal!.species.icon,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    )
                  : Text(
                      animal!.species.icon,
                      style: const TextStyle(fontSize: 18),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    animal!.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${animal!.breed ?? animal!.species.displayName} • ${animal!.ageFormatted}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _OffspringCard extends StatelessWidget {
  final Animal animal;
  final Animal parentAnimal;
  final VoidCallback onTap;

  const _OffspringCard({
    required this.animal,
    required this.parentAnimal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final relationship = animal.motherId == parentAnimal.id
        ? 'Mother'
        : 'Father';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: animal.photoUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: animal.photoUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Text(
                          animal.species.icon,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    )
                  : Text(
                      animal.species.icon,
                      style: const TextStyle(fontSize: 18),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        animal.displayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: animal.gender == Gender.male
                              ? Colors.blue.withValues(alpha: 0.2)
                              : Colors.pink.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          animal.gender == Gender.male ? '♂' : '♀',
                          style: TextStyle(
                            fontSize: 12,
                            color: animal.gender == Gender.male
                                ? Colors.blue
                                : Colors.pink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${animal.breed ?? animal.species.displayName} • ${animal.ageFormatted}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'Via $relationship',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
