import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/paginated_feeding_provider.dart';
import '../../providers/providers.dart';
import '../../utils/responsive_layout.dart';
import '../../utils/seo_helper.dart';
import 'add_feeding_dialog.dart';

class FeedingScreen extends ConsumerStatefulWidget {
  const FeedingScreen({super.key});

  @override
  ConsumerState<FeedingScreen> createState() => _FeedingScreenState();
}

class _FeedingScreenState extends ConsumerState<FeedingScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    SeoHelper.configureFeedingPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(paginatedFeedingProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedingState = ref.watch(paginatedFeedingProvider);
    final animalsAsync = ref.watch(animalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Feeding Records')),
      body: _buildBody(context, feedingState, animalsAsync),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFeedingDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Record'),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PaginatedFeedingState state,
    AsyncValue<List<Animal>> animalsAsync,
  ) {
    if (state.error != null && state.records.isEmpty) {
      return Center(child: Text('Error: ${state.error}'));
    }

    if (state.isLoading && state.records.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.records.isEmpty) {
      return _buildEmptyState(context);
    }

    return animalsAsync.when(
      data: (animals) {
        final animalMap = {for (var a in animals) a.id: a};
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(paginatedFeedingProvider.notifier).refresh(),
          child: _buildRecordsList(context, state, animalMap),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No feeding records yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your animals\' feeding',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(
    BuildContext context,
    PaginatedFeedingState state,
    Map<String, Animal> animalMap,
  ) {
    final records = state.records;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > Breakpoints.tablet;
        final screenWidth = constraints.maxWidth;
        const maxContentWidth = 1200.0;
        final horizontalPadding = screenWidth > maxContentWidth
            ? (screenWidth - maxContentWidth) / 2 + 8
            : 8.0;

        Widget buildFeedingCard(FeedingRecord record) {
          final animal = animalMap[record.animalId];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.amber.withValues(alpha: 0.2),
                child: const Icon(Icons.restaurant, color: Colors.amber),
              ),
              title: Text(
                animal?.tagId ?? 'Unknown Animal',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.feedType),
                  Text(
                    DateFormat.yMMMd().format(record.date),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              trailing: Text(
                '${record.quantity.toStringAsFixed(1)} kg',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              isThreeLine: true,
              onLongPress: () => _deleteRecord(context, ref, record),
            ),
          );
        }

        if (isWide) {
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 8,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: constraints.maxWidth > Breakpoints.desktop
                        ? 3
                        : 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.5,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => buildFeedingCard(records[index]),
                    childCount: records.length,
                  ),
                ),
              ),
              if (state.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              if (!state.hasMore && records.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'All ${records.length} records loaded',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(8),
          itemCount:
              records.length + (state.isLoading || !state.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == records.length) {
              if (state.isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'All ${records.length} records loaded',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              );
            }
            return buildFeedingCard(records[index]);
          },
        );
      },
    );
  }

  void _showAddFeedingDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => const AddFeedingDialog(),
      ),
    );
  }

  void _deleteRecord(
    BuildContext context,
    WidgetRef ref,
    FeedingRecord record,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text(
          'Are you sure you want to delete this feeding record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(feedingRepositoryProvider)
                  .deleteFeedingRecord(record.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
