import 'package:flutter/material.dart';
import '../ml_theme.dart';
import '../widgets/widgets.dart';
import '../../../models/ml_models.dart';
import 'shap_explanation_screen.dart';

/// Weight Prediction Detail Screen
///
/// Shows detailed prediction information for a single animal:
/// - Current vs predicted weight
/// - Growth trajectory chart
/// - Confidence range
/// - Link to SHAP explanations
/// - Action buttons (record weight, schedule sale)
class WeightPredictionDetailScreen extends StatelessWidget {
  final WeightPrediction prediction;
  final List<GrowthDataPoint> chartData;

  const WeightPredictionDetailScreen({
    super.key,
    required this.prediction,
    required this.chartData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MLTheme.backgroundColor(context),
      appBar: AppBar(
        title: Text(
          '${prediction.animalTagId} "${prediction.animalName}"',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: MLTheme.textPrimaryColor(context),
          ),
        ),
        backgroundColor: MLTheme.surfaceColor(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20),
                    SizedBox(width: 12),
                    Text('Share'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 12),
                    Text('Export Data'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main prediction card
            _buildPredictionCard(context),
            const SizedBox(height: 20),

            // Growth trajectory chart
            _buildGrowthTrajectoryCard(context),
            const SizedBox(height: 20),

            // Why this prediction
            _buildWhyPredictionCard(context),
            const SizedBox(height: 20),

            // Growth stats
            _buildGrowthStatsCard(context),
            const SizedBox(height: 24),

            // Action buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard(BuildContext context) {
    final emoji = MLTheme.getAnimalEmoji('pig');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: MLTheme.elevatedCardDecorationFor(context),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),

          // Current weight
          Text(
            'Current Weight',
            style: MLTheme.labelMedium.copyWith(
              color: MLTheme.textSubtleColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${prediction.currentWeight.toStringAsFixed(0)} kg',
            style: MLTheme.numberLarge.copyWith(
              color: MLTheme.textPrimaryColor(context),
            ),
          ),

          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 2,
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
          const SizedBox(height: 20),

          // Predicted weight
          Text(
            'Predicted in ${14} days',
            style: MLTheme.labelMedium.copyWith(
              color: MLTheme.textSubtleColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${prediction.predictedWeight.toStringAsFixed(0)} kg',
            style: MLTheme.numberLarge.copyWith(color: MLTheme.farmGreen),
          ),
          Text(
            '(+${prediction.predictedGain.toStringAsFixed(0)} kg gain)',
            style: MLTheme.bodyMedium.copyWith(color: MLTheme.successGreen),
          ),

          const SizedBox(height: 20),

          // Confidence range
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade50,
              borderRadius: MLTheme.borderRadiusLg,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Confidence: ',
                      style: MLTheme.bodyMedium.copyWith(
                        color: MLTheme.textPrimaryColor(context),
                      ),
                    ),
                    Text(
                      prediction.confidenceLevel.displayName,
                      style: MLTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: MLTheme.getConfidenceColor(
                          prediction.confidenceScore,
                        ),
                      ),
                    ),
                    Text(
                      ' (±${((prediction.upperBound - prediction.lowerBound) / 2).toStringAsFixed(1)} kg)',
                      style: MLTheme.bodyMedium.copyWith(
                        color: MLTheme.textPrimaryColor(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Range: ${prediction.lowerBound.toStringAsFixed(0)} - ${prediction.upperBound.toStringAsFixed(0)} kg',
                  style: MLTheme.bodySmall.copyWith(
                    color: MLTheme.textSubtleColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthTrajectoryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MLTheme.cardDecorationFor(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, color: MLTheme.trustBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Growth Trajectory',
                style: MLTheme.titleMedium.copyWith(
                  color: MLTheme.textPrimaryColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FlGrowthChart(
            dataPoints: chartData,
            showLabels: true,
            showPredicted: true,
            height: 200,
          ),
        ],
      ),
    );
  }

  Widget _buildWhyPredictionCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToShapExplanation(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MLTheme.trustBlue.withValues(alpha: 0.05),
          borderRadius: MLTheme.borderRadiusLg,
          border: Border.all(color: MLTheme.trustBlue.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: MLTheme.trustBlue.withValues(alpha: 0.1),
                borderRadius: MLTheme.borderRadiusMd,
              ),
              child: const Icon(
                Icons.search,
                color: MLTheme.trustBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Why this prediction?', style: MLTheme.titleSmall),
                  SizedBox(height: 2),
                  Text(
                    'See what factors influenced this prediction',
                    style: MLTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: MLTheme.trustBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthStatsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MLTheme.cardDecorationFor(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: MLTheme.farmGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Growth Stats',
                style: MLTheme.titleMedium.copyWith(
                  color: MLTheme.textPrimaryColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            context,
            'Daily Gain (7d)',
            '0.92 kg/day',
            '↑ +8%',
            true,
          ),
          Divider(height: 24, color: MLTheme.dividerColor(context)),
          _buildStatRow(
            context,
            'Daily Gain (30d)',
            '0.85 kg/day',
            '↑ +3%',
            true,
          ),
          Divider(height: 24, color: MLTheme.dividerColor(context)),
          _buildStatRow(
            context,
            'Daily Gain (lifetime)',
            '0.82 kg/day',
            null,
            null,
          ),
          Divider(height: 24, color: MLTheme.dividerColor(context)),
          _buildStatRow(context, 'vs Breed Average', '+12%', 'better', true),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    String? trend,
    bool? isPositive,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: MLTheme.bodyMedium.copyWith(
              color: MLTheme.textPrimaryColor(context),
            ),
          ),
        ),
        Text(
          value,
          style: MLTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: MLTheme.textPrimaryColor(context),
          ),
        ),
        if (trend != null) ...[
          const SizedBox(width: 8),
          Text(
            trend,
            style: MLTheme.bodySmall.copyWith(
              color: isPositive == true
                  ? MLTheme.successGreen
                  : isPositive == false
                  ? MLTheme.dangerRed
                  : MLTheme.textSubtleColor(context),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _recordWeight(context),
            icon: const Icon(Icons.monitor_weight_outlined),
            label: const Text('Record Weight'),
            style: OutlinedButton.styleFrom(
              foregroundColor: MLTheme.trustBlue,
              side: const BorderSide(color: MLTheme.trustBlue),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _scheduleSale(context),
            icon: const Icon(Icons.calendar_today),
            label: const Text('Schedule Sale'),
            style: FilledButton.styleFrom(
              backgroundColor: MLTheme.farmGreen,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$action - Coming soon')));
  }

  void _navigateToShapExplanation(BuildContext context) {
    // Create mock SHAP explanation
    final explanation = ShapExplanation(
      animalId: prediction.animalId,
      predictionType: 'weight',
      baseValue: 70,
      predictedValue: prediction.predictedWeight,
      features: [
        ShapFeature(
          featureName: 'current_weight',
          displayName:
              'Current Weight (${prediction.currentWeight.toStringAsFixed(0)} kg)',
          value: prediction.currentWeight,
          shapValue: 40.6,
          unit: 'kg',
          explanation: 'Heavier animals tend to gain more weight',
        ),
        ShapFeature(
          featureName: 'lifetime_growth_rate',
          displayName: 'Lifetime Growth Rate (0.85 kg/day)',
          value: 0.85,
          shapValue: 1.1,
          unit: 'kg/day',
          explanation: 'Consistent historical growth supports prediction',
        ),
        ShapFeature(
          featureName: 'prediction_horizon',
          displayName: 'Prediction Horizon (${prediction.horizonDays} days)',
          value: prediction.horizonDays.toDouble(),
          shapValue: 0.9,
          unit: 'days',
          explanation: 'Longer time = more potential growth',
        ),
        ShapFeature(
          featureName: 'weight_variability',
          displayName: 'Weight Variability',
          value: 2.5,
          shapValue: -4.9,
          explanation: 'Recent weight fluctuations reduce confidence',
        ),
        ShapFeature(
          featureName: 'weekly_change',
          displayName: 'Weekly Weight Change',
          value: -1.2,
          shapValue: -2.6,
          explanation: 'Slower recent growth affects forecast',
        ),
        ShapFeature(
          featureName: '30d_velocity',
          displayName: '30-Day Growth Velocity',
          value: 0.78,
          shapValue: -1.9,
          explanation: 'Monthly growth trend is below optimal',
        ),
      ],
      summary:
          '${prediction.animalName} is predicted to gain ${prediction.predictedGain.toStringAsFixed(0)} kg because of strong current weight and steady growth rate. The main limiting factor is recent weight variability.',
      recommendation:
          'The weight variability suggests inconsistent feeding. Consider checking feed quality and quantity, ensuring consistent feeding schedule, and recording weights more frequently.',
      modelConfidence: prediction.confidenceScore,
      generatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ShapExplanationScreen(
          explanation: explanation,
          animalName: prediction.animalName ?? prediction.animalTagId,
        ),
      ),
    );
  }

  void _recordWeight(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Record Weight - Coming soon')),
    );
  }

  void _scheduleSale(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Schedule Sale - Coming soon')),
    );
  }
}
