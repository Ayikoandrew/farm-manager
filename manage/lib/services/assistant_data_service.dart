import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/animal.dart';
import '../providers/providers.dart';

/// Service to fetch real farm data for the AI Assistant
class AssistantDataService {
  final Ref _ref;

  AssistantDataService(this._ref);

  /// Get animal by tag ID from the active farm
  Future<Animal?> getAnimalByTagId(String tagId) async {
    final farmId = _ref.read(activeFarmIdProvider);
    if (farmId == null) return null;

    final repository = _ref.read(animalRepositoryProvider);
    return repository.getAnimalByTagId(farmId, tagId);
  }

  /// Get all animals from the active farm
  List<Animal> getAllAnimals() {
    final animalsAsync = _ref.read(animalsProvider);
    return animalsAsync.maybeWhen(data: (animals) => animals, orElse: () => []);
  }

  /// Search animals by name or tag (partial match)
  List<Animal> searchAnimals(String query) {
    final animals = getAllAnimals();
    final lowerQuery = query.toLowerCase();
    return animals.where((animal) {
      return animal.tagId.toLowerCase().contains(lowerQuery) ||
          (animal.name?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Get animal statistics for the active farm
  Map<String, dynamic> getAnimalStats() {
    final animals = getAllAnimals();
    final bySpecies = <String, int>{};
    final byStatus = <String, int>{};

    for (final animal in animals) {
      final speciesName = animal.species.displayName;
      bySpecies[speciesName] = (bySpecies[speciesName] ?? 0) + 1;
      byStatus[animal.status.name] = (byStatus[animal.status.name] ?? 0) + 1;
    }

    return {
      'totalCount': animals.length,
      'bySpecies': bySpecies,
      'byStatus': byStatus,
    };
  }

  /// Format animal data for the AI to use in rendering
  Map<String, dynamic> animalToDisplayData(Animal animal) {
    return {
      'name': animal.name,
      'tagId': animal.tagId,
      'species': animal.species.displayName,
      'breed': animal.breed,
      'status': animal.status.name,
    };
  }
}

/// Provider for the assistant data service
final assistantDataServiceProvider = Provider<AssistantDataService>((ref) {
  return AssistantDataService(ref);
});
