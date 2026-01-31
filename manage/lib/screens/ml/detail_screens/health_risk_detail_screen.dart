import 'package:flutter/material.dart';
import '../ml_theme.dart';
import '../../../models/ml_models.dart';

/// Health Risk Detail Screen
///
/// Shows detailed health information for an at-risk animal:
/// - Health score with visual gauge
/// - Risk factors with impact points
/// - Possible causes and recommendations
/// - Action buttons (schedule vet, give vaccine, etc.)
class HealthRiskDetailScreen extends StatelessWidget {
  final AnimalHealthScore healthScore;

  const HealthRiskDetailScreen({super.key, required this.healthScore});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MLTheme.backgroundColor(context),
      appBar: AppBar(
        title: Text(
          '${healthScore.animalTagId} "${healthScore.animalName}" - Health Risk',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: MLTheme.textPrimaryColor(context),
          ),
        ),
        backgroundColor: MLTheme.surfaceColor(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Health score card
            _buildHealthScoreCard(context),
            const SizedBox(height: 24),

            // Risk factors
            _buildRiskFactorsSection(context),
            const SizedBox(height: 24),

            // Recommended actions
            _buildRecommendedActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthScoreCard(BuildContext context) {
    final statusColor = _getRiskColor();
    final statusLabel = _getStatusLabel();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: MLTheme.elevatedCardDecorationFor(context),
      child: Column(
        children: [
          Text(
            'Health Score',
            style: MLTheme.labelMedium.copyWith(
              color: MLTheme.textSubtleColor(context),
            ),
          ),
          const SizedBox(height: 16),
          // Score display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: MLTheme.borderRadiusLg,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      healthScore.healthScore.toString(),
                      style: MLTheme.numberLarge.copyWith(
                        fontSize: 48,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ 100',
                      style: MLTheme.bodyMedium.copyWith(
                        color: MLTheme.textSubtleColor(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ClipRRect(
                    borderRadius: MLTheme.borderRadiusSm,
                    child: LinearProgressIndicator(
                      value: healthScore.healthScore / 100,
                      backgroundColor: isDark
                          ? Colors.white12
                          : Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(statusColor),
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: MLTheme.borderRadiusSm,
                  ),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskFactorsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Risk Factors',
          style: MLTheme.titleMedium.copyWith(
            color: MLTheme.textPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: MLTheme.dividerColor(context)),
        const SizedBox(height: 12),
        ...healthScore.riskFactors.map(
          (factor) => _buildRiskFactorCard(context, factor),
        ),
        // Add a positive factor for demonstration
        _buildPositiveFactorCard(context),
      ],
    );
  }

  Widget _buildRiskFactorCard(BuildContext context, HealthRiskFactor factor) {
    final color = _getSeverityColor(factor.severity);
    final icon = _getSeverityIcon(factor.severity);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MLTheme.surfaceColor(context),
        borderRadius: MLTheme.borderRadiusLg,
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: isDark ? null : MLTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  factor.name.toUpperCase(),
                  style: MLTheme.labelMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: MLTheme.borderRadiusSm,
                ),
                child: Text(
                  '${factor.pointsImpact} pts',
                  style: MLTheme.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            factor.description,
            style: MLTheme.bodyMedium.copyWith(
              color: MLTheme.textPrimaryColor(context),
            ),
          ),

          // Possible causes
          if (factor.possibleCauses != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade50,
                borderRadius: MLTheme.borderRadiusMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 14,
                        color: MLTheme.textSubtleColor(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Possible causes:',
                        style: MLTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: MLTheme.textPrimaryColor(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    factor.possibleCauses!,
                    style: MLTheme.bodySmall.copyWith(
                      color: MLTheme.textSubtleColor(context),
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

  Widget _buildPositiveFactorCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MLTheme.surfaceColor(context),
        borderRadius: MLTheme.borderRadiusLg,
        border: Border.all(color: MLTheme.successGreen.withValues(alpha: 0.3)),
        boxShadow: isDark ? null : MLTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: MLTheme.successGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'RECENT CHECKUP',
                  style: MLTheme.labelMedium.copyWith(
                    color: MLTheme.successGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MLTheme.successGreen.withValues(alpha: 0.1),
                  borderRadius: MLTheme.borderRadiusSm,
                ),
                child: Text(
                  '+10 pts',
                  style: MLTheme.labelSmall.copyWith(
                    color: MLTheme.successGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Health checkup performed 3 days ago',
            style: MLTheme.bodyMedium.copyWith(
              color: MLTheme.textPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No issues noted',
            style: MLTheme.bodySmall.copyWith(
              color: MLTheme.textSubtleColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended Actions',
          style: MLTheme.titleMedium.copyWith(
            color: MLTheme.textPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: MLTheme.dividerColor(context)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.medical_services,
                label: 'Schedule Vet\nVisit',
                color: MLTheme.trustBlue,
                onTap: () => _scheduleVetVisit(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.vaccines,
                label: 'Give\nVaccine',
                color: MLTheme.successGreen,
                onTap: () => _giveVaccine(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.edit_note,
                label: 'Log\nTreatment',
                color: MLTheme.warningOrange,
                onTap: () => _logTreatment(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.monitor_weight,
                label: 'Record\nWeight',
                color: MLTheme.farmGreen,
                onTap: () => _recordWeight(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: MLTheme.borderRadiusLg,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: MLTheme.surfaceColor(context),
            borderRadius: MLTheme.borderRadiusLg,
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade200,
            ),
            boxShadow: isDark ? null : MLTheme.shadowSm,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: MLTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: MLTheme.textPrimaryColor(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRiskColor() {
    switch (healthScore.riskLevel) {
      case RiskLevel.critical:
        return const Color(0xFFB71C1C);
      case RiskLevel.high:
        return MLTheme.dangerRed;
      case RiskLevel.moderate:
        return MLTheme.warningOrange;
      default:
        return MLTheme.successGreen;
    }
  }

  String _getStatusLabel() {
    switch (healthScore.riskLevel) {
      case RiskLevel.critical:
        return 'CRITICAL';
      case RiskLevel.high:
        return 'AT RISK';
      case RiskLevel.moderate:
        return 'NEEDS ATTENTION';
      default:
        return 'HEALTHY';
    }
  }

  Color _getSeverityColor(RiskLevel severity) {
    switch (severity) {
      case RiskLevel.critical:
        return const Color(0xFFB71C1C);
      case RiskLevel.high:
        return MLTheme.dangerRed;
      case RiskLevel.moderate:
        return MLTheme.warningOrange;
      default:
        return MLTheme.textSubtle;
    }
  }

  IconData _getSeverityIcon(RiskLevel severity) {
    switch (severity) {
      case RiskLevel.critical:
      case RiskLevel.high:
        return Icons.error;
      case RiskLevel.moderate:
        return Icons.warning;
      default:
        return Icons.info_outline;
    }
  }

  void _scheduleVetVisit(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Schedule Vet Visit - Coming soon')),
    );
  }

  void _giveVaccine(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Give Vaccine - Coming soon')));
  }

  void _logTreatment(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log Treatment - Coming soon')),
    );
  }

  void _recordWeight(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Record Weight - Coming soon')),
    );
  }
}
