import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/nutrition.dart';
import '../providers/expense_provider.dart';

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
