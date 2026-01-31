import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/animal.dart';
import '../repositories/animal_repository.dart';
import 'providers.dart';

const int pageSize = 20;

/// State for paginated animals
class PaginatedAnimalsState {
  final List<Animal> animals;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int currentPage;

  const PaginatedAnimalsState({
    this.animals = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 0,
  });

  PaginatedAnimalsState copyWith({
    List<Animal>? animals,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? currentPage,
  }) {
    return PaginatedAnimalsState(
      animals: animals ?? this.animals,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// Notifier for paginated animals
class PaginatedAnimalsNotifier extends Notifier<PaginatedAnimalsState> {
  @override
  PaginatedAnimalsState build() {
    final farmId = ref.watch(activeFarmIdProvider);

    if (farmId == null) {
      return const PaginatedAnimalsState(hasMore: false);
    }

    Future.microtask(() => loadInitial());
    return const PaginatedAnimalsState(isLoading: true);
  }

  AnimalRepository get _repository => ref.read(animalRepositoryProvider);
  String? get _farmId => ref.read(activeFarmIdProvider);

  Future<void> loadInitial() async {
    if (_farmId == null) {
      state = const PaginatedAnimalsState(hasMore: false);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final animals = await _repository.getAnimalsPaginated(
        _farmId!,
        limit: pageSize,
        offset: 0,
      );

      state = PaginatedAnimalsState(
        animals: animals,
        isLoading: false,
        hasMore: animals.length >= pageSize,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || _farmId == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final offset = state.animals.length;
      final newAnimals = await _repository.getAnimalsPaginated(
        _farmId!,
        limit: pageSize,
        offset: offset,
      );

      state = state.copyWith(
        animals: [...state.animals, ...newAnimals],
        isLoading: false,
        hasMore: newAnimals.length >= pageSize,
        currentPage: state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = const PaginatedAnimalsState(isLoading: true);
    await loadInitial();
  }

  /// Add animal to the list (for optimistic updates)
  void addAnimal(Animal animal) {
    state = state.copyWith(animals: [animal, ...state.animals]);
  }

  /// Remove animal from the list
  void removeAnimal(String animalId) {
    state = state.copyWith(
      animals: state.animals.where((a) => a.id != animalId).toList(),
    );
  }

  /// Update animal in the list
  void updateAnimal(Animal animal) {
    state = state.copyWith(
      animals: state.animals
          .map((a) => a.id == animal.id ? animal : a)
          .toList(),
    );
  }
}

/// Provider for paginated animals
final paginatedAnimalsProvider =
    NotifierProvider<PaginatedAnimalsNotifier, PaginatedAnimalsState>(
      PaginatedAnimalsNotifier.new,
    );
