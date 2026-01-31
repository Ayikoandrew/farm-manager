import 'package:flutter/material.dart';
import '../ml_theme.dart';
import '../widgets/widgets.dart';
import '../../../models/ml_models.dart';

/// SHAP Explanation Screen
///
/// Shows why a prediction was made by displaying SHAP values:
/// - Summary explanation in natural language
/// - Factors increasing the prediction (positive SHAP)
/// - Factors decreasing the prediction (negative SHAP)
/// - Recommendations based on analysis
/// - Model confidence information
class ShapExplanationScreen extends StatelessWidget {
  final ShapExplanation explanation;
  final String animalName;

  const ShapExplanationScreen({
    super.key,
    required this.explanation,
    required this.animalName,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate max absolute SHAP value for scaling bars
    final maxAbsValue = explanation.features
        .map((f) => f.absoluteImpact)
        .reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: MLTheme.backgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Why This Prediction?',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: MLTheme.textPrimaryColor(context),
          ),
        ),
        backgroundColor: MLTheme.surfaceColor(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showInfoDialog(context),
            icon: const Icon(Icons.info_outline),
            tooltip: 'About SHAP',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary card
            if (explanation.summary != null) _buildSummaryCard(context),
            const SizedBox(height: 24),

            // Positive factors
            if (explanation.positiveFeatures.isNotEmpty) ...[
              FactorsSection(
                title: 'Factors Increasing Weight Gain',
                features: explanation.positiveFeatures,
                isPositive: true,
                maxAbsValue: maxAbsValue,
              ),
              const SizedBox(height: 24),
            ],

            // Negative factors
            if (explanation.negativeFeatures.isNotEmpty) ...[
              FactorsSection(
                title: 'Factors Limiting Weight Gain',
                features: explanation.negativeFeatures,
                isPositive: false,
                maxAbsValue: maxAbsValue,
              ),
              const SizedBox(height: 24),
            ],

            // Recommendation card
            if (explanation.recommendation != null)
              RecommendationCard(
                recommendation: explanation.recommendation!,
                bulletPoints: const [
                  'Checking feed quality and quantity',
                  'Ensuring consistent feeding schedule',
                  'Recording weights more frequently',
                ],
              ),
            const SizedBox(height: 24),

            // Model info footer
            _buildModelInfoFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? MLTheme.trustBlue.withValues(alpha: 0.15)
            : MLTheme.trustBlue.withValues(alpha: 0.05),
        borderRadius: MLTheme.borderRadiusLg,
        border: Border.all(color: MLTheme.trustBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MLTheme.trustBlue.withValues(alpha: 0.1),
                  borderRadius: MLTheme.borderRadiusMd,
                ),
                child: const Icon(
                  Icons.psychology,
                  color: MLTheme.trustBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                animalName,
                style: MLTheme.titleMedium.copyWith(
                  color: MLTheme.textPrimaryColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '"${explanation.summary}"',
            style: MLTheme.bodyLarge.copyWith(
              fontStyle: FontStyle.italic,
              height: 1.6,
              color: MLTheme.textPrimaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelInfoFooter(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confidenceColor = MLTheme.getConfidenceColor(
      explanation.modelConfidence,
    );
    final timeDiff = DateTime.now().difference(explanation.generatedAt);
    String timeAgo;
    if (timeDiff.inMinutes < 60) {
      timeAgo = '${timeDiff.inMinutes} minutes ago';
    } else if (timeDiff.inHours < 24) {
      timeAgo = '${timeDiff.inHours} hours ago';
    } else {
      timeAgo = '${timeDiff.inDays} days ago';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        borderRadius: MLTheme.borderRadiusLg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified, size: 14, color: confidenceColor),
          const SizedBox(width: 4),
          Text(
            'Model Confidence: ${(explanation.modelConfidence * 100).toStringAsFixed(0)}%',
            style: MLTheme.bodySmall.copyWith(
              color: confidenceColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
          Icon(
            Icons.schedule,
            size: 14,
            color: MLTheme.textSubtleColor(context),
          ),
          const SizedBox(width: 4),
          Text(
            'Last updated: $timeAgo',
            style: MLTheme.bodySmall.copyWith(
              color: MLTheme.textSubtleColor(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.psychology, color: MLTheme.trustBlue),
            SizedBox(width: 12),
            Text('About SHAP Explanations'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('What is SHAP?', style: MLTheme.titleSmall),
              SizedBox(height: 8),
              Text(
                'SHAP (SHapley Additive exPlanations) is a method to explain machine learning predictions by showing how each feature contributed to the final result.',
                style: MLTheme.bodyMedium,
              ),
              SizedBox(height: 16),
              Text('How to read this:', style: MLTheme.titleSmall),
              SizedBox(height: 8),
              Text(
                '• Green bars show factors that INCREASE the predicted weight gain\n'
                '• Red bars show factors that DECREASE the predicted weight gain\n'
                '• Longer bars = bigger impact on the prediction\n'
                '• The numbers show how much each factor changes the prediction (in kg)',
                style: MLTheme.bodyMedium,
              ),
              SizedBox(height: 16),
              Text('Why is this useful?', style: MLTheme.titleSmall),
              SizedBox(height: 8),
              Text(
                'Understanding what drives predictions helps you make better decisions about feeding, health care, and management of your animals.',
                style: MLTheme.bodyMedium,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

/// Global Model Insights Screen
///
/// Shows overall model feature importance across all predictions
class ModelInsightsScreen extends StatelessWidget {
  final List<FeatureImportance> featureImportances;
  final ModelMetrics? metrics;

  const ModelInsightsScreen({
    super.key,
    required this.featureImportances,
    this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MLTheme.backgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Model Insights',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: MLTheme.textPrimaryColor(context),
          ),
        ),
        backgroundColor: MLTheme.surfaceColor(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showInfoDialog(context),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intro card
            _buildIntroCard(context),
            const SizedBox(height: 24),

            // Feature importance chart
            FeatureImportanceChart(
              features: featureImportances,
              title: 'Feature Importance (SHAP Values)',
            ),
            const SizedBox(height: 24),

            // What this means
            _buildExplanationCards(context),
            const SizedBox(height: 24),

            // Model performance
            if (metrics != null) _buildModelPerformance(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? MLTheme.trustBlue.withValues(alpha: 0.15)
            : MLTheme.trustBlue.withValues(alpha: 0.05),
        borderRadius: MLTheme.borderRadiusLg,
        border: Border.all(color: MLTheme.trustBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What Drives Weight Predictions?',
            style: MLTheme.titleMedium.copyWith(
              color: MLTheme.textPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'These are the most important factors the AI considers when predicting animal weights.',
            style: MLTheme.bodyMedium.copyWith(
              color: MLTheme.textPrimaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationCards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What This Means For You',
          style: MLTheme.titleMedium.copyWith(
            color: MLTheme.textPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: MLTheme.dividerColor(context)),
        const SizedBox(height: 12),
        _buildInsightCard(
          context: context,
          icon: Icons.bar_chart,
          title: 'ACCURATE WEIGHTS MATTER MOST',
          description:
              'Current weight is by far the strongest predictor. Regular, accurate weight measurements improve prediction accuracy significantly.',
          tip: 'Tip: Weigh animals at least weekly',
        ),
        const SizedBox(height: 12),
        _buildInsightCard(
          context: context,
          icon: Icons.trending_up,
          title: 'GROWTH TRENDS INFORM PREDICTIONS',
          description:
              'The model looks at how weight has changed over the past 7 and 30 days to predict future growth. Consistent growth leads to more reliable predictions.',
          tip: null,
        ),
        const SizedBox(height: 12),
        _buildInsightCard(
          context: context,
          icon: Icons.vaccines,
          title: 'HEALTH IMPACTS GROWTH',
          description:
              'Vaccination status and health history have a smaller but meaningful impact on predictions. Keep health records up to date for best results.',
          tip: null,
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    String? tip,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MLTheme.cardDecorationFor(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: MLTheme.farmGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: MLTheme.labelMedium.copyWith(color: MLTheme.farmGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: MLTheme.bodyMedium.copyWith(
              height: 1.5,
              color: MLTheme.textPrimaryColor(context),
            ),
          ),
          if (tip != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? MLTheme.farmGreen.withValues(alpha: 0.15)
                    : MLTheme.farmGreen.withValues(alpha: 0.05),
                borderRadius: MLTheme.borderRadiusMd,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: MLTheme.farmGreen,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tip,
                    style: MLTheme.bodySmall.copyWith(
                      color: MLTheme.farmGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModelPerformance(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Model Performance',
          style: MLTheme.titleMedium.copyWith(
            color: MLTheme.textPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: MLTheme.cardDecorationFor(context),
          child: Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  value: metrics!.mae.toStringAsFixed(1),
                  label: 'kg error',
                  sublabel: '(MAE)',
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  value: '${(metrics!.mape * 100).toStringAsFixed(1)}%',
                  label: '% error',
                  sublabel: '(MAPE)',
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  value: '${(metrics!.r2 * 100).toStringAsFixed(0)}%',
                  label: 'accuracy',
                  sublabel: '(R²)',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required BuildContext context,
    required String value,
    required String label,
    required String sublabel,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            value,
            style: MLTheme.numberMedium.copyWith(
              color: MLTheme.textPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: MLTheme.bodySmall.copyWith(
              color: MLTheme.textSubtleColor(context),
            ),
          ),
          Text(
            sublabel,
            style: MLTheme.labelSmall.copyWith(
              color: MLTheme.textSubtleColor(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Model Insights'),
        content: const Text(
          'This screen shows what features the machine learning model considers most important when making predictions across all animals.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
