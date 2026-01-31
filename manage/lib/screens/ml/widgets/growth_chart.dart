import 'package:flutter/material.dart';
import '../ml_theme.dart';
import '../../../models/ml_models.dart';

/// A simple line chart for displaying growth data
/// Uses CustomPaint for a lightweight implementation without external packages
class GrowthChart extends StatelessWidget {
  final List<GrowthDataPoint> dataPoints;
  final double? targetWeight;
  final double height;
  final bool showLabels;
  final bool showPredicted;
  final String? title;

  const GrowthChart({
    super.key,
    required this.dataPoints,
    this.targetWeight,
    this.height = 200,
    this.showLabels = true,
    this.showPredicted = true,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return _buildEmptyState();
    }

    final actualPoints = dataPoints.where((p) => !p.isPredicted).toList();
    final predictedPoints = dataPoints.where((p) => p.isPredicted).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Row(
            children: [
              const Icon(Icons.show_chart, size: 20, color: MLTheme.trustBlue),
              const SizedBox(width: 8),
              Text(title!, style: MLTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          height: height,
          child: CustomPaint(
            size: Size.infinite,
            painter: _GrowthChartPainter(
              actualPoints: actualPoints,
              predictedPoints: showPredicted ? predictedPoints : [],
              targetWeight: targetWeight,
              showLabels: showLabels,
            ),
          ),
        ),
        if (showLabels) ...[const SizedBox(height: 12), _buildLegend()],
      ],
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              'No weight data available',
              style: MLTheme.bodyMedium.copyWith(color: MLTheme.textSubtle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _LegendItem(color: MLTheme.trustBlue, label: 'Actual', isDashed: false),
        if (showPredicted)
          _LegendItem(
            color: MLTheme.farmGreen,
            label: 'Predicted',
            isDashed: true,
          ),
        if (targetWeight != null)
          _LegendItem(
            color: MLTheme.warningOrange,
            label: 'Target',
            isDashed: true,
          ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDashed;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.isDashed,
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
        Text(label, style: MLTheme.bodySmall),
      ],
    );
  }
}

class _GrowthChartPainter extends CustomPainter {
  final List<GrowthDataPoint> actualPoints;
  final List<GrowthDataPoint> predictedPoints;
  final double? targetWeight;
  final bool showLabels;

  _GrowthChartPainter({
    required this.actualPoints,
    required this.predictedPoints,
    this.targetWeight,
    required this.showLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (actualPoints.isEmpty && predictedPoints.isEmpty) return;

    final allPoints = [...actualPoints, ...predictedPoints];
    final allWeights = allPoints.map((p) => p.weight).toList();
    if (targetWeight != null) allWeights.add(targetWeight!);

    final minWeight = allWeights.reduce((a, b) => a < b ? a : b) * 0.9;
    final maxWeight = allWeights.reduce((a, b) => a > b ? a : b) * 1.1;
    final weightRange = maxWeight - minWeight;

    final minDate = allPoints
        .map((p) => p.date.millisecondsSinceEpoch)
        .reduce((a, b) => a < b ? a : b)
        .toDouble();
    final maxDate = allPoints
        .map((p) => p.date.millisecondsSinceEpoch)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final dateRange = maxDate - minDate;

    final padding = showLabels ? 40.0 : 20.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    // Draw grid
    _drawGrid(
      canvas,
      size,
      padding,
      chartWidth,
      chartHeight,
      minWeight,
      weightRange,
    );

    // Draw target line
    if (targetWeight != null) {
      _drawTargetLine(
        canvas,
        size,
        padding,
        chartWidth,
        chartHeight,
        targetWeight!,
        minWeight,
        weightRange,
      );
    }

    // Draw actual line
    if (actualPoints.isNotEmpty) {
      _drawLine(
        canvas,
        actualPoints,
        MLTheme.trustBlue,
        false,
        padding,
        chartWidth,
        chartHeight,
        minWeight,
        weightRange,
        minDate,
        dateRange,
      );
    }

    // Draw predicted line
    if (predictedPoints.isNotEmpty && actualPoints.isNotEmpty) {
      // Connect last actual to first predicted
      final lastActual = actualPoints.last;
      final allPredicted = [lastActual, ...predictedPoints];
      _drawLine(
        canvas,
        allPredicted,
        MLTheme.farmGreen,
        true,
        padding,
        chartWidth,
        chartHeight,
        minWeight,
        weightRange,
        minDate,
        dateRange,
      );
    }

    // Draw Y-axis labels
    if (showLabels) {
      _drawYAxisLabels(
        canvas,
        size,
        padding,
        chartHeight,
        minWeight,
        maxWeight,
      );
    }
  }

  void _drawGrid(
    Canvas canvas,
    Size size,
    double padding,
    double chartWidth,
    double chartHeight,
    double minWeight,
    double weightRange,
  ) {
    final paint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;

    // Horizontal lines
    for (var i = 0; i <= 4; i++) {
      final y = padding + chartHeight * (1 - i / 4);
      canvas.drawLine(
        Offset(padding, y),
        Offset(padding + chartWidth, y),
        paint,
      );
    }
  }

  void _drawTargetLine(
    Canvas canvas,
    Size size,
    double padding,
    double chartWidth,
    double chartHeight,
    double target,
    double minWeight,
    double weightRange,
  ) {
    final y = padding + chartHeight * (1 - (target - minWeight) / weightRange);

    final paint = Paint()
      ..color = MLTheme.warningOrange
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Dashed line
    const dashWidth = 8.0;
    const dashSpace = 4.0;
    var startX = padding;

    while (startX < padding + chartWidth) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
      startX += dashWidth + dashSpace;
    }
  }

