import 'package:flutter/material.dart';

/// Design constants for ML Analytics screens
/// Based on UI_DESIGN.md specifications
///
/// Use the context-aware methods for colors that should adapt to theme:
/// - MLTheme.backgroundColor(context)
/// - MLTheme.surfaceColor(context)
/// - MLTheme.textPrimaryColor(context)
/// - MLTheme.textSubtleColor(context)
class MLTheme {
  // ==========================================================================
  // PRIMARY COLORS (Brand colors - don't change with theme)
  // ==========================================================================

  /// Farm Green - Primary brand color
  static const Color farmGreen = Color(0xFF2E7D32);

  /// Trust Blue - Secondary brand color
  static const Color trustBlue = Color(0xFF1565C0);

  /// Healthy Green - Success indicators
  static const Color successGreen = Color(0xFF43A047);

  /// Attention Orange - Warning indicators
  static const Color warningOrange = Color(0xFFFB8C00);

  /// Alert Red - Danger/critical indicators
  static const Color dangerRed = Color(0xFFE53935);

  // ==========================================================================
  // THEME-AWARE COLORS (Use methods for these)
  // ==========================================================================

  /// Background color - adapts to light/dark theme
  static Color backgroundColor(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  /// Surface color - adapts to light/dark theme
  static Color surfaceColor(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  /// Card color - adapts to light/dark theme
  static Color cardColor(BuildContext context) => Theme.of(context).cardColor;

  /// Primary text color - adapts to light/dark theme
  static Color textPrimaryColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  /// Subtle/secondary text color - adapts to light/dark theme
  static Color textSubtleColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

  /// Disabled text color - adapts to light/dark theme
  static Color textDisabledColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38);

  /// Divider color - adapts to light/dark theme
  static Color dividerColor(BuildContext context) =>
      Theme.of(context).dividerColor;

  // ==========================================================================
  // LEGACY STATIC COLORS (Keep for backwards compatibility, prefer context versions)
  // ==========================================================================

  /// Clean White - Background (DEPRECATED: use backgroundColor(context))
  static const Color background = Color(0xFFFAFAFA);

  /// Card White - Surface (DEPRECATED: use surfaceColor(context))
  static const Color surface = Color(0xFFFFFFFF);

  /// Dark Gray - Primary text (DEPRECATED: use textPrimaryColor(context))
  static const Color textPrimary = Color(0xFF212121);

  /// Medium Gray - Subtle/secondary text (DEPRECATED: use textSubtleColor(context))
  static const Color textSubtle = Color(0xFF757575);

  /// Light Gray - Disabled/placeholder (DEPRECATED: use textDisabledColor(context))
  static const Color textDisabled = Color(0xFFBDBDBD);

  // ==========================================================================
  // CHART COLORS
  // ==========================================================================

  /// Actual data line color
  static const Color chartActual = trustBlue;

  /// Predicted data line color
  static const Color chartPredicted = farmGreen;

  /// Confidence band color
  static const Color chartConfidence = Color(0x332E7D32);

  /// Breed average line color
  static const Color chartBreedAverage = Color(0xFF9E9E9E);

  // ==========================================================================
  // RISK LEVEL COLORS
  // ==========================================================================

  static Color getRiskColor(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return successGreen;
      case 'moderate':
        return warningOrange;
      case 'high':
        return dangerRed;
      case 'critical':
        return const Color(0xFFB71C1C);
      default:
        return textSubtle;
    }
  }

  // ==========================================================================
  // HEALTH SCORE COLORS
  // ==========================================================================

  static Color getHealthScoreColor(int score) {
    if (score >= 80) return successGreen;
    if (score >= 60) return const Color(0xFF8BC34A);
    if (score >= 40) return warningOrange;
    return dangerRed;
  }

  // ==========================================================================
  // CONFIDENCE COLORS
  // ==========================================================================

  static Color getConfidenceColor(double confidence) {
    if (confidence >= 0.85) return successGreen;
    if (confidence >= 0.70) return warningOrange;
    return dangerRed;
  }

