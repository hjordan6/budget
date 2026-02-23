import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_ai/firebase_ai.dart';
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
                ],
              ),
            ],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Log Meal'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(140, 44)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NutritionForm()),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Log Meal with AI'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(140, 44)),
              onPressed: () => _showAIMealSheet(context),
            ),
          ],
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
                    'P:${entry.protein.toStringAsFixed(1)}g',
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

void _showAIMealSheet(BuildContext context) {
  final controller = TextEditingController();
  bool isLoading = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          Future<void> submit() async {
            final query = controller.text.trim();
            if (query.isEmpty) return;
            setSheetState(() => isLoading = true);
            try {
              final model = FirebaseAI.googleAI().generativeModel(
                model: 'gemini-2.5-flash',
              );
              final prompt =
                  'You are a nutrition assistant. Given a meal description, respond ONLY with a JSON object in this exact format, with no extra text or markdown:\n'
                  '{"mealName": "...", "calories": 0, "carbs": 0, "fats": 0, "protein": 0}\n'
                  'All numeric values must be numbers (not strings). Meal: $query';
              final response = await model.generateContent([Content.text(prompt)]);
              final text = response.text ?? '';
              final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(text);
              if (jsonMatch == null) throw FormatException('No JSON in response');
              final data = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;

              if (ctx.mounted) {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NutritionForm(
                      initialMealName: data['mealName'] as String?,
                      initialCalories: (data['calories'] as num?)?.toDouble(),
                      initialCarbs: (data['carbs'] as num?)?.toDouble(),
                      initialFats: (data['fats'] as num?)?.toDouble(),
                      initialProtein: (data['protein'] as num?)?.toDouble(),
                    ),
                  ),
                );
              }
            } catch (e) {
              setSheetState(() => isLoading = false);
              if (ctx.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('AI error: could not parse meal. Try again or log manually.')),
                );
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NutritionForm()),
                );
              }
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Describe your meal',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'e.g. chicken sandwich with fries and a coke',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => submit(),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 16),
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton.icon(
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Generate with AI'),
                        onPressed: submit,
                      ),
              ],
            ),
          );
        },
      );
    },
  );
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

