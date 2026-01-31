import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/weight_record.dart';
import '../repositories/weight_repository.dart';
import 'providers.dart';

const int _pageSize = 20;

/// State for paginated weight records
class PaginatedWeightState {
  final List<WeightRecord> records;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const PaginatedWeightState({
    this.records = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  PaginatedWeightState copyWith({
    List<WeightRecord>? records,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return PaginatedWeightState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

/// Notifier for paginated weight records
class PaginatedWeightNotifier extends Notifier<PaginatedWeightState> {
  @override
  PaginatedWeightState build() {
    final farmId = ref.watch(activeFarmIdProvider);
    if (farmId == null) {
      return const PaginatedWeightState(hasMore: false);
    }
    Future.microtask(() => loadInitial());
    return const PaginatedWeightState(isLoading: true);
  }

  WeightRepository get _repository => ref.read(weightRepositoryProvider);
  String? get _farmId => ref.read(activeFarmIdProvider);

  Future<void> loadInitial() async {
    if (_farmId == null) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final records = await _repository.getWeightRecordsPaginated(
        _farmId!,
        limit: _pageSize,
        offset: 0,
      );
      state = PaginatedWeightState(
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
      final newRecords = await _repository.getWeightRecordsPaginated(
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
    state = const PaginatedWeightState(isLoading: true);
    await loadInitial();
  }

  void addRecord(WeightRecord record) {
    state = state.copyWith(records: [record, ...state.records]);
  }

  void removeRecord(String id) {
    state = state.copyWith(
      records: state.records.where((r) => r.id != id).toList(),
    );
  }
}

final paginatedWeightProvider =
    NotifierProvider<PaginatedWeightNotifier, PaginatedWeightState>(
      PaginatedWeightNotifier.new,
    );
