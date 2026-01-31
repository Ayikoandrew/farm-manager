import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/health_record.dart';
import '../repositories/health_repository.dart';
import 'providers.dart';

const int _pageSize = 20;

/// State for paginated health records
class PaginatedHealthState {
  final List<HealthRecord> records;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const PaginatedHealthState({
    this.records = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  PaginatedHealthState copyWith({
    List<HealthRecord>? records,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return PaginatedHealthState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

/// Notifier for paginated health records
class PaginatedHealthNotifier extends Notifier<PaginatedHealthState> {
  @override
  PaginatedHealthState build() {
    final farmId = ref.watch(activeFarmIdProvider);
    if (farmId == null) {
      return const PaginatedHealthState(hasMore: false);
    }
    Future.microtask(() => loadInitial());
    return const PaginatedHealthState(isLoading: true);
  }

  HealthRepository get _repository => ref.read(healthRepositoryProvider);
  String? get _farmId => ref.read(activeFarmIdProvider);

  Future<void> loadInitial() async {
    if (_farmId == null) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final records = await _repository.getHealthRecordsPaginated(
        _farmId!,
        limit: _pageSize,
        offset: 0,
      );
      state = PaginatedHealthState(
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
      final newRecords = await _repository.getHealthRecordsPaginated(
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
    state = const PaginatedHealthState(isLoading: true);
    await loadInitial();
  }

  void addRecord(HealthRecord record) {
    state = state.copyWith(records: [record, ...state.records]);
  }

  void removeRecord(String id) {
    state = state.copyWith(
      records: state.records.where((r) => r.id != id).toList(),
    );
  }
}

final paginatedHealthProvider =
    NotifierProvider<PaginatedHealthNotifier, PaginatedHealthState>(
      PaginatedHealthNotifier.new,
    );
