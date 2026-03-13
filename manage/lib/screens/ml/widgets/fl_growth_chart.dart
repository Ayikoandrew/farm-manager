import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../ml_theme.dart';
import '../../../models/ml_models.dart';

/// A beautiful line chart for displaying growth data using fl_chart
/// Enhanced with target progress, ADG badges, and breed comparison
class FlGrowthChart extends StatelessWidget {
  final List<GrowthDataPoint> dataPoints;
  final double? targetWeight;
  final double height;
  final bool showLabels;
  final bool showPredicted;
  final String? title;
  final GrowthStats? growthStats;
  final List<GrowthDataPoint>? breedAveragePoints;
  final double? currentWeight;
  final VoidCallback? onShapTap;

  const FlGrowthChart({
    super.key,
    required this.dataPoints,
    this.targetWeight,
    this.height = 220,
    this.showLabels = true,
    this.showPredicted = true,
    this.title,
    this.growthStats,
    this.breedAveragePoints,
    this.currentWeight,
    this.onShapTap,
  });

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return _buildEmptyState(context);
    }

    final actualPoints = dataPoints.where((p) => !p.isPredicted).toList();
    final predictedPoints = dataPoints.where((p) => p.isPredicted).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Row(
            children: [
              Icon(Icons.show_chart, size: 20, color: MLTheme.trustBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title!,
                  style: MLTheme.titleMedium.copyWith(
                    color: MLTheme.textPrimaryColor(context),
                  ),
                ),
              ),
              // ADG Badge
              if (growthStats != null) _buildAdgBadge(context),
            ],
          ),
          const SizedBox(height: 16),
        ],
        // Target progress bar
        if (targetWeight != null && currentWeight != null) ...[
          _buildTargetProgressBar(context),
          const SizedBox(height: 16),
        ],
        Container(
          height: height,
          padding: const EdgeInsets.only(right: 16, top: 8),
          child: LineChart(
            _buildChartData(context, actualPoints, predictedPoints),
            duration: const Duration(milliseconds: 300),
          ),
        ),
        if (showLabels) ...[const SizedBox(height: 12), _buildLegend(context)],
        // SHAP explanation button
        if (onShapTap != null) ...[
          const SizedBox(height: 12),
          _buildShapButton(context),
        ],
      ],
    );
  }

  LineChartData _buildChartData(
    BuildContext context,
    List<GrowthDataPoint> actualPoints,
    List<GrowthDataPoint> predictedPoints,
  ) {
    final allPoints = [...actualPoints, ...predictedPoints];
    if (allPoints.isEmpty) {
      return LineChartData();
    }

    // Calculate bounds
    final allWeights = allPoints.map((p) => p.weight).toList();
    if (targetWeight != null) allWeights.add(targetWeight!);

    final minWeight = (allWeights.reduce((a, b) => a < b ? a : b) * 0.9);
    final maxWeight = (allWeights.reduce((a, b) => a > b ? a : b) * 1.1);

    final minDate = allPoints
        .map((p) => p.date.millisecondsSinceEpoch.toDouble())
        .reduce((a, b) => a < b ? a : b);
    final maxDate = allPoints
        .map((p) => p.date.millisecondsSinceEpoch.toDouble())
        .reduce((a, b) => a > b ? a : b);

    // Build actual line spots
    final actualSpots = actualPoints.map((p) {
      return FlSpot(p.date.millisecondsSinceEpoch.toDouble(), p.weight);
    }).toList();

    // Build predicted line spots (connect to last actual point)
    List<FlSpot> predictedSpots = [];
    if (showPredicted && predictedPoints.isNotEmpty) {
      // Add last actual point to connect the lines
      if (actualPoints.isNotEmpty) {
        final lastActual = actualPoints.last;
        predictedSpots.add(
          FlSpot(
            lastActual.date.millisecondsSinceEpoch.toDouble(),
            lastActual.weight,
          ),
        );
      }
      // Add predicted points
      predictedSpots.addAll(
        predictedPoints.map((p) {
          return FlSpot(p.date.millisecondsSinceEpoch.toDouble(), p.weight);
        }),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridColor = isDark ? Colors.white12 : Colors.grey.shade200;
    final textColor = MLTheme.textSubtleColor(context);

    return LineChartData(
      minX: minDate,
      maxX: maxDate,
      minY: minWeight,
      maxY: maxWeight,
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: (maxWeight - minWeight) / 5,
        verticalInterval: (maxDate - minDate) / 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: gridColor, strokeWidth: 1);
        },
        getDrawingVerticalLine: (value) {
          return FlLine(color: gridColor, strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        show: showLabels,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: (maxDate - minDate) / 4,
            getTitlesWidget: (value, meta) {
              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  '${date.day}/${date.month}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            interval: (maxWeight - minWeight) / 5,
            getTitlesWidget: (value, meta) {
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  '${value.toInt()}kg',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: gridColor, width: 1),
          left: BorderSide(color: gridColor, width: 1),
        ),
      ),
      lineBarsData: [
        // Actual weight line
        if (actualSpots.isNotEmpty)
          LineChartBarData(
            spots: actualSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: MLTheme.trustBlue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: MLTheme.trustBlue,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  MLTheme.trustBlue.withValues(alpha: 0.2),
                  MLTheme.trustBlue.withValues(alpha: 0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        // Predicted weight line
        if (predictedSpots.isNotEmpty)
          LineChartBarData(
            spots: predictedSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: MLTheme.farmGreen,
            barWidth: 3,
            isStrokeCapRound: true,
            dashArray: [8, 4],
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: MLTheme.farmGreen,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  MLTheme.farmGreen.withValues(alpha: 0.15),
                  MLTheme.farmGreen.withValues(alpha: 0.02),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        // Breed average line (optional)
        if (breedAveragePoints != null && breedAveragePoints!.isNotEmpty)
          LineChartBarData(
            spots: breedAveragePoints!.map((p) {
              return FlSpot(p.date.millisecondsSinceEpoch.toDouble(), p.weight);
            }).toList(),
            isCurved: true,
            curveSmoothness: 0.3,
            color: Colors.purple.withValues(alpha: 0.7),
            barWidth: 2,
            isStrokeCapRound: true,
            dashArray: [4, 4],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
      ],
      extraLinesData: targetWeight != null
          ? ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: targetWeight!,
                  color: MLTheme.warningOrange,
                  strokeWidth: 2,
                  dashArray: [8, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    padding: const EdgeInsets.only(right: 8, bottom: 4),
                    style: TextStyle(
                      color: MLTheme.warningOrange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    labelResolver: (line) => 'Target: ${line.y.toInt()}kg',
                  ),
                ),
              ],
            )
          : null,
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) =>
              isDark ? Colors.grey.shade800 : Colors.white,
          tooltipBorder: BorderSide(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final date = DateTime.fromMillisecondsSinceEpoch(
                barSpot.x.toInt(),
              );
              final isPredicted = barSpot.barIndex == 1;
              return LineTooltipItem(
                '${date.day}/${date.month}\n',
                TextStyle(color: textColor, fontSize: 11),
                children: [
                  TextSpan(
                    text: '${barSpot.y.toStringAsFixed(1)}kg',
                    style: TextStyle(
                      color: isPredicted
                          ? MLTheme.farmGreen
                          : MLTheme.trustBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (isPredicted)
                    TextSpan(
                      text: ' (predicted)',
                      style: TextStyle(color: textColor, fontSize: 10),
                    ),
                ],
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: MLTheme.textSubtleColor(context).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'No weight data available',
              style: TextStyle(
                color: MLTheme.textSubtleColor(context),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _LegendItem(
          color: MLTheme.trustBlue,
          label: 'Actual',
          isDashed: false,
          context: context,
        ),
        if (showPredicted)
          _LegendItem(
            color: MLTheme.farmGreen,
            label: 'Predicted',
            isDashed: true,
            context: context,
          ),
        if (targetWeight != null)
          _LegendItem(
            color: MLTheme.warningOrange,
            label: 'Target',
            isDashed: true,
            context: context,
          ),
        if (breedAveragePoints != null && breedAveragePoints!.isNotEmpty)
          _LegendItem(
            color: Colors.purple,
            label: 'Breed Avg',
            isDashed: true,
            context: context,
          ),
      ],
    );
  }

  /// Builds the ADG (Average Daily Gain) badge
  Widget _buildAdgBadge(BuildContext context) {
    final adg = growthStats!.dailyGain7d;
    final trend = growthStats!.changePercent7d;
    final isGood = adg >= growthStats!.breedAverage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isGood
            ? MLTheme.successGreen.withValues(alpha: 0.1)
            : MLTheme.warningOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGood
              ? MLTheme.successGreen.withValues(alpha: 0.3)
              : MLTheme.warningOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGood ? Icons.trending_up : Icons.trending_flat,
            size: 14,
            color: isGood ? MLTheme.successGreen : MLTheme.warningOrange,
          ),
          const SizedBox(width: 4),
          Text(
            '${adg.toStringAsFixed(2)} kg/day',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isGood ? MLTheme.successGreen : MLTheme.warningOrange,
            ),
          ),
          if (trend != 0) ...[
            const SizedBox(width: 4),
            Text(
              '${trend >= 0 ? "+" : ""}${trend.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 10,
                color: trend >= 0 ? MLTheme.successGreen : MLTheme.dangerRed,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the target weight progress bar
  Widget _buildTargetProgressBar(BuildContext context) {
    final progress = (currentWeight! / targetWeight!).clamp(0.0, 1.0);
    final progressPercent = (progress * 100).toStringAsFixed(0);
    final remaining = targetWeight! - currentWeight!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.flag, size: 16, color: MLTheme.warningOrange),
                  const SizedBox(width: 6),
                  Text(
                    'Target: ${targetWeight!.toStringAsFixed(0)} kg',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: MLTheme.textPrimaryColor(context),
                    ),
                  ),
                ],
              ),
              Text(
                '$progressPercent%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: progress >= 1.0
                      ? MLTheme.successGreen
                      : MLTheme.trustBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                progress >= 1.0 ? MLTheme.successGreen : MLTheme.trustBlue,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            remaining > 0
                ? '${remaining.toStringAsFixed(1)} kg to go'
                : 'Target reached! 🎉',
            style: TextStyle(
              fontSize: 11,
              color: MLTheme.textSubtleColor(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the SHAP explanation button
  Widget _buildShapButton(BuildContext context) {
    return GestureDetector(
      onTap: onShapTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: MLTheme.trustBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: MLTheme.trustBlue.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.psychology, size: 18, color: MLTheme.trustBlue),
            const SizedBox(width: 8),
            Text(
              'Why this prediction?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: MLTheme.trustBlue,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios, size: 12, color: MLTheme.trustBlue),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDashed;
  final BuildContext context;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.isDashed,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: isDashed ? Colors.transparent : color,
            border: isDashed ? Border.all(color: color, width: 1.5) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: MLTheme.textSubtleColor(context),
          ),
        ),
      ],
    );
  }
}
