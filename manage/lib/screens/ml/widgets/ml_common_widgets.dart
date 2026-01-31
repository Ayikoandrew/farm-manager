import 'package:flutter/material.dart';
import '../ml_theme.dart';

/// Forecast horizon selector with toggle buttons
class ForecastHorizonSelector extends StatelessWidget {
  final int selectedDays;
  final ValueChanged<int> onChanged;
  final List<int> options;

  const ForecastHorizonSelector({
    super.key,
    required this.selectedDays,
    required this.onChanged,
    this.options = const [7, 14, 30],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Forecast Horizon', style: MLTheme.labelMedium),
        const SizedBox(height: 8),
        Row(
          children: options.map((days) {
            final isSelected = days == selectedDays;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => onChanged(days),
                child: AnimatedContainer(
                  duration: MLTheme.animationFast,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? MLTheme.farmGreen : MLTheme.surface,
                    borderRadius: MLTheme.borderRadiusMd,
                    border: Border.all(
                      color: isSelected
                          ? MLTheme.farmGreen
                          : Colors.grey.shade300,
                    ),
                    boxShadow: isSelected ? MLTheme.shadowSm : null,
                  ),
                  child: Text(
                    '$days Days',
                    style: MLTheme.titleSmall.copyWith(
                      color: isSelected ? Colors.white : MLTheme.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Time period selector dropdown
class TimePeriodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final List<String> options;

  const TimePeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.options = const [
      'This Week',
      'This Month',
      'Last 30 Days',
      'Last 90 Days',
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: MLTheme.surface,
        borderRadius: MLTheme.borderRadiusMd,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option, style: MLTheme.bodyMedium),
            );
          }).toList(),
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          style: MLTheme.bodyMedium,
          isDense: true,
        ),
      ),
    );
  }
}

/// AI Insight card with dismissable functionality
class AIInsightCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onLearnMore;
  final VoidCallback? onDismiss;
  final IconData? icon;

  const AIInsightCard({
    super.key,
    required this.title,
    required this.description,
    this.onLearnMore,
    this.onDismiss,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MLTheme.farmGreen.withValues(alpha: 0.08),
            MLTheme.trustBlue.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: MLTheme.borderRadiusLg,
        border: Border.all(color: MLTheme.farmGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MLTheme.farmGreen.withValues(alpha: 0.15),
                  borderRadius: MLTheme.borderRadiusMd,
                ),
                child: Icon(
                  icon ?? Icons.lightbulb_outline,
                  color: MLTheme.farmGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI INSIGHTS',
                  style: MLTheme.labelMedium.copyWith(color: MLTheme.farmGreen),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: MLTheme.textSubtle,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"$description"',
            style: MLTheme.bodyMedium.copyWith(
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (onLearnMore != null)
                OutlinedButton(
                  onPressed: onLearnMore,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MLTheme.farmGreen,
                    side: const BorderSide(color: MLTheme.farmGreen),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Learn More'),
                ),
              if (onDismiss != null) ...[
                const SizedBox(width: 12),
                TextButton(onPressed: onDismiss, child: const Text('Dismiss')),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Quick action button grid
class QuickActionsGrid extends StatelessWidget {
  final List<QuickAction> actions;

  const QuickActionsGrid({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: actions.map((action) {
        return _QuickActionButton(action: action);
      }).toList(),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final QuickAction action;

  const _QuickActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: MLTheme.surface,
          borderRadius: MLTheme.borderRadiusLg,
          boxShadow: MLTheme.shadowSm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, color: action.color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: MLTheme.labelSmall.copyWith(color: MLTheme.textPrimary),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick action data model
class QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const QuickAction({
    required this.label,
    required this.icon,
    this.color = MLTheme.farmGreen,
    this.onTap,
  });
}

/// Section header with optional action button
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: MLTheme.textSubtle),
          const SizedBox(width: 8),
        ],
        Expanded(child: Text(title, style: MLTheme.titleMedium)),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(actionLabel!),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios, size: 12),
              ],
            ),
          ),
      ],
    );
  }
}

/// Empty state placeholder
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              title,
              style: MLTheme.titleMedium.copyWith(color: MLTheme.textSubtle),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: MLTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading shimmer placeholder
class ShimmerPlaceholder extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerPlaceholder({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.grey.shade200,
              ],
            ),
          ),
        );
      },
    );
  }
}