  void _drawLine(
    Canvas canvas,
    List<GrowthDataPoint> points,
    Color color,
    bool isDashed,
    double padding,
    double chartWidth,
    double chartHeight,
    double minWeight,
    double weightRange,
    double minDate,
    double dateRange,
  ) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final x =
          padding +
          chartWidth *
              ((point.date.millisecondsSinceEpoch - minDate) / dateRange);
      final y =
          padding +
          chartHeight * (1 - (point.weight - minWeight) / weightRange);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    if (isDashed) {
      // Draw dashed path
      final pathMetrics = path.computeMetrics();
      for (final metric in pathMetrics) {
        var distance = 0.0;
        while (distance < metric.length) {
          final extractPath = metric.extractPath(distance, distance + 8);
          canvas.drawPath(extractPath, paint);
          distance += 12;
        }
      }
    } else {
      canvas.drawPath(path, paint);
    }

    // Draw points
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final point in points) {
      final x =
          padding +
          chartWidth *
              ((point.date.millisecondsSinceEpoch - minDate) / dateRange);
      final y =
          padding +
          chartHeight * (1 - (point.weight - minWeight) / weightRange);
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
  }

  void _drawYAxisLabels(
    Canvas canvas,
    Size size,
    double padding,
    double chartHeight,
    double minWeight,
    double maxWeight,
  ) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i <= 4; i++) {
      final weight = minWeight + (maxWeight - minWeight) * i / 4;
      final y = padding + chartHeight * (1 - i / 4);

      textPainter.text = TextSpan(
        text: '${weight.toStringAsFixed(0)}kg',
        style: MLTheme.labelSmall,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(padding - textPainter.width - 8, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GrowthChartPainter oldDelegate) {
    return oldDelegate.actualPoints != actualPoints ||
        oldDelegate.predictedPoints != predictedPoints ||
        oldDelegate.targetWeight != targetWeight;
  }
}

/// A mini sparkline chart for compact displays
class MiniGrowthChart extends StatelessWidget {
  final List<double> weights;
  final double width;
  final double height;
  final Color? color;

  const MiniGrowthChart({
    super.key,
    required this.weights,
    this.width = 80,
    this.height = 30,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (weights.isEmpty) {
      return SizedBox(width: width, height: height);
    }

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(
          weights: weights,
          color: color ?? MLTheme.farmGreen,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> weights;
  final Color color;

  _SparklinePainter({required this.weights, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (weights.isEmpty) return;

    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final range = maxWeight - minWeight;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    for (var i = 0; i < weights.length; i++) {
      final x = size.width * i / (weights.length - 1);
      final y = range > 0
          ? size.height * (1 - (weights[i] - minWeight) / range)
          : size.height / 2;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.weights != weights || oldDelegate.color != color;
  }
}
