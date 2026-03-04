import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../models/nutrition.dart';
import '../providers/expense_provider.dart';
import 'nutrition_ai_prompt.dart';

class NutritionForm extends StatefulWidget {
  const NutritionForm({
    super.key,
    this.initialMealName,
    this.initialCalories,
    this.initialCarbs,
    this.initialFats,
    this.initialProtein,
    this.initialFiber,
    this.initialScore,
    this.initialBreakdown,
    this.initialVolumePoints,
    this.initialNetCarbs,
    this.initialAddedSugar,
    this.initialSodium,
    this.initialFiberLight,
    this.initialSugarLight,
    this.initialFatLight,
    this.initialCounterBalanceTip,
    this.originalQuery,
    this.originalImageBytes,
    this.originalImageMimeType,
    this.originalAiResponseJson,
  });

  final String? initialMealName;
  final double? initialCalories;
  final double? initialCarbs;
  final double? initialFats;
  final double? initialProtein;
  final double? initialFiber;
  final String? initialScore;
  final String? initialBreakdown;
  final double? initialVolumePoints;
  final double? initialNetCarbs;
  final double? initialAddedSugar;
  final double? initialSodium;
  final String? initialFiberLight;
  final String? initialSugarLight;
  final String? initialFatLight;
  final String? initialCounterBalanceTip;

  /// The original text query the user typed when invoking the AI.
  final String? originalQuery;

  /// The original image bytes sent to the AI (if any).
  final Uint8List? originalImageBytes;

  /// The MIME type of [originalImageBytes].
  final String? originalImageMimeType;

  /// The raw JSON string returned by the AI in the initial analysis.
  /// When non-null, an "Ask AI to Adjust" option is shown.
  final String? originalAiResponseJson;

  @override
  State<NutritionForm> createState() => _NutritionFormState();
}

class _NutritionFormState extends State<NutritionForm> {
  final _formKey = GlobalKey<FormState>();
  final _caloriesController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatsController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fiberController = TextEditingController();
  String _mealName = '';
  DateTime _date = DateTime.now();
  final _dateFormatter = DateFormat('yyyy-MM-dd HH:mm');

