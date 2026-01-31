import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../ml_theme.dart';
import '../../../models/ml_models.dart';

/// A beautiful line chart for displaying growth data using fl_chart
/// Replaces the CustomPaint-based GrowthChart for better visuals
class FlGrowthChart extends StatelessWidget {
  final List<GrowthDataPoint> dataPoints;
  final double? targetWeight;
  final double height;
  final bool showLabels;
  final bool showPredicted;
  final String? title;

  const FlGrowthChart({
    super.key,
    required this.dataPoints,
    this.targetWeight,
    this.height = 220,
    this.showLabels = true,
    this.showPredicted = true,
    this.title,
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
              Text(
                title!,
                style: MLTheme.titleMedium.copyWith(
                  color: MLTheme.textPrimaryColor(context),
                ),
              ),
            ],
          ),
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
      ],
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
