import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/nutrition.dart';
import '../providers/expense_provider.dart';

class NutritionHistoryPage extends StatelessWidget {
  const NutritionHistoryPage({super.key});

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // Returns the Sunday that starts the calendar week containing [date].
  DateTime _weekStart(DateTime date) {
    final d = _dateOnly(date);
    return d.subtract(Duration(days: d.weekday % 7));
  }

  Map<String, double> _totals(Iterable<NutritionEntry> entries) {
    double calories = 0, carbs = 0, fats = 0, protein = 0;
    for (final e in entries) {
      calories += e.calories;
      carbs += e.carbs;
      fats += e.fats;
      protein += e.protein;
    }
    return {
      'calories': calories,
      'carbs': carbs,
      'fats': fats,
      'protein': protein,
    };
  }

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<ExpenseProvider>().nutrition;
    final today = _dateOnly(DateTime.now());

    // Rolling 7-day averages
    final sevenDaysAgo = today.subtract(const Duration(days: 6));
    final rolling7 = _totals(
      entries.where((e) {
        final d = _dateOnly(e.date);
        return !d.isBefore(sevenDaysAgo) && !d.isAfter(today);
      }),
    );
    final rolling7Avg = rolling7.map((k, v) => MapEntry(k, v / 7));

    // Last 7 individual days, most recent first (today = index 0)
    final last7Days = List.generate(7, (i) => today.subtract(Duration(days: i)));

    // Last 20 calendar weeks (Sunday–Saturday), most recent first
    final currentWeekStart = _weekStart(today);
    final last20Weeks = List.generate(
      20,
      (i) => currentWeekStart.subtract(Duration(days: 7 * i)),
    );

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _SectionHeader(title: 'Rolling 7-Day Averages'),
        _NutritionSummaryCard(
          title: 'Past 7 Days (Daily Avg)',
          calories: rolling7Avg['calories']!,
          carbs: rolling7Avg['carbs']!,
          fats: rolling7Avg['fats']!,
          protein: rolling7Avg['protein']!,
        ),
        const SizedBox(height: 16),
        _SectionHeader(title: 'Last 7 Days'),
        ...last7Days.map((day) {
          final dayTotals = _totals(
            entries.where((e) => _dateOnly(e.date) == day),
          );
          return _NutritionSummaryCard(
            title: DateFormat('EEE, MMM d').format(day),
            calories: dayTotals['calories']!,
            carbs: dayTotals['carbs']!,
            fats: dayTotals['fats']!,
            protein: dayTotals['protein']!,
          );
        }),
        const SizedBox(height: 16),
        _SectionHeader(title: 'Last 20 Weeks (Daily Avg, Sun–Sat)'),
        ...last20Weeks.map((weekStart) {
          final weekEnd = weekStart.add(const Duration(days: 6));
          final weekTotals = _totals(
            entries.where((e) {
              final d = _dateOnly(e.date);
              return !d.isBefore(weekStart) && !d.isAfter(weekEnd);
            }),
          );
          final weekAvg = weekTotals.map((k, v) => MapEntry(k, v / 7));
          final label =
              '${DateFormat('MMM d').format(weekStart)} – ${DateFormat('MMM d').format(weekEnd)}';
          return _NutritionSummaryCard(
            title: label,
            calories: weekAvg['calories']!,
            carbs: weekAvg['carbs']!,
            fats: weekAvg['fats']!,
            protein: weekAvg['protein']!,
          );
        }),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _NutritionSummaryCard extends StatelessWidget {
  const _NutritionSummaryCard({
    required this.title,
    required this.calories,
    required this.carbs,
    required this.fats,
    required this.protein,
  });

  final String title;
  final double calories;
  final double carbs;
  final double fats;
  final double protein;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Chip(label: 'Calories', value: '${calories.toStringAsFixed(0)} kcal'),
                _Chip(label: 'Carbs', value: '${carbs.toStringAsFixed(1)}g'),
                _Chip(label: 'Fats', value: '${fats.toStringAsFixed(1)}g'),
                _Chip(label: 'Protein', value: '${protein.toStringAsFixed(1)}g'),
              ],
            ),
          ],
        ),
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
