import 'package:flutter/material.dart';
import '../ml_theme.dart';
import '../../../models/ml_models.dart';

/// A horizontal bar showing SHAP feature contribution
class FeatureContributionBar extends StatelessWidget {
  final ShapFeature feature;
  final double maxAbsValue;
  final bool showValue;

  const FeatureContributionBar({
    super.key,
    required this.feature,
    required this.maxAbsValue,
    this.showValue = true,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = maxAbsValue > 0
        ? (feature.absoluteImpact / maxAbsValue).clamp(0.0, 1.0)
        : 0.0;
    final color = feature.isPositive
        ? MLTheme.shapPositive
        : MLTheme.shapNegative;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MLTheme.surface,
        borderRadius: MLTheme.borderRadiusMd,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                feature.isPositive ? Icons.add_circle : Icons.remove_circle,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(feature.displayName, style: MLTheme.titleSmall),
              ),
              if (showValue)
                Text(
                  '${feature.isPositive ? '+' : ''}${feature.shapValue.toStringAsFixed(1)} kg',
                  style: MLTheme.bodyMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: MLTheme.borderRadiusSm,
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
          if (feature.explanation != null) ...[
            const SizedBox(height: 8),
            Text(feature.explanation!, style: MLTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// A section showing positive or negative SHAP factors
class FactorsSection extends StatelessWidget {
  final String title;
  final List<ShapFeature> features;
  final bool isPositive;
  final double maxAbsValue;

  const FactorsSection({
    super.key,
    required this.title,
    required this.features,
    required this.isPositive,
    required this.maxAbsValue,
  });

  @override
  Widget build(BuildContext context) {
    if (features.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: MLTheme.titleMedium.copyWith(
            color: MLTheme.textSubtleColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: isDark ? Colors.white12 : Colors.grey.shade300),
        const SizedBox(height: 12),
        ...features.map(
          (feature) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FeatureContributionBar(
              feature: feature,
              maxAbsValue: maxAbsValue,
            ),
          ),
        ),
      ],
    );
  }
}

/// Global feature importance chart
class FeatureImportanceChart extends StatelessWidget {
  final List<FeatureImportance> features;
  final String? title;

  const FeatureImportanceChart({super.key, required this.features, this.title});

  @override
  Widget build(BuildContext context) {
    if (features.isEmpty) return const SizedBox.shrink();

    final maxImportance = features
        .map((f) => f.importance)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MLTheme.cardDecorationFor(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: MLTheme.titleMedium.copyWith(
                color: MLTheme.textPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 16),
          ],
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FeatureImportanceRow(
                feature: feature,
                maxValue: maxImportance,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureImportanceRow extends StatelessWidget {
  final FeatureImportance feature;
  final double maxValue;

  const _FeatureImportanceRow({required this.feature, required this.maxValue});

  @override
  Widget build(BuildContext context) {
    final percentage = maxValue > 0
        ? (feature.importance / maxValue).clamp(0.0, 1.0)
        : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            feature.displayName,
            style: MLTheme.bodySmall.copyWith(
              color: MLTheme.textPrimaryColor(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: MLTheme.borderRadiusSm,
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(MLTheme.trustBlue),
              minHeight: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            feature.importance.toStringAsFixed(1),
            style: MLTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: MLTheme.textPrimaryColor(context),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

/// SHAP summary card with key information
class ShapSummaryCard extends StatelessWidget {
  final ShapExplanation explanation;
  final VoidCallback? onLearnMore;

  const ShapSummaryCard({
    super.key,
    required this.explanation,
    this.onLearnMore,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MLTheme.trustBlue.withValues(alpha: isDark ? 0.15 : 0.05),
        borderRadius: MLTheme.borderRadiusLg,
        border: Border.all(color: MLTheme.trustBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (explanation.summary != null) ...[
            Text(
              '"${explanation.summary}"',
              style: MLTheme.bodyLarge.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.5,
                color: MLTheme.textPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              _InfoChip(
                icon: Icons.psychology,
                label: 'Model Confidence',
                value:
                    '${(explanation.modelConfidence * 100).toStringAsFixed(0)}%',
              ),
              const SizedBox(width: 12),
              _InfoChip(
                icon: Icons.schedule,
                label: 'Last Updated',
                value: _formatTime(explanation.generatedAt),
              ),
            ],
          ),
          if (onLearnMore != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onLearnMore,
              icon: const Icon(Icons.info_outline, size: 18),
              label: const Text('Learn More'),
              style: TextButton.styleFrom(foregroundColor: MLTheme.trustBlue),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: MLTheme.surfaceColor(context),
          borderRadius: MLTheme.borderRadiusMd,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: MLTheme.textSubtleColor(context)),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: MLTheme.labelSmall.copyWith(
                      color: MLTheme.textSubtleColor(context),
                    ),
                  ),
                  Text(
                    value,
                    style: MLTheme.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: MLTheme.textPrimaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Recommendation card based on SHAP analysis
class RecommendationCard extends StatelessWidget {
  final String recommendation;
  final List<String>? bulletPoints;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    this.bulletPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MLTheme.farmGreen.withValues(alpha: 0.05),
        borderRadius: MLTheme.borderRadiusLg,
        border: Border.all(color: MLTheme.farmGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MLTheme.farmGreen.withValues(alpha: 0.1),
                  borderRadius: MLTheme.borderRadiusMd,
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: MLTheme.farmGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'RECOMMENDATION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: MLTheme.farmGreen,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recommendation,
            style: MLTheme.bodyMedium.copyWith(
              height: 1.5,
              color: MLTheme.textPrimaryColor(context),
            ),
          ),
          if (bulletPoints != null && bulletPoints!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...bulletPoints!.map(
              (point) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: MLTheme.bodyMedium.copyWith(
                        color: MLTheme.textPrimaryColor(context),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        point,
                        style: MLTheme.bodyMedium.copyWith(
                          color: MLTheme.textPrimaryColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
