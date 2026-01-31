// Machine Learning models for livestock analytics
//
// These models represent the data structures used for ML predictions,
// SHAP explanations, health scores, and analytics.

// =============================================================================
// ENUMS
// =============================================================================

/// Status of an ML model
enum MLModelStatus {
  notTrained,
  training,
  ready,
  error,
  offline;

  String get displayName {
    return switch (this) {
      MLModelStatus.notTrained => 'Not Trained',
      MLModelStatus.training => 'Training',
      MLModelStatus.ready => 'Ready',
      MLModelStatus.error => 'Error',
      MLModelStatus.offline => 'Offline',
    };
  }
}

/// Risk level for health assessments
enum RiskLevel {
  low,
  moderate,
  high,
  critical;

  String get displayName {
    return switch (this) {
      RiskLevel.low => 'Low Risk',
      RiskLevel.moderate => 'Moderate Risk',
      RiskLevel.high => 'High Risk',
      RiskLevel.critical => 'Critical',
    };
  }
}

/// Prediction confidence level
enum ConfidenceLevel {
  low,
  medium,
  high;

  String get displayName {
    return switch (this) {
      ConfidenceLevel.low => 'Low',
      ConfidenceLevel.medium => 'Medium',
      ConfidenceLevel.high => 'High',
    };
  }
}

/// Forecast horizon for predictions
enum ForecastHorizon {
  days7(7, '7 Days'),
  days14(14, '14 Days'),
  days30(30, '30 Days');

  final int days;
  final String displayName;

  const ForecastHorizon(this.days, this.displayName);
}

// =============================================================================
// WEIGHT PREDICTION MODELS
// =============================================================================

/// A weight prediction for a single animal
class WeightPrediction {
  final String animalId;
  final String animalTagId;
  final String? animalName;
  final double currentWeight;
  final double predictedWeight;
  final double predictedGain;
  final int horizonDays;
  final DateTime predictionDate;
  final double confidenceScore;
  final double lowerBound;
  final double upperBound;
  final double? targetWeight;
  final int? daysToTarget;

  WeightPrediction({
    required this.animalId,
    required this.animalTagId,
    this.animalName,
    required this.currentWeight,
    required this.predictedWeight,
    required this.predictedGain,
    required this.horizonDays,
    required this.predictionDate,
    required this.confidenceScore,
    required this.lowerBound,
    required this.upperBound,
    this.targetWeight,
    this.daysToTarget,
  });

  /// Confidence level based on score
  ConfidenceLevel get confidenceLevel {
    if (confidenceScore >= 0.85) return ConfidenceLevel.high;
    if (confidenceScore >= 0.70) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }

  /// Percentage to target weight (0-100+)
  double get targetProgress {
    if (targetWeight == null) return 0;
    return (currentWeight / targetWeight!) * 100;
  }

  /// Whether the animal is predicted to reach target within horizon
  bool get willReachTarget {
    if (targetWeight == null) return false;
    return predictedWeight >= targetWeight!;
  }

  factory WeightPrediction.fromJson(Map<String, dynamic> json) {
    return WeightPrediction(
      animalId: json['animal_id'] ?? '',
      animalTagId: json['animal_tag_id'] ?? '',
      animalName: json['animal_name'],
      currentWeight: (json['current_weight'] ?? 0).toDouble(),
      predictedWeight: (json['predicted_weight'] ?? 0).toDouble(),
      predictedGain: (json['predicted_gain'] ?? 0).toDouble(),
      horizonDays: json['horizon_days'] ?? 14,
      predictionDate: DateTime.parse(
        json['prediction_date'] ?? DateTime.now().toIso8601String(),
      ),
      confidenceScore: (json['confidence_score'] ?? 0).toDouble(),
      lowerBound: (json['lower_bound'] ?? 0).toDouble(),
      upperBound: (json['upper_bound'] ?? 0).toDouble(),
      targetWeight: json['target_weight']?.toDouble(),
      daysToTarget: json['days_to_target'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'animal_id': animalId,
      'animal_tag_id': animalTagId,
      'animal_name': animalName,
      'current_weight': currentWeight,
      'predicted_weight': predictedWeight,
      'predicted_gain': predictedGain,
      'horizon_days': horizonDays,
      'prediction_date': predictionDate.toIso8601String(),
      'confidence_score': confidenceScore,
      'lower_bound': lowerBound,
      'upper_bound': upperBound,
      'target_weight': targetWeight,
      'days_to_target': daysToTarget,
    };
  }
}

/// Herd-level weight prediction summary
class HerdWeightSummary {
  final int totalAnimals;
  final double avgDailyGain;
  final double targetDailyGain;
  final int animalsGrowingWell;
  final int animalsReadyForMarket;
  final int daysToMarketReady;
  final DateTime lastUpdated;

