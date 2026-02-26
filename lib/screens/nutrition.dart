import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:image_picker/image_picker.dart';
import '../log.dart';
import '../providers/expense_provider.dart';
import 'nutrition_form.dart';
import 'nutrition_detail.dart';

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

    final totalCalories = todayEntries.fold<double>(
      0,
      (sum, e) => sum + e.calories,
    );
    final totalCarbs = todayEntries.fold<double>(0, (sum, e) => sum + e.carbs);
    final totalFats = todayEntries.fold<double>(0, (sum, e) => sum + e.fats);
    final totalProtein = todayEntries.fold<double>(
      0,
      (sum, e) => sum + e.protein,
    );
    final totalFiber = todayEntries.fold<double>(0, (sum, e) => sum + e.fiber);

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
            ElevatedButton.icon(
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Log Meal with AI'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(140, 44)),
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
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NutritionDetailPage(entry: entry),
                ),
              ),
              title: Row(
                children: [
                  Expanded(child: Text(entry.mealName)),
                  if (entry.score != null)
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(left: 6),
                      decoration: BoxDecoration(
                        color: _scoreColor(entry.score!),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
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

void _showAIMealSheet(BuildContext context) {
  final controller = TextEditingController();
  bool isLoading = false;
  XFile? pickedImage;
  Uint8List? pickedImageBytes;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          Future<void> pickImage(ImageSource source) async {
            try {
              final picker = ImagePicker();
              final image = await picker.pickImage(
                source: source,
                imageQuality: 85,
              );
              if (image != null) {
                final bytes = await image.readAsBytes();
                setSheetState(() {
                  pickedImage = image;
                  pickedImageBytes = bytes;
                });
              }
            } catch (e) {
              Logger.error(
                'Error picking image',
                data: {'source': source.toString(), 'error': e.toString()},
              );
            }
          }

          Future<void> submit() async {
            final query = controller.text.trim();
            if (query.isEmpty && pickedImage == null) return;
            setSheetState(() => isLoading = true);
            try {
              final model = FirebaseAI.googleAI().generativeModel(
                model: 'gemini-2.5-flash',
              );
              String nutritionSystemPrompt = '''
              You are a professional nutritional analyst and personal health assistant. 
              Your goal is to analyze food images or text descriptions and return a structured JSON response based on the "Balanced Life Tracking System."

              ### THE SCORING SYSTEM:
              1. Volume (Points): 1-10 (1 = Snack, 5 = Standard Meal, 8+ = Large/Heavy Restaurant Meal).
              2. Fiber Score: Green (High > 8g), Yellow (Med 4-8g), Red (Low < 4g).
              3. Sugar Score: Green (Low < 5g), Yellow (Med 5-15g), Red (High > 15g).
              4. Fat Quality Score: Green (Plant/Healthy), Yellow (Moderate/Animal), Red (High Saturated/Processed).
              5. Overall Score: Green, Yellow, Orange, or Red based on net nutrient density.

              ### CONSTRAINTS:
              - Estimate portion sizes based on visual cues (plates, hands, utensils) or text descriptions.
              - Use current (2026) nutritional data for known chains (e.g., Dave's Hot Chicken, Cafe Rio).
              - ALWAYS return only a valid JSON object. Do not include markdown formatting like ```json ... ``` in the response.
              - In summary explain the reasoning behind scores and totals including where the calories and protien come from. Format in paragraphs.
              - In counter balance give tips on improving this meal in the future, as well as suggestion for future meals that day or the next morning.

              ### OUTPUT JSON SCHEMA:
              {
                "meal_name": "string",
                "volume_points": number,
                "overall_score": "Green/Yellow/Orange/Red",
                "nutrients_numeric": {
                  "calories": number,
                  "protein_g": number,
                  "total_carbs_g": number,
                  "net_carbs_g": number,
                  "fiber_g": number,
                  "fat_g": number,
                  "added_sugar_g": number,
                  "sodium_mg": number
                },
                "quality_ratings": {
                  "fiber_light": "Green/Yellow/Red",
                  "sugar_light": "Green/Yellow/Red",
                  "fat_light": "Green/Yellow/Red"
                },
                "summary": "string",
                "counter_balance_tip": "string"
              }
              ''';

              final List<Part> parts = [];
              if (pickedImage != null && pickedImageBytes != null) {
                final mimeType = pickedImage!.mimeType ?? 'image/jpeg';
                parts.add(InlineDataPart(mimeType, pickedImageBytes!));
              }
              parts.add(
                TextPart(
                  query.isNotEmpty
                      ? '$nutritionSystemPrompt\nMeal: $query'
                      : nutritionSystemPrompt,
                ),
              );

              final response = await model.generateContent([
                Content.multi(parts),
              ]);
              final text = response.text ?? '';
              // Extract the outermost JSON object from the response
              final jsonStart = text.indexOf('{');
              final jsonEnd = text.lastIndexOf('}');
              if (jsonStart == -1 || jsonEnd == -1) {
                throw FormatException('No JSON in response');
              }
              final data =
                  jsonDecode(text.substring(jsonStart, jsonEnd + 1))
                      as Map<String, dynamic>;

              if (ctx.mounted) {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NutritionForm(
                      initialMealName: data['meal_name'] as String?,
                      initialCalories:
                          (data['nutrients_numeric']?['calories'] as num?)
                              ?.toDouble(),
                      initialCarbs:
                          (data['nutrients_numeric']?['total_carbs_g'] as num?)
                              ?.toDouble(),
                      initialFats: (data['nutrients_numeric']?['fat_g'] as num?)
                          ?.toDouble(),
                      initialProtein:
                          (data['nutrients_numeric']?['protein_g'] as num?)
                              ?.toDouble(),
                      initialFiber:
                          (data['nutrients_numeric']?['fiber_g'] as num?)
                              ?.toDouble(),
                      initialScore: data['overall_score'] as String?,
                      initialBreakdown: data['summary'] as String?,
                      initialVolumePoints: (data['volume_points'] as num?)
                          ?.toDouble(),
                      initialNetCarbs:
                          (data['nutrients_numeric']?['net_carbs_g'] as num?)
                              ?.toDouble(),
                      initialAddedSugar:
                          (data['nutrients_numeric']?['added_sugar_g'] as num?)
                              ?.toDouble(),
                      initialSodium:
                          (data['nutrients_numeric']?['sodium_mg'] as num?)
                              ?.toDouble(),
                      initialFiberLight:
                          data['quality_ratings']?['fiber_light'] as String?,
                      initialSugarLight:
                          data['quality_ratings']?['sugar_light'] as String?,
                      initialFatLight:
                          data['quality_ratings']?['fat_light'] as String?,
                      initialCounterBalanceTip:
                          data['counter_balance_tip'] as String?,
                    ),
                  ),
                );
              }
            } catch (e) {
              setSheetState(() => isLoading = false);
              if (ctx.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'AI error: could not parse meal. Try again or log manually.',
                    ),
                  ),
                );
                print(e);
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
                  decoration: const InputDecoration(
                    hintText: 'e.g. chicken sandwich with fries and a coke',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => submit(),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 12),
                if (pickedImage != null)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          pickedImageBytes!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                        ),
                        onPressed: () => setSheetState(() {
                          pickedImage = null;
                          pickedImageBytes = null;
                        }),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                          onPressed: () => pickImage(ImageSource.gallery),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                          onPressed: () => pickImage(ImageSource.camera),
                        ),
                      ),
                    ],
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
