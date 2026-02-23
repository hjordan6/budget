import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import 'nutrition_form.dart';

class NutritionTrackerPage extends StatelessWidget {
  const NutritionTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<ExpenseProvider>().nutrition;
    final dateFormatter = DateFormat('MMM d, yyyy h:mm a');

    // Daily totals for today
    final today = DateTime.now();
    final todayEntries = entries.where(
      (e) =>
          e.date.year == today.year &&
          e.date.month == today.month &&
          e.date.day == today.day,
    );

    final totalCalories =
        todayEntries.fold<double>(0, (sum, e) => sum + e.calories);
    final totalCarbs =
        todayEntries.fold<double>(0, (sum, e) => sum + e.carbs);
    final totalFats = todayEntries.fold<double>(0, (sum, e) => sum + e.fats);
    final totalProtein =
        todayEntries.fold<double>(0, (sum, e) => sum + e.protein);
    final totalFiber =
        todayEntries.fold<double>(0, (sum, e) => sum + e.fiber);

    final children = <Widget>[
      // Today's summary card
      Card(
        margin: const EdgeInsets.all(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's Totals",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryChip(
                    label: 'Calories',
                    value: '${totalCalories.toStringAsFixed(0)} kcal',
                  ),
                  _SummaryChip(
                    label: 'Carbs',
                    value: '${totalCarbs.toStringAsFixed(1)}g',
                  ),
                  _SummaryChip(
                    label: 'Fats',
                    value: '${totalFats.toStringAsFixed(1)}g',
                  ),
                  _SummaryChip(
                    label: 'Protein',
                    value: '${totalProtein.toStringAsFixed(1)}g',
                  ),
                  _SummaryChip(
                    label: 'Fiber',
                    value: '${totalFiber.toStringAsFixed(1)}g',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Log Meal'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(140, 44)),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NutritionForm()),
          ),
        ),
      ),
    ];

    if (entries.isEmpty) {
      children.add(
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Text('No meals logged yet.'),
          ),
        ),
      );
    } else {
      children.addAll(
        entries.map((entry) {
          return Dismissible(
            key: Key(entry.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) {
              context.read<ExpenseProvider>().deleteNutritionEntry(entry);
            },
            child: ListTile(
              title: Text(entry.mealName),
              subtitle: Text(dateFormatter.format(entry.date)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.calories.toStringAsFixed(0)} kcal',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'C:${entry.carbs.toStringAsFixed(1)}g  '
                    'F:${entry.fats.toStringAsFixed(1)}g  '
                    'P:${entry.protein.toStringAsFixed(1)}g  '
                    'Fiber:${entry.fiber.toStringAsFixed(1)}g',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }),
      );
    }

    return ListView(children: children);
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

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

