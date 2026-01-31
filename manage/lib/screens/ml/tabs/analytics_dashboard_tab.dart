import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme.dart';
import '../../../models/ml_models.dart';
import '../../../providers/ml_analytics_provider.dart';

class AnalyticsDashboardTab extends ConsumerStatefulWidget {
  const AnalyticsDashboardTab({super.key});

  @override
  ConsumerState<AnalyticsDashboardTab> createState() =>
      _AnalyticsDashboardTabState();
}

class _AnalyticsDashboardTabState extends ConsumerState<AnalyticsDashboardTab> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mlState = ref.watch(mlAnalyticsProvider);
    final herdSummary = mlState.weightSummary;
    final healthSummary = mlState.healthSummary;
    final insights = mlState.insights;
    final error = mlState.error;

    if (mlState.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.farmGreen),
      );
    }

    if (error != null && !mlState.hasData) {
      return Center(child: Text('Error: $error'));
    }

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(mlAnalyticsProvider),
      color: AppTheme.farmGreen,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),

          if (herdSummary != null && healthSummary != null)
            _buildSummaryRow(herdSummary, healthSummary, theme, isDark),
          const SizedBox(height: 24),

          Text(
            'AI Insights',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          _buildInsightsList(insights, theme, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.farmGreen.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Farm Intelligence',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real-time analytics & predictions',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    HerdWeightSummary weightSummary,
    HerdHealthSummary healthSummary,
    ThemeData theme,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Daily Gain',
            '${weightSummary.avgDailyGain.toStringAsFixed(2)} kg',
            Icons.trending_up,
            Colors.blue,
            'Target: ${weightSummary.targetDailyGain} kg',
            theme,
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Health Score',
            '${healthSummary.overallScore}%',
            Icons.favorite,
            AppTheme.farmGreen,
            '${healthSummary.atRiskCount} at risk',
            theme,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: theme.textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsList(
    List<AIInsight> insights,
    ThemeData theme,
    bool isDark,
  ) {
    if (insights.isEmpty) {
      return Center(
        child: Text(
          'No insights available yet.',
          style: GoogleFonts.inter(color: Colors.grey),
        ),
      );
    }
    return Column(
      children: insights
          .map((insight) => _buildInsightCard(insight, theme, isDark))
          .toList(),
    );
  }

  Widget _buildInsightCard(AIInsight insight, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? theme.dividerColor : Colors.grey.shade100,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
