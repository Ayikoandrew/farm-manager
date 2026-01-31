import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../ml_theme.dart';

/// A circular gauge displaying health score (0-100)
class HealthScoreGauge extends StatelessWidget {
  final int score;
  final double size;
  final double strokeWidth;
  final String? label;
  final String? changeText;
  final bool? changePositive;

  const HealthScoreGauge({
    super.key,
    required this.score,
    this.size = 180,
    this.strokeWidth = 12,
    this.label,
    this.changeText,
    this.changePositive,
  });

  @override
  Widget build(BuildContext context) {
    final color = MLTheme.getHealthScoreColor(score);
    final statusLabel = _getStatusLabel();

    return SizedBox(
      width: size,
      height: size + 40,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background arc
                CustomPaint(
                  size: Size(size, size),
                  painter: _GaugeBackgroundPainter(strokeWidth: strokeWidth),
                ),
                // Progress arc
                CustomPaint(
                  size: Size(size, size),
                  painter: _GaugeProgressPainter(
                    progress: score / 100,
                    color: color,
                    strokeWidth: strokeWidth,
                  ),
                ),
                // Center content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      score.toString(),
                      style: MLTheme.numberLarge.copyWith(
                        color: color,
                        fontSize: size * 0.25,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: MLTheme.borderRadiusSm,
                      ),
                      child: Text(
                        statusLabel,
                        style: MLTheme.labelMedium.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (changeText != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  changePositive == true
                      ? Icons.arrow_upward
                      : changePositive == false
                      ? Icons.arrow_downward
                      : Icons.remove,
                  size: 14,
                  color: changePositive == true
                      ? MLTheme.successGreen
                      : changePositive == false
                      ? MLTheme.dangerRed
                      : MLTheme.textSubtle,
                ),
                const SizedBox(width: 4),
                Text(
                  changeText!,
                  style: MLTheme.bodySmall.copyWith(
                    color: changePositive == true
                        ? MLTheme.successGreen
                        : changePositive == false
                        ? MLTheme.dangerRed
                        : MLTheme.textSubtle,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getStatusLabel() {
    if (score >= 85) return 'EXCELLENT';
    if (score >= 70) return 'HEALTHY';
    if (score >= 50) return 'FAIR';
    if (score >= 30) return 'AT RISK';
    return 'CRITICAL';
  }
}

class _GaugeBackgroundPainter extends CustomPainter {
  final double strokeWidth;

  _GaugeBackgroundPainter({required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw arc from 135° to 405° (270° total)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75, // Start angle (135°)
      math.pi * 1.5, // Sweep angle (270°)
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GaugeProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _GaugeProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75, // Start angle (135°)
      math.pi * 1.5 * progress, // Sweep based on progress
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugeProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// A linear health score bar for compact displays
class HealthScoreBar extends StatelessWidget {
  final int score;
  final double height;
  final String? label;

  const HealthScoreBar({
    super.key,
    required this.score,
    this.height = 8,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final color = MLTheme.getHealthScoreColor(score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label!, style: MLTheme.bodySmall),
                Text(
                  '$score/100',
                  style: MLTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: MLTheme.borderRadiusSm,
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: height,
          ),
        ),
      ],
    );
  }
}

/// Risk indicator badge
class RiskBadge extends StatelessWidget {
  final String level;
  final bool showIcon;

  const RiskBadge({super.key, required this.level, this.showIcon = true});

  @override
  Widget build(BuildContext context) {
    final color = MLTheme.getRiskColor(level);
    IconData icon;

    switch (level.toLowerCase()) {
      case 'critical':
        icon = Icons.warning;
      case 'high':
        icon = Icons.error_outline;
      case 'moderate':
        icon = Icons.info_outline;
      default:
        icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: MLTheme.borderRadiusSm,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            level.toUpperCase(),
            style: MLTheme.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