  // ==========================================================================
  // SHAP COLORS
  // ==========================================================================

  /// Positive SHAP contribution (increasing prediction)
  static const Color shapPositive = successGreen;

  /// Negative SHAP contribution (decreasing prediction)
  static const Color shapNegative = dangerRed;

  // ==========================================================================
  // TYPOGRAPHY
  // ==========================================================================

  /// Headline style (Poppins SemiBold alternative using system font)
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.25,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  /// Title style
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  /// Body text style (Inter Regular alternative)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSubtle,
  );

  /// Number/stat style (tabular figures)
  static const TextStyle numberLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle numberMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle numberSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Label style (uppercase with letter spacing)
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSubtle,
    letterSpacing: 1.2,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSubtle,
    letterSpacing: 1.0,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: textSubtle,
    letterSpacing: 0.8,
  );

  // ==========================================================================
  // SPACING
  // ==========================================================================

  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // ==========================================================================
  // BORDER RADIUS
  // ==========================================================================

  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusRound = 999.0;

  static BorderRadius get borderRadiusSm => BorderRadius.circular(radiusSm);
  static BorderRadius get borderRadiusMd => BorderRadius.circular(radiusMd);
  static BorderRadius get borderRadiusLg => BorderRadius.circular(radiusLg);
  static BorderRadius get borderRadiusXl => BorderRadius.circular(radiusXl);

  // ==========================================================================
  // SHADOWS
  // ==========================================================================

  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // ==========================================================================
  // CARD DECORATION
  // ==========================================================================

  /// Card decoration - adapts to light/dark theme
  static BoxDecoration cardDecorationFor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: cardColor(context),
      borderRadius: borderRadiusLg,
      boxShadow: isDark ? [] : shadowSm,
    );
  }

  /// Elevated card decoration - adapts to light/dark theme
  static BoxDecoration elevatedCardDecorationFor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: cardColor(context),
      borderRadius: borderRadiusLg,
      boxShadow: isDark ? [] : shadowMd,
      border: isDark ? Border.all(color: Colors.grey.shade800) : null,
    );
  }

  /// DEPRECATED: Use cardDecorationFor(context) instead
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surface,
    borderRadius: borderRadiusLg,
    boxShadow: shadowSm,
  );

  /// DEPRECATED: Use elevatedCardDecorationFor(context) instead
  static BoxDecoration get elevatedCardDecoration => BoxDecoration(
    color: surface,
    borderRadius: borderRadiusLg,
    boxShadow: shadowMd,
  );

  // ==========================================================================
  // ICON SIZES
  // ==========================================================================

  static const double iconSizeSm = 16.0;
  static const double iconSizeMd = 24.0;
  static const double iconSizeLg = 32.0;
  static const double iconSizeXl = 48.0;

  // ==========================================================================
  // ANIMATION DURATIONS
  // ==========================================================================

  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // ==========================================================================
  // HELPER METHODS
  // ==========================================================================

  /// Get icon for animal type
  static IconData getAnimalIcon(String animalType) {
    switch (animalType.toLowerCase()) {
      case 'cattle':
      case 'cow':
        return Icons.pets;
      case 'pig':
        return Icons.pets;
      case 'goat':
        return Icons.pets;
      case 'sheep':
        return Icons.pets;
      case 'poultry':
      case 'chicken':
        return Icons.flutter_dash;
      default:
        return Icons.pets;
    }
  }

  /// Get emoji for animal type
  static String getAnimalEmoji(String animalType) {
    switch (animalType.toLowerCase()) {
      case 'cattle':
      case 'cow':
        return '🐄';
      case 'pig':
        return '🐷';
      case 'goat':
        return '🐐';
      case 'sheep':
        return '🐑';
      case 'poultry':
      case 'chicken':
        return '🐔';
      case 'rabbit':
        return '🐰';
      default:
        return '🐾';
    }
  }
}

/// Extension for convenient color manipulations
extension ColorExtension on Color {
  Color withOpacityValue(double opacity) => withValues(alpha: opacity);

  Color lighten([double amount = 0.1]) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color darken([double amount = 0.1]) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}
