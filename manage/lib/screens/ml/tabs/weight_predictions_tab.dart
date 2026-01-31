import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/theme.dart';
import '../../../models/ml_models.dart';
import '../widgets/widgets.dart';

class WeightPredictionsTab extends StatefulWidget {
  const WeightPredictionsTab({super.key});

  @override
  State<WeightPredictionsTab> createState() => _WeightPredictionsTabState();
}

class _WeightPredictionsTabState extends State<WeightPredictionsTab> {
  int _forecastDays = 14;
  final List<WeightPrediction> _predictions = [];
  final List<GrowthDataPoint> _chartData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    // Mock Data (matches original logic)
    final now = DateTime.now();
    _predictions.addAll([
      WeightPrediction(
        animalId: '1',
        animalTagId: 'Pig-001',
        animalName: 'Babe',
        currentWeight: 92,
        predictedWeight: 105,
        predictedGain: 13,
        horizonDays: 14,
        predictionDate: now,
        confidenceScore: 0.93,
        lowerBound: 102,
        upperBound: 108,
        targetWeight: 100,
        daysToTarget: 7,
      ),
      WeightPrediction(
        animalId: '2',
        animalTagId: 'Pig-003',
        animalName: 'Wilbur',
        currentWeight: 88,
        predictedWeight: 101,
        predictedGain: 13,
        horizonDays: 14,
        predictionDate: now,
        confidenceScore: 0.88,
        lowerBound: 98,
        upperBound: 104,
        targetWeight: 100,
        daysToTarget: 12,
      ),
      WeightPrediction(
        animalId: '3',
        animalTagId: 'Pig-007',
        animalName: 'Arnold',
        currentWeight: 85,
        predictedWeight: 98,
        predictedGain: 13,
        horizonDays: 14,
        predictionDate: now,
        confidenceScore: 0.85,
        lowerBound: 95,
        upperBound: 101,
        targetWeight: 100,
        daysToTarget: 18,
      ),
    ]);

    // Mock chart data
    for (int i = 30; i >= 0; i--) {
      _chartData.add(
        GrowthDataPoint(
          date: now.subtract(Duration(days: i)),
          weight: 60 + (30 - i) * 1.1 + (i % 3) * 0.5,
          isPredicted: false,
        ),
      );
    }
    for (int i = 1; i <= 14; i++) {
      _chartData.add(
        GrowthDataPoint(
          date: now.add(Duration(days: i)),
          weight: 92 + i * 0.9,
          isPredicted: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHorizonSelector(theme, isDark),
        const SizedBox(height: 24),
        _buildChartSection(theme, isDark),
        const SizedBox(height: 24),
        Text(
          'Individual Predictions',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 12),
        ..._predictions.map((p) => _buildPredictionCard(p, theme, isDark)),
      ],
    );
  }

  Widget _buildHorizonSelector(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [7, 14, 30].map((days) {
          final isSelected = _forecastDays == days;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _forecastDays = days),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? theme.colorScheme.surface : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  '$days Days',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppTheme.farmGreen
                        : theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChartSection(ThemeData theme, bool isDark) {
    return Container(
      height: 300,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Growth Trajectory',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: theme.textTheme.titleMedium?.color,
                ),
              ),
              Row(
                children: [
                  _legendItem('Actual', Colors.blue, theme),
                  const SizedBox(width: 12),
                  _legendItem('Predicted', AppTheme.farmGreen, theme),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: GrowthChart(dataPoints: _chartData)),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
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

  Widget _buildPredictionCard(
    WeightPrediction p,
    ThemeData theme,
    bool isDark,
  ) {
    final name = p.animalName ?? 'Unknown';
    final initial = name.isNotEmpty ? name[0] : '?';

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
          CircleAvatar(
            backgroundColor: AppTheme.farmGreen.withValues(alpha: 0.1),
            child: Text(
              initial,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: AppTheme.farmGreen,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                Text(
                  'Tag: ${p.animalTagId}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${p.predictedWeight.toStringAsFixed(1)} kg',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.textTheme.titleMedium?.color,
                ),
              ),
              Text(
                '+${p.predictedGain.toStringAsFixed(1)} kg',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
