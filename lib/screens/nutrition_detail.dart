import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/nutrition.dart';

class NutritionDetailPage extends StatelessWidget {
  const NutritionDetailPage({super.key, required this.entry});

  final NutritionEntry entry;

  Color _scoreColor(String score) {
    switch (score.toLowerCase()) {
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.amber;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('MMM d, yyyy h:mm a');

    return Scaffold(
      appBar: AppBar(title: Text(entry.mealName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            dateFormatter.format(entry.date),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Chip(label: 'Calories', value: '${entry.calories.toStringAsFixed(0)} kcal'),
                  _Chip(label: 'Carbs', value: '${entry.carbs.toStringAsFixed(1)}g'),
                  _Chip(label: 'Fats', value: '${entry.fats.toStringAsFixed(1)}g'),
                  _Chip(label: 'Protein', value: '${entry.protein.toStringAsFixed(1)}g'),
                  _Chip(label: 'Fiber', value: '${entry.fiber.toStringAsFixed(1)}g'),
                ],
              ),
            ),
          ),
          if (entry.score != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _scoreColor(entry.score!),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Score: ${entry.score![0].toUpperCase()}${entry.score!.substring(1)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: _scoreColor(entry.score!),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
          if (entry.breakdown != null) ...[
            const SizedBox(height: 16),
            Text(
              'AI Breakdown',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              entry.breakdown!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
