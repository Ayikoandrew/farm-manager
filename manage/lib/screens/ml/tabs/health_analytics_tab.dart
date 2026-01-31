import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme.dart';
import '../../../models/ml_models.dart';
import '../../../providers/ml_analytics_provider.dart';

class HealthAnalyticsTab extends ConsumerWidget {
  const HealthAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mlState = ref.watch(mlAnalyticsProvider);

    if (mlState.isLoading && !mlState.hasData) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.farmGreen),
      );
    }

    final healthSummary = mlState.healthSummary;
    final atRiskAnimals = mlState.atRiskAnimals; // List<AnimalHealthScore>

    if (healthSummary == null) {
      return const Center(child: Text('No health data available'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHealthScoreCard(healthSummary, theme, isDark),
        const SizedBox(height: 24),
        Text(
          'Animals At Risk',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 12),
        if (atRiskAnimals.isNotEmpty)
          ...atRiskAnimals.map(
            (score) => _buildAtRiskCard(score, theme, isDark),
          )
        else
          _buildEmptyState(theme),
        const SizedBox(height: 24),
        Text(
          'Recommended Actions',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          'Vaccination Schedule',
          '3 animals due for vaccination in next 5 days',
          Icons.medical_services,
          Colors.blue,
          theme,
          isDark,
        ),
        _buildActionCard(
          'Dietary Adjustment',
          'Consider increasing protein for group B',
          Icons.restaurant,
          Colors.orange,
          theme,
          isDark,
        ),
      ],
    );
  }

  Widget _buildHealthScoreCard(
    HerdHealthSummary summary,
    ThemeData theme,
    bool isDark,
  ) {
    final score = summary.overallScore; // Corrected property
    Color scoreColor = score > 90
        ? Colors.green
        : (score > 70 ? Colors.orange : Colors.red);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.farmGreen.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Overall Herd Health',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: theme.textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: score / 100,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                  color: scoreColor,
                  strokeWidth: 12,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score%', // score is int
                    style: GoogleFonts.poppins(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  Text(
                    score > 90 ? 'Excellent' : 'Attention',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: scoreColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStat(
                summary.healthyCount.toString(),
                'Healthy',
                Colors.green,
                theme,
              ),
              Container(
                height: 30,
                width: 1,
                color: theme.dividerColor,
                margin: const EdgeInsets.symmetric(horizontal: 24),
              ),
              _buildStat(
                summary.atRiskCount.toString(),
                'Risk',
                Colors.red,
                theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, Color color, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildAtRiskCard(
    AnimalHealthScore score,
    ThemeData theme,
    bool isDark,
  ) {
    final isHighRisk =
        score.riskLevel == RiskLevel.high ||
        score.riskLevel == RiskLevel.critical;
    final color = isHighRisk ? Colors.red : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.warning_amber_rounded, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  score.animalName ?? score.animalTagId,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                Text(
                  'Risk: ${score.riskLevel.displayName}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
                if (score.riskFactors.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      score.riskFactors.first.description,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    ThemeData theme,
    bool isDark,
  ) {
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
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
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

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green),
          const SizedBox(width: 12),
          Text(
            'No animals currently at risk',
            style: GoogleFonts.inter(
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
