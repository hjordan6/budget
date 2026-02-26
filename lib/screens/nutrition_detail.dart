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
              child: Wrap(
                alignment: WrapAlignment.spaceAround,
                spacing: 12,
                runSpacing: 8,
                children: [
                  _Chip(label: 'Calories', value: '${entry.calories.toStringAsFixed(0)} kcal'),
                  _Chip(label: 'Carbs', value: '${entry.carbs.toStringAsFixed(1)}g'),
                  _Chip(label: 'Fats', value: '${entry.fats.toStringAsFixed(1)}g'),
                  _Chip(label: 'Protein', value: '${entry.protein.toStringAsFixed(1)}g'),
                  _Chip(label: 'Fiber', value: '${entry.fiber.toStringAsFixed(1)}g'),
                  if (entry.netCarbs != null)
                    _Chip(label: 'Net Carbs', value: '${entry.netCarbs!.toStringAsFixed(1)}g'),
                  if (entry.addedSugar != null)
                    _Chip(label: 'Added Sugar', value: '${entry.addedSugar!.toStringAsFixed(1)}g'),
                  if (entry.sodium != null)
                    _Chip(label: 'Sodium', value: '${entry.sodium!.toStringAsFixed(0)}mg'),
                  if (entry.volumePoints != null)
                    _Chip(label: 'Volume Pts', value: entry.volumePoints!.toStringAsFixed(1)),
                ],
              ),
            ),
          ),
          if (entry.fiberLight != null || entry.sugarLight != null || entry.fatLight != null) ...[
            const SizedBox(height: 16),
            Text('Traffic Lights', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                if (entry.fiberLight != null)
                  _TrafficLight(label: 'Fiber', score: entry.fiberLight!),
                if (entry.sugarLight != null) ...[
                  const SizedBox(width: 16),
                  _TrafficLight(label: 'Sugar', score: entry.sugarLight!),
                ],
                if (entry.fatLight != null) ...[
                  const SizedBox(width: 16),
                  _TrafficLight(label: 'Fat', score: entry.fatLight!),
                ],
              ],
            ),
          ],
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
          if (entry.counterBalanceTip != null) ...[
            const SizedBox(height: 16),
            Text(
              'Counter-Balance Tip',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              entry.counterBalanceTip!,
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

class _TrafficLight extends StatelessWidget {
  const _TrafficLight({required this.label, required this.score});

  final String label;
  final String score;

  Color _color() {
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: _color(), shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