  HerdWeightSummary({
    required this.totalAnimals,
    required this.avgDailyGain,
    required this.targetDailyGain,
    required this.animalsGrowingWell,
    required this.animalsReadyForMarket,
    required this.daysToMarketReady,
    required this.lastUpdated,
  });

  /// Percentage of animals growing well
  double get growingWellPercentage {
    if (totalAnimals == 0) return 0;
    return (animalsGrowingWell / totalAnimals) * 100;
  }

  /// Whether daily gain is meeting target
  bool get meetingTarget => avgDailyGain >= targetDailyGain;

  factory HerdWeightSummary.fromJson(Map<String, dynamic> json) {
    return HerdWeightSummary(
      totalAnimals: json['total_animals'] ?? 0,
      avgDailyGain: (json['avg_daily_gain'] ?? 0).toDouble(),
      targetDailyGain: (json['target_daily_gain'] ?? 0).toDouble(),
      animalsGrowingWell: json['animals_growing_well'] ?? 0,
      animalsReadyForMarket: json['animals_ready_for_market'] ?? 0,
      daysToMarketReady: json['days_to_market_ready'] ?? 0,
      lastUpdated: DateTime.parse(
        json['last_updated'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

// =============================================================================
// SHAP EXPLANATION MODELS
// =============================================================================

/// A single SHAP feature contribution
class ShapFeature {
  final String featureName;
  final String displayName;
  final double value;
  final double shapValue;
  final String? unit;
  final String? explanation;
  final bool isPositive;

  ShapFeature({
    required this.featureName,
    required this.displayName,
    required this.value,
    required this.shapValue,
    this.unit,
    this.explanation,
  }) : isPositive = shapValue >= 0;

  /// Absolute impact value
  double get absoluteImpact => shapValue.abs();

  factory ShapFeature.fromJson(Map<String, dynamic> json) {
    return ShapFeature(
      featureName: json['feature_name'] ?? '',
      displayName: json['display_name'] ?? json['feature_name'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      shapValue: (json['shap_value'] ?? 0).toDouble(),
      unit: json['unit'],
      explanation: json['explanation'],
    );
  }
}

/// SHAP explanation for a prediction
class ShapExplanation {
  final String animalId;
  final String predictionType;
  final double baseValue;
  final double predictedValue;
  final List<ShapFeature> features;
  final String? summary;
  final String? recommendation;
  final double modelConfidence;
  final DateTime generatedAt;

  ShapExplanation({
    required this.animalId,
    required this.predictionType,
    required this.baseValue,
    required this.predictedValue,
    required this.features,
    this.summary,
    this.recommendation,
    required this.modelConfidence,
    required this.generatedAt,
  });

  /// Features that increase the prediction
  List<ShapFeature> get positiveFeatures =>
      features.where((f) => f.isPositive).toList()
        ..sort((a, b) => b.shapValue.compareTo(a.shapValue));

  /// Features that decrease the prediction
  List<ShapFeature> get negativeFeatures =>
      features.where((f) => !f.isPositive).toList()
        ..sort((a, b) => a.shapValue.compareTo(b.shapValue));

  /// Total positive contribution
  double get totalPositive =>
      positiveFeatures.fold(0, (sum, f) => sum + f.shapValue);

  /// Total negative contribution
  double get totalNegative =>
      negativeFeatures.fold(0, (sum, f) => sum + f.shapValue);

  factory ShapExplanation.fromJson(Map<String, dynamic> json) {
    return ShapExplanation(
      animalId: json['animal_id'] ?? '',
      predictionType: json['prediction_type'] ?? 'weight',
      baseValue: (json['base_value'] ?? 0).toDouble(),
      predictedValue: (json['predicted_value'] ?? 0).toDouble(),
      features:
          (json['features'] as List<dynamic>?)
              ?.map((f) => ShapFeature.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      summary: json['summary'],
      recommendation: json['recommendation'],
      modelConfidence: (json['model_confidence'] ?? 0).toDouble(),
      generatedAt: DateTime.parse(
        json['generated_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

/// Global model feature importance
class FeatureImportance {
  final String featureName;
  final String displayName;
  final double importance;
  final String? description;

  FeatureImportance({
    required this.featureName,
    required this.displayName,
    required this.importance,
    this.description,
  });

  factory FeatureImportance.fromJson(Map<String, dynamic> json) {
    return FeatureImportance(
      featureName: json['feature_name'] ?? '',
      displayName: json['display_name'] ?? json['feature_name'] ?? '',
      importance: (json['importance'] ?? 0).toDouble(),
      description: json['description'],
    );
  }
}

// =============================================================================
// HEALTH ANALYTICS MODELS
// =============================================================================

/// Health score and risk assessment for an animal
class AnimalHealthScore {
  final String animalId;
  final String animalTagId;
  final String? animalName;
  final int healthScore;
  final RiskLevel riskLevel;
  final List<HealthRiskFactor> riskFactors;
  final DateTime lastUpdated;

  AnimalHealthScore({
    required this.animalId,
    required this.animalTagId,
    this.animalName,
    required this.healthScore,
    required this.riskLevel,
    required this.riskFactors,
    required this.lastUpdated,
  });

  /// Get points deducted by risk factors
  int get totalPointsDeducted =>
      riskFactors.fold(0, (sum, f) => sum + f.pointsImpact.abs());

  factory AnimalHealthScore.fromJson(Map<String, dynamic> json) {
    final score = json['health_score'] ?? 100;
    RiskLevel level;
    if (score >= 80) {
      level = RiskLevel.low;
    } else if (score >= 60) {
      level = RiskLevel.moderate;
    } else if (score >= 40) {
      level = RiskLevel.high;
    } else {
      level = RiskLevel.critical;
    }

    return AnimalHealthScore(
      animalId: json['animal_id'] ?? '',
      animalTagId: json['animal_tag_id'] ?? '',
      animalName: json['animal_name'],
      healthScore: score,
      riskLevel: level,
      riskFactors:
          (json['risk_factors'] as List<dynamic>?)
              ?.map((f) => HealthRiskFactor.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      lastUpdated: DateTime.parse(
        json['last_updated'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

/// A single health risk factor
class HealthRiskFactor {
  final String name;
  final String description;
  final RiskLevel severity;
  final int pointsImpact;
  final String? possibleCauses;
  final String? recommendation;

  HealthRiskFactor({
    required this.name,
    required this.description,
    required this.severity,
    required this.pointsImpact,
    this.possibleCauses,
    this.recommendation,
  });

  factory HealthRiskFactor.fromJson(Map<String, dynamic> json) {
    return HealthRiskFactor(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      severity: RiskLevel.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => RiskLevel.low,
      ),
      pointsImpact: json['points_impact'] ?? 0,
      possibleCauses: json['possible_causes'],
      recommendation: json['recommendation'],
    );
  }
}

/// Herd-level health summary
class HerdHealthSummary {
  final int overallScore;
  final int totalAnimals;
  final int atRiskCount;
  final int healthyCount;
  final int scoreChange;
  final String scoreChangePeriod;
  final List<UpcomingHealthTask> upcomingTasks;
  final DateTime lastUpdated;

  HerdHealthSummary({
    required this.overallScore,
    required this.totalAnimals,
    required this.atRiskCount,
    required this.healthyCount,
    required this.scoreChange,
    required this.scoreChangePeriod,
    required this.upcomingTasks,
    required this.lastUpdated,
  });

  /// Get risk level based on overall score
  RiskLevel get riskLevel {
    if (overallScore >= 80) return RiskLevel.low;
    if (overallScore >= 60) return RiskLevel.moderate;
    if (overallScore >= 40) return RiskLevel.high;
    return RiskLevel.critical;
  }

  /// Get health status label
  String get statusLabel {
    if (overallScore >= 85) return 'Excellent';
    if (overallScore >= 70) return 'Healthy';
    if (overallScore >= 50) return 'Fair';
    return 'At Risk';
  }

  factory HerdHealthSummary.fromJson(Map<String, dynamic> json) {
    return HerdHealthSummary(
      overallScore: json['overall_score'] ?? 0,
      totalAnimals: json['total_animals'] ?? 0,
      atRiskCount: json['at_risk_count'] ?? 0,
      healthyCount: json['healthy_count'] ?? 0,
      scoreChange: json['score_change'] ?? 0,
      scoreChangePeriod: json['score_change_period'] ?? 'last week',
      upcomingTasks:
          (json['upcoming_tasks'] as List<dynamic>?)
              ?.map(
                (t) => UpcomingHealthTask.fromJson(t as Map<String, dynamic>),
              )
              .toList() ??
          [],
      lastUpdated: DateTime.parse(
        json['last_updated'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

/// An upcoming health task
class UpcomingHealthTask {
  final String type;
  final String title;
  final String description;
  final DateTime dueDate;
  final List<String> animalIds;
  final int animalCount;

  UpcomingHealthTask({
    required this.type,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.animalIds,
    required this.animalCount,
  });

  /// Whether the task is overdue
  bool get isOverdue => dueDate.isBefore(DateTime.now());

  /// Whether the task is due today
  bool get isDueToday {
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  factory UpcomingHealthTask.fromJson(Map<String, dynamic> json) {
    final animalIds =
        (json['animal_ids'] as List<dynamic>?)?.cast<String>() ?? [];
    return UpcomingHealthTask(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dueDate: DateTime.parse(
        json['due_date'] ?? DateTime.now().toIso8601String(),
      ),
      animalIds: animalIds,
      animalCount: json['animal_count'] ?? animalIds.length,
    );
  }
}

// =============================================================================
// AI INSIGHTS
// =============================================================================

/// An AI-generated insight or recommendation
class AIInsight {
  final String id;
  final String title;
  final String description;
  final String? recommendation;
  final String category;
  final String priority;
  final DateTime createdAt;
  final bool isDismissed;

  AIInsight({
    required this.id,
    required this.title,
    required this.description,
    this.recommendation,
    required this.category,
    required this.priority,
    required this.createdAt,
    this.isDismissed = false,
  });

  factory AIInsight.fromJson(Map<String, dynamic> json) {
    return AIInsight(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      recommendation: json['recommendation'],
      category: json['category'] ?? 'general',
      priority: json['priority'] ?? 'medium',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      isDismissed: json['is_dismissed'] ?? false,
    );
  }
}

// =============================================================================
// GROWTH DATA FOR CHARTS
// =============================================================================

/// A single data point for growth charts
class GrowthDataPoint {
  final DateTime date;
  final double weight;
  final bool isPredicted;

  GrowthDataPoint({
    required this.date,
    required this.weight,
    this.isPredicted = false,
  });

  factory GrowthDataPoint.fromJson(Map<String, dynamic> json) {
    return GrowthDataPoint(
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      weight: (json['weight'] ?? 0).toDouble(),
      isPredicted: json['is_predicted'] ?? false,
    );
  }
}

/// Growth statistics for an animal
class GrowthStats {
  final double dailyGain7d;
  final double dailyGain30d;
  final double dailyGainLifetime;
  final double breedAverage;
  final double changePercent7d;
  final double changePercent30d;

  GrowthStats({
    required this.dailyGain7d,
    required this.dailyGain30d,
    required this.dailyGainLifetime,
    required this.breedAverage,
    required this.changePercent7d,
    required this.changePercent30d,
  });

  /// Percentage difference from breed average
  double get breedComparisonPercent {
    if (breedAverage == 0) return 0;
    return ((dailyGainLifetime - breedAverage) / breedAverage) * 100;
  }

  factory GrowthStats.fromJson(Map<String, dynamic> json) {
    return GrowthStats(
      dailyGain7d: (json['daily_gain_7d'] ?? 0).toDouble(),
      dailyGain30d: (json['daily_gain_30d'] ?? 0).toDouble(),
      dailyGainLifetime: (json['daily_gain_lifetime'] ?? 0).toDouble(),
      breedAverage: (json['breed_average'] ?? 0).toDouble(),
      changePercent7d: (json['change_percent_7d'] ?? 0).toDouble(),
      changePercent30d: (json['change_percent_30d'] ?? 0).toDouble(),
    );
  }
}

// =============================================================================
// MODEL PERFORMANCE METRICS
// =============================================================================

/// Performance metrics for an ML model
class ModelMetrics {
  final String modelName;
  final double mae;
  final double mape;
  final double r2;
  final int trainingSamples;
  final DateTime lastTrainedAt;
  final String version;

  ModelMetrics({
    required this.modelName,
    required this.mae,
    required this.mape,
    required this.r2,
    required this.trainingSamples,
    required this.lastTrainedAt,
    required this.version,
  });

  factory ModelMetrics.fromJson(Map<String, dynamic> json) {
    return ModelMetrics(
      modelName: json['model_name'] ?? '',
      mae: (json['mae'] ?? 0).toDouble(),
      mape: (json['mape'] ?? 0).toDouble(),
      r2: (json['r2'] ?? 0).toDouble(),
      trainingSamples: json['training_samples'] ?? 0,
      lastTrainedAt: DateTime.parse(
        json['last_trained_at'] ?? DateTime.now().toIso8601String(),
      ),
      version: json['version'] ?? '1.0',
    );
  }
}
