import 'package:flutter/material.dart';

class GenUiAnimalCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const GenUiAnimalCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Ideally, we would deserialize this into an Animal object, but for display
    // purposes, we can just read the map.
    // The AI might return partial data.

    final name = data['name'] as String?;
    final tagId = data['tagId'] as String? ?? 'Unknown Tag';
    final species = data['species'] as String? ?? 'Unknown';
    final status = data['status'] as String? ?? 'Unknown';
    final breed = data['breed'] as String?;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Text(species.characters.first.toUpperCase()),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? tagId,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (name != null)
                      Text(tagId, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const Spacer(),
                Chip(
                  label: Text(status),
                  backgroundColor: _getStatusColor(
                    status,
                  ).withValues(alpha: 0.2),
                  labelStyle: TextStyle(color: _getStatusColor(status)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (breed != null)
              Text(
                "Breed: $breed",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
        return Colors.green;
      case 'sick':
        return Colors.red;
      case 'pregnant':
        return Colors.purple;
      case 'sold':
        return Colors.blue;
      case 'deceased':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }
}
