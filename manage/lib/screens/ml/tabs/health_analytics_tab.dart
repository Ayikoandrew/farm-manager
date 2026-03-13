import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme.dart';
import '../../../models/ml_models.dart';
import '../../../models/health_record.dart';
import '../../../providers/ml_analytics_provider.dart';
import '../../../providers/providers.dart';

/// A dynamic recommended action based on real data
class RecommendedAction {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final ActionPriority priority;

  const RecommendedAction({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.priority,
  });
}

enum ActionPriority { urgent, high, medium, low }

class HealthAnalyticsTab extends ConsumerWidget {
  const HealthAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mlState = ref.watch(mlAnalyticsProvider);

    // Watch real data for dynamic recommendations
    final upcomingVaccinations = ref.watch(upcomingVaccinationsProvider);
    final pendingFollowUps = ref.watch(pendingFollowUpsProvider);
    final animalsInWithdrawal = ref.watch(animalsInWithdrawalProvider);

    if (mlState.isLoading && !mlState.hasData) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.farmGreen),
      );
    }

    final healthSummary = mlState.healthSummary;
    final atRiskAnimals = mlState.atRiskAnimals;
    final predictions = mlState.predictions;

    if (healthSummary == null) {
      return const Center(child: Text('No health data available'));
    }

    // Generate dynamic recommendations
    final recommendations = _generateRecommendations(
      healthSummary: healthSummary,
      atRiskAnimals: atRiskAnimals,
      predictions: predictions,
      upcomingVaccinations: upcomingVaccinations.value ?? [],
      pendingFollowUps: pendingFollowUps.value ?? [],
      animalsInWithdrawal: animalsInWithdrawal.value ?? [],
    );

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
        if (recommendations.isNotEmpty)
          ...recommendations.map(
            (action) => _buildActionCard(
              action.title,
              action.description,
              action.icon,
              action.color,
              theme,
              isDark,
            ),
          )
        else
          _buildNoActionsState(theme),
      ],
    );
  }

  /// Generate dynamic recommendations based on actual data
  List<RecommendedAction> _generateRecommendations({
    required HerdHealthSummary healthSummary,
    required List<AnimalHealthScore> atRiskAnimals,
    required List<WeightPrediction> predictions,
    required List<HealthRecord> upcomingVaccinations,
    required List<HealthRecord> pendingFollowUps,
    required List<HealthRecord> animalsInWithdrawal,
  }) {
    final recommendations = <RecommendedAction>[];

    // 1. Upcoming vaccinations
    if (upcomingVaccinations.isNotEmpty) {
      final dueIn5Days = upcomingVaccinations.where((v) {
        final daysUntilDue =
            v.nextDueDate?.difference(DateTime.now()).inDays ?? 999;
        return daysUntilDue <= 5;
      }).toList();

      if (dueIn5Days.isNotEmpty) {
        recommendations.add(
          RecommendedAction(
            title: 'Vaccination Due',
            description:
                '${dueIn5Days.length} animal${dueIn5Days.length > 1 ? 's' : ''} due for vaccination in the next 5 days',
            icon: Icons.medical_services,
            color: Colors.blue,
            priority: ActionPriority.high,
          ),
        );
      } else {
        recommendations.add(
          RecommendedAction(
            title: 'Upcoming Vaccinations',
            description:
                '${upcomingVaccinations.length} vaccination${upcomingVaccinations.length > 1 ? 's' : ''} scheduled',
            icon: Icons.medical_services,
            color: Colors.blue,
            priority: ActionPriority.medium,
          ),
        );
      }
    }

    // 2. Pending follow-ups
    if (pendingFollowUps.isNotEmpty) {
      final overdue = pendingFollowUps.where((f) {
        return f.followUpDate?.isBefore(DateTime.now()) ?? false;
      }).toList();

      if (overdue.isNotEmpty) {
        recommendations.add(
          RecommendedAction(
            title: 'Overdue Follow-ups',
            description:
                '${overdue.length} follow-up${overdue.length > 1 ? 's' : ''} overdue - schedule vet visit',
            icon: Icons.event_busy,
            color: Colors.red,
            priority: ActionPriority.urgent,
          ),
        );
      } else {
        recommendations.add(
          RecommendedAction(
            title: 'Pending Follow-ups',
            description:
                '${pendingFollowUps.length} health check${pendingFollowUps.length > 1 ? 's' : ''} pending',
            icon: Icons.event_note,
            color: Colors.orange,
            priority: ActionPriority.medium,
          ),
        );
      }
    }

    // 3. Animals in withdrawal period
    if (animalsInWithdrawal.isNotEmpty) {
      recommendations.add(
        RecommendedAction(
          title: 'Withdrawal Period Active',
          description:
              '${animalsInWithdrawal.length} animal${animalsInWithdrawal.length > 1 ? 's' : ''} in medication withdrawal - not for sale',
          icon: Icons.do_not_disturb_alt,
          color: Colors.purple,
          priority: ActionPriority.high,
        ),
      );
    }

    // 4. At-risk animals dietary recommendations
    if (atRiskAnimals.isNotEmpty) {
      // Check if any risk factors mention weight or nutrition
      final nutritionRelated = atRiskAnimals
          .where(
            (a) => a.riskFactors.any(
              (f) =>
                  f.name.toLowerCase().contains('weight') ||
                  f.name.toLowerCase().contains('feed') ||
                  f.name.toLowerCase().contains('nutrition') ||
                  f.description.toLowerCase().contains('underweight'),
            ),
          )
          .toList();

      if (nutritionRelated.isNotEmpty) {
        recommendations.add(
          RecommendedAction(
            title: 'Dietary Review Needed',
            description:
                '${nutritionRelated.length} animal${nutritionRelated.length > 1 ? 's' : ''} may need feed adjustment based on health scores',
            icon: Icons.restaurant,
            color: Colors.orange,
            priority: ActionPriority.medium,
          ),
        );
      }

      // Check for critical risk animals
      final criticalAnimals = atRiskAnimals
          .where((a) => a.riskLevel == RiskLevel.critical)
          .toList();

      if (criticalAnimals.isNotEmpty) {
        recommendations.add(
          RecommendedAction(
            title: 'Critical Attention Required',
            description:
                '${criticalAnimals.length} animal${criticalAnimals.length > 1 ? 's' : ''} in critical condition - immediate action needed',
            icon: Icons.warning_amber,
            color: Colors.red,
            priority: ActionPriority.urgent,
          ),
        );
      }
    }

    // 5. Underweight animals from predictions
    final underweightAnimals = predictions.where((p) {
      if (p.targetWeight == null) return false;
      return p.currentWeight <
          (p.targetWeight! * 0.7); // Less than 70% of target
    }).toList();

    if (underweightAnimals.isNotEmpty) {
      recommendations.add(
        RecommendedAction(
          title: 'Weight Management',
          description:
              '${underweightAnimals.length} animal${underweightAnimals.length > 1 ? 's' : ''} significantly below target weight',
          icon: Icons.monitor_weight,
          color: Colors.teal,
          priority: ActionPriority.medium,
        ),
      );
    }

    // 6. Upcoming health tasks from summary
    final urgentTasks = healthSummary.upcomingTasks.where((t) {
      return t.isOverdue || t.isDueToday;
    }).toList();

    for (final task in urgentTasks.take(2)) {
      // Limit to 2
      recommendations.add(
        RecommendedAction(
          title: task.title,
          description: task.isOverdue
              ? 'Overdue: ${task.description}'
              : 'Due today: ${task.animalCount} animal${task.animalCount > 1 ? 's' : ''}',
          icon: _getTaskIcon(task.type),
          color: task.isOverdue ? Colors.red : Colors.amber,
          priority: task.isOverdue
              ? ActionPriority.urgent
              : ActionPriority.high,
        ),
      );
    }

    // 7. General herd health recommendation
    if (healthSummary.overallScore < 70 && recommendations.length < 5) {
      recommendations.add(
        RecommendedAction(
          title: 'Herd Health Review',
          description:
              'Overall herd health score is ${healthSummary.overallScore}% - consider veterinary consultation',
          icon: Icons.health_and_safety,
          color: Colors.indigo,
          priority: ActionPriority.medium,
        ),
      );
    }

    // Sort by priority
    recommendations.sort(
      (a, b) => a.priority.index.compareTo(b.priority.index),
    );

    // Return top 5 recommendations
    return recommendations.take(5).toList();
  }

  IconData _getTaskIcon(String taskType) {
    switch (taskType.toLowerCase()) {
      case 'vaccination':
        return Icons.vaccines;
      case 'checkup':
        return Icons.fact_check;
      case 'treatment':
        return Icons.medical_services;
      case 'deworming':
        return Icons.bug_report;
      default:
        return Icons.assignment;
    }
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

  Widget _buildNoActionsState(ThemeData theme) {
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
          const Icon(Icons.thumb_up_outlined, color: Colors.green),
          const SizedBox(width: 12),
          Text(
            'All caught up! No actions needed',
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
