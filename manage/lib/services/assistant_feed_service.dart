import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manage/providers/providers.dart';

import '../models/feeding_record.dart';

class AssistantFeedService {
  final Ref _ref;

  AssistantFeedService(this._ref);

  /// Get Feed by animal ID from active farm
  Future<FeedingRecord?> getFeedByAnimalId(String tagId) async {
    final farmId = _ref.watch(activeFarmIdProvider);
    if (farmId == null) return null;

    final repository = _ref.read(feedingRepositoryProvider);
    return repository.getAnimalFeedByTagId(farmId, tagId);
  }
}
