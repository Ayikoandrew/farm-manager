import 'package:flutter/material.dart';

class QuickActions extends StatelessWidget {
  final VoidCallback? onAddAnimal;
  final VoidCallback? onRecordFeed;
  final VoidCallback? onRecordWeight;
  final VoidCallback? onBreeding;
  final VoidCallback? onMLAnalytics;

  const QuickActions({
    super.key,
    this.onAddAnimal,
    this.onRecordFeed,
    this.onRecordWeight,
    this.onBreeding,
    this.onMLAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _ActionItem(
            label: 'Add Animal',
            icon: Icons.add,
            color: Colors.blue,
            onTap: onAddAnimal,
          ),
          _ActionItem(
            label: 'Feed',
            icon: Icons.restaurant,
            color: Colors.orange,
            onTap: onRecordFeed,
          ),
          _ActionItem(
            label: 'Weigh',
            icon: Icons.monitor_weight,
            color: Colors.teal,
            onTap: onRecordWeight,
          ),
          _ActionItem(
            label: 'Breed',
            icon: Icons.favorite,
            color: Colors.pink,
            onTap: onBreeding,
          ),
          _ActionItem(
            label: 'AI Insights',
            icon: Icons.auto_graph,
            color: Colors.purple,
            onTap: onMLAnalytics,
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionItem({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
