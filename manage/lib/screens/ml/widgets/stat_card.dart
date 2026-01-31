import 'package:flutter/material.dart';
import '../ml_theme.dart';

/// A stat card displaying a single metric with optional icon and trend
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData? icon;
  final Color? iconColor;
  final String? trend;
  final bool? trendPositive;
  final VoidCallback? onTap;
  final bool compact;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.icon,
    this.iconColor,
    this.trend,
    this.trendPositive,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(
          compact ? MLTheme.spacingMd : MLTheme.spacingLg,
        ),
        decoration: MLTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (iconColor ?? MLTheme.farmGreen).withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: MLTheme.borderRadiusMd,
                    ),
                    child: Icon(
                      icon,
                      size: compact ? 18 : 24,
                      color: iconColor ?? MLTheme.farmGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: MLTheme.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? MLTheme.spacingSm : MLTheme.spacingMd),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: compact ? MLTheme.numberSmall : MLTheme.numberMedium,
                ),
                if (unit != null) ...[
                  const SizedBox(width: 4),
                  Text(unit!, style: MLTheme.bodySmall),
                ],
              ],
            ),
            if (trend != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    trendPositive == true
                        ? Icons.trending_up
                        : trendPositive == false
                        ? Icons.trending_down
                        : Icons.trending_flat,
                    size: 16,
                    color: trendPositive == true
                        ? MLTheme.successGreen
                        : trendPositive == false
                        ? MLTheme.dangerRed
                        : MLTheme.textSubtle,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    trend!,
                    style: MLTheme.bodySmall.copyWith(
                      color: trendPositive == true
                          ? MLTheme.successGreen
                          : trendPositive == false
                          ? MLTheme.dangerRed
                          : MLTheme.textSubtle,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A row of compact stats for displaying multiple metrics inline
class StatRow extends StatelessWidget {
  final List<StatItem> stats;

  const StatRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: stats.map((stat) {
        final index = stats.indexOf(stat);
        return Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MLTheme.surface,
              borderRadius: BorderRadius.horizontal(
                left: index == 0 ? const Radius.circular(12) : Radius.zero,
                right: index == stats.length - 1
                    ? const Radius.circular(12)
                    : Radius.zero,
              ),
              border: Border(
                right: index < stats.length - 1
                    ? BorderSide(color: Colors.grey.shade200)
                    : BorderSide.none,
              ),
            ),
            child: Column(
              children: [
                Text(
                  stat.value,
                  style: MLTheme.numberSmall.copyWith(
                    color: stat.color ?? MLTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat.label,
                  style: MLTheme.labelSmall,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// A single stat item for use in StatRow
class StatItem {
  final String label;
  final String value;
  final Color? color;

  const StatItem({required this.label, required this.value, this.color});
}
