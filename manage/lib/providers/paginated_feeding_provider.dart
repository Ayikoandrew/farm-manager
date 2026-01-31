import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feeding_record.dart';
import '../repositories/feeding_repository.dart';
import 'providers.dart';

const int _pageSize = 20;

/// State for paginated feeding records
class PaginatedFeedingState {
  final List<FeedingRecord> records;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const PaginatedFeedingState({
    this.records = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  PaginatedFeedingState copyWith({
    List<FeedingRecord>? records,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return PaginatedFeedingState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

/// Notifier for paginated feeding records
class PaginatedFeedingNotifier extends Notifier<PaginatedFeedingState> {
  @override
  PaginatedFeedingState build() {
    final farmId = ref.watch(activeFarmIdProvider);
    if (farmId == null) {
      return const PaginatedFeedingState(hasMore: false);
    }
    Future.microtask(() => loadInitial());
    return const PaginatedFeedingState(isLoading: true);
  }

  FeedingRepository get _repository => ref.read(feedingRepositoryProvider);
  String? get _farmId => ref.read(activeFarmIdProvider);

  Future<void> loadInitial() async {
    if (_farmId == null) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final records = await _repository.getFeedingRecordsPaginated(
        _farmId!,
        limit: _pageSize,
        offset: 0,
      );
      state = PaginatedFeedingState(
        records: records,
        isLoading: false,
        hasMore: records.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || _farmId == null) return;
    state = state.copyWith(isLoading: true);

    try {
      final newRecords = await _repository.getFeedingRecordsPaginated(
        _farmId!,
        limit: _pageSize,
        offset: state.records.length,
      );
      state = state.copyWith(
        records: [...state.records, ...newRecords],
        isLoading: false,
        hasMore: newRecords.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = const PaginatedFeedingState(isLoading: true);
    await loadInitial();
  }

  void addRecord(FeedingRecord record) {
    state = state.copyWith(records: [record, ...state.records]);
  }

  void removeRecord(String id) {
    state = state.copyWith(
      records: state.records.where((r) => r.id != id).toList(),
    );
  }
}

final paginatedFeedingProvider =
    NotifierProvider<PaginatedFeedingNotifier, PaginatedFeedingState>(
      PaginatedFeedingNotifier.new,
    );