  @override
  void initState() {
    super.initState();
    if (widget.initialMealName != null) _mealName = widget.initialMealName!;
    if (widget.initialCalories != null) _caloriesController.text = widget.initialCalories!.toString();
    if (widget.initialCarbs != null) _carbsController.text = widget.initialCarbs!.toString();
    if (widget.initialFats != null) _fatsController.text = widget.initialFats!.toString();
    if (widget.initialProtein != null) _proteinController.text = widget.initialProtein!.toString();
    if (widget.initialFiber != null) _fiberController.text = widget.initialFiber!.toString();
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    _proteinController.dispose();
    _fiberController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_date),
      );
      setState(() {
        _date = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime?.hour ?? _date.hour,
          pickedTime?.minute ?? _date.minute,
        );
      });
    }
  }

  void _autoFill(NutritionEntry entry) {
    _caloriesController.text = entry.calories.toString();
    _carbsController.text = entry.carbs.toString();
    _fatsController.text = entry.fats.toString();
    _proteinController.text = entry.protein.toString();
    _fiberController.text = entry.fiber.toString();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final newEntry = NutritionEntry(
        mealName: _mealName.trim(),
        calories: double.tryParse(_caloriesController.text) ?? 0,
        carbs: double.tryParse(_carbsController.text) ?? 0,
        fats: double.tryParse(_fatsController.text) ?? 0,
        protein: double.tryParse(_proteinController.text) ?? 0,
        fiber: double.tryParse(_fiberController.text) ?? 0,
        date: _date,
        score: widget.initialScore,
        breakdown: widget.initialBreakdown,
        volumePoints: widget.initialVolumePoints,
        netCarbs: widget.initialNetCarbs,
        addedSugar: widget.initialAddedSugar,
        sodium: widget.initialSodium,
        fiberLight: widget.initialFiberLight,
        sugarLight: widget.initialSugarLight,
        fatLight: widget.initialFatLight,
        counterBalanceTip: widget.initialCounterBalanceTip,
      );

      context.read<ExpenseProvider>().addNutritionEntry(newEntry);
      Navigator.pop(context);
    }
  }

  Future<void> _showAdjustmentSheet() async {
    final adjustmentController = TextEditingController();
    bool isLoading = false;
    Map<String, dynamic>? result;

    try {
      result = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> submitAdjustment() async {
              final userRequest = adjustmentController.text.trim();
              if (userRequest.isEmpty) return;
              setSheetState(() => isLoading = true);
              try {
                final model = FirebaseAI.googleAI().generativeModel(
                  model: 'gemini-2.5-flash',
                );

                final List<Part> parts = [];
                if (widget.originalImageBytes != null) {
                  parts.add(InlineDataPart(
                    widget.originalImageMimeType ?? 'image/jpeg',
                    widget.originalImageBytes!,
                  ));
                }

                final fullPrompt = StringBuffer(kNutritionSystemPrompt);
                fullPrompt.writeln();
                if (widget.originalQuery != null && widget.originalQuery!.isNotEmpty) {
                  fullPrompt.writeln('The user originally described their meal as: "${widget.originalQuery!}"');
                  fullPrompt.writeln();
                }
                fullPrompt.writeln('Your previous analysis was:');
                fullPrompt.writeln(widget.originalAiResponseJson!);
                fullPrompt.writeln();
                fullPrompt.writeln('The user has reviewed your analysis and requests the following adjustment:');
                fullPrompt.writeln(userRequest);
                fullPrompt.writeln();
                fullPrompt.writeln('Please provide a revised JSON response that incorporates the user\'s feedback. In the "summary" field, clearly explain what changed from the previous analysis and why you made these adjustments.');

                parts.add(TextPart(fullPrompt.toString()));

                final response = await model.generateContent([Content.multi(parts)]);
                final text = response.text ?? '';
                final jsonStart = text.indexOf('{');
                final jsonEnd = text.lastIndexOf('}');
                if (jsonStart == -1 || jsonEnd == -1) {
                  throw const FormatException('No JSON in response');
                }
                final rawJson = text.substring(jsonStart, jsonEnd + 1);
                final data = jsonDecode(rawJson) as Map<String, dynamic>;
                data['_rawJson'] = rawJson;

                if (ctx.mounted) {
                  Navigator.pop(ctx, data);
                }
              } catch (e) {
                setSheetState(() => isLoading = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'AI error: could not process adjustment. Please try again.',
                      ),
                    ),
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
                    'Request AI Adjustment',
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tell the AI what you\'d like to change about this analysis.',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: adjustmentController,
                    decoration: const InputDecoration(
                      hintText:
                          'e.g. The portion was larger, about 2x what you estimated',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 16),
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : FilledButton.icon(
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Submit Adjustment'),
                          onPressed: submitAdjustment,
                        ),
                ],
              ),
            );
          },
        );
      },
    );
    } finally {
      adjustmentController.dispose();
    }

    if (result != null && mounted) {
      final rawJson = result.remove('_rawJson') as String?;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => NutritionForm(
            initialMealName: result['meal_name'] as String?,
            initialCalories:
                (result['nutrients_numeric']?['calories'] as num?)?.toDouble(),
            initialCarbs:
                (result['nutrients_numeric']?['total_carbs_g'] as num?)
                    ?.toDouble(),
            initialFats:
                (result['nutrients_numeric']?['fat_g'] as num?)?.toDouble(),
            initialProtein:
                (result['nutrients_numeric']?['protein_g'] as num?)?.toDouble(),
            initialFiber:
                (result['nutrients_numeric']?['fiber_g'] as num?)?.toDouble(),
            initialScore: result['overall_score'] as String?,
            initialBreakdown: result['summary'] as String?,
            initialVolumePoints:
                (result['volume_points'] as num?)?.toDouble(),
            initialNetCarbs:
                (result['nutrients_numeric']?['net_carbs_g'] as num?)
                    ?.toDouble(),
            initialAddedSugar:
                (result['nutrients_numeric']?['added_sugar_g'] as num?)
                    ?.toDouble(),
            initialSodium:
                (result['nutrients_numeric']?['sodium_mg'] as num?)?.toDouble(),
            initialFiberLight:
                result['quality_ratings']?['fiber_light'] as String?,
            initialSugarLight:
                result['quality_ratings']?['sugar_light'] as String?,
            initialFatLight:
                result['quality_ratings']?['fat_light'] as String?,
            initialCounterBalanceTip: result['counter_balance_tip'] as String?,
            originalQuery: widget.originalQuery,
            originalImageBytes: widget.originalImageBytes,
            originalImageMimeType: widget.originalImageMimeType,
            originalAiResponseJson: rawJson,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allEntries = context.watch<ExpenseProvider>().nutrition;

    // Build a map of unique meal names → most recent entry for autofill
    final Map<String, NutritionEntry> mealMap = {};
    for (final entry in allEntries.reversed) {
      mealMap[entry.mealName.toLowerCase()] = entry;
    }
    final mealOptions = mealMap.values.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Log Meal')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // AI summary card — shown when the form was pre-filled by AI
              if (widget.initialBreakdown != null) ...[
                Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AI Analysis',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.initialBreakdown!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (widget.originalAiResponseJson != null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Ask AI to Adjust'),
                    onPressed: _showAdjustmentSheet,
                  ),
                const SizedBox(height: 16),
              ],
              Autocomplete<NutritionEntry>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) return const [];
                  return mealOptions.where(
                    (e) => e.mealName.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    ),
                  );
                },
                displayStringForOption: (e) => e.mealName,
                onSelected: (NutritionEntry selected) {
                  setState(() => _mealName = selected.mealName);
                  _autoFill(selected);
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Meal Name',
                        ),
                        onChanged: (value) => setState(() => _mealName = value),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter a meal name'
                            : null,
                      );
                    },
              ),
              const SizedBox(height: 16),
              // Enter Calories
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(
                  labelText: 'Calories',
                  suffixText: 'kcal',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter calories' : null,
              ),
              const SizedBox(height: 16),
              // Enter Carbs
              TextFormField(
                controller: _carbsController,
                decoration: const InputDecoration(
                  labelText: 'Carbs',
                  suffixText: 'g',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter carbs' : null,
              ),
              const SizedBox(height: 16),
              // Enter Fats
              TextFormField(
                controller: _fatsController,
                decoration: const InputDecoration(
                  labelText: 'Fats',
                  suffixText: 'g',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter fats' : null,
              ),
              const SizedBox(height: 16),
              // Enter Protein
              TextFormField(
                controller: _proteinController,
                decoration: const InputDecoration(
                  labelText: 'Protein',
                  suffixText: 'g',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter protein' : null,
              ),
              const SizedBox(height: 16),
              // Enter Fiber
              TextFormField(
                controller: _fiberController,
                decoration: const InputDecoration(
                  labelText: 'Fiber',
                  suffixText: 'g',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter fiber' : null,
              ),
              const SizedBox(height: 16),
              // Select Date & Time
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date & Time'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_dateFormatter.format(_date)),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Save Meal Button
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Save Meal'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
