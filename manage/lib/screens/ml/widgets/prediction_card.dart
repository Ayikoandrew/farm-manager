import 'package:flutter/material.dart';
import '../ml_theme.dart';
import '../../../models/ml_models.dart';

/// A card displaying weight prediction information for an animal
class PredictionCard extends StatelessWidget {
  final WeightPrediction prediction;
  final String? animalEmoji;
  final VoidCallback? onTap;
  final bool showProgress;

  const PredictionCard({
    super.key,
    required this.prediction,
    this.animalEmoji,
    this.onTap,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: MLTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with animal info
            Row(
              children: [
                if (animalEmoji != null)
                  Text(animalEmoji!, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prediction.animalName ?? prediction.animalTagId,
                        style: MLTheme.titleMedium,
                      ),
                      if (prediction.animalName != null)
                        Text(prediction.animalTagId, style: MLTheme.bodySmall),
                    ],
                  ),
                ),
                _buildConfidenceBadge(),
              ],
            ),
            const SizedBox(height: 16),

            // Weight prediction
            Row(
              children: [
                Text(
                  'Current: ${prediction.currentWeight.toStringAsFixed(1)}kg',
                  style: MLTheme.bodyMedium,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: MLTheme.textSubtle,
                  ),
                ),
                Text(
                  'Predicted: ${prediction.predictedWeight.toStringAsFixed(1)}kg',
                  style: MLTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: MLTheme.farmGreen,
                  ),
                ),
                Text(
                  ' in ${prediction.horizonDays} days',
                  style: MLTheme.bodySmall,
                ),
              ],
            ),

            // Progress bar
            if (showProgress && prediction.targetWeight != null) ...[
              const SizedBox(height: 12),
              _buildProgressBar(),
            ],

            // View details
            if (onTap != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View Details',
                    style: MLTheme.bodySmall.copyWith(color: MLTheme.trustBlue),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: MLTheme.trustBlue,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge() {
    final confidence = prediction.confidenceLevel;
    final (color, label) = switch (confidence) {
      ConfidenceLevel.high => (MLTheme.successGreen, 'High'),
      ConfidenceLevel.medium => (MLTheme.warningOrange, 'Medium'),
      ConfidenceLevel.low => (MLTheme.dangerRed, 'Low'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: MLTheme.borderRadiusSm,
      ),
      child: Text(
        '${(prediction.confidenceScore * 100).toStringAsFixed(0)}%',
        style: MLTheme.labelSmall.copyWith(color: color),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = prediction.targetProgress.clamp(0, 100) / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Target: ${prediction.targetWeight!.toStringAsFixed(0)}kg',
              style: MLTheme.bodySmall,
            ),
            Text(
              '${prediction.targetProgress.toStringAsFixed(0)}%',
              style: MLTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: MLTheme.borderRadiusSm,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(
              progress >= 1.0 ? MLTheme.successGreen : MLTheme.farmGreen,
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

/// Compact prediction card for list views
class CompactPredictionCard extends StatelessWidget {
  final String tagId;
  final String? name;
  final double currentWeight;
  final double predictedWeight;
  final int days;
  final double progress;
  final String? emoji;
  final VoidCallback? onTap;

  const CompactPredictionCard({
    super.key,
    required this.tagId,
    this.name,
    required this.currentWeight,
    required this.predictedWeight,
    required this.days,
    required this.progress,
    this.emoji,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: emoji != null
          ? Text(emoji!, style: const TextStyle(fontSize: 28))
          : const CircleAvatar(
              backgroundColor: MLTheme.farmGreen,
              child: Icon(Icons.pets, color: Colors.white),
            ),
      title: Text(name ?? tagId, style: MLTheme.titleSmall),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current: ${currentWeight.toStringAsFixed(0)}kg → Predicted: ${predictedWeight.toStringAsFixed(0)}kg in $days days',
            style: MLTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: MLTheme.borderRadiusSm,
            child: LinearProgressIndicator(
              value: (progress / 100).clamp(0, 1),
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(MLTheme.farmGreen),
              minHeight: 6,
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${progress.toStringAsFixed(0)}%',
            style: MLTheme.titleSmall.copyWith(
              color: progress >= 100
                  ? MLTheme.successGreen
                  : MLTheme.textPrimary,
            ),
          ),
          const Icon(Icons.chevron_right, color: MLTheme.textSubtle, size: 20),
        ],
      ),
    );
  }
}
