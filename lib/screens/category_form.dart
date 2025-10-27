import 'package:budget/models/category.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';

class CategoryForm extends StatefulWidget {
  const CategoryForm({super.key});

  @override
  State<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<CategoryForm> {
  final _formKey = GlobalKey<FormState>();
  String _categoryName = '';
  BudgetInterval _interval = BudgetInterval.month;
  double _budget = 0.0;

  DateTime _calculateNextUpdate(BudgetInterval interval) {
    DateTime now = DateTime.now();
    if (interval == BudgetInterval.week) {
      int daysUntilNextSunday = (DateTime.sunday - now.weekday) % 7;
      if (daysUntilNextSunday == 0) daysUntilNextSunday = 7;
      return DateTime(now.year, now.month, now.day + daysUntilNextSunday);
    } else if (interval == BudgetInterval.month) {
      return DateTime(now.year, now.month + 1, 1);
    } else if (interval == BudgetInterval.quarter) {
      int currentQuarter = ((now.month - 1) ~/ 3) + 1;
      int nextQuarter = currentQuarter == 4 ? 1 : currentQuarter + 1;
      int year = currentQuarter == 4 ? now.year + 1 : now.year;
      int nextQuarterStartMonth = (nextQuarter - 1) * 3 + 1;
      return DateTime(year, nextQuarterStartMonth, 1);
    } else if (interval == BudgetInterval.year) {
      return DateTime(now.year + 1, 1, 1);
    } else {
      throw ArgumentError("Invalid period: $interval");
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Add category with budget to the provider
      context.read<ExpenseProvider>().addBudget(
        BudgetCategory(
          name: _categoryName,
          budget: _budget,
          balance: _budget,
          interval: _interval,
          nextUpdate: _calculateNextUpdate(_interval),
        ),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Category added!')));

      Navigator.pop(context); // Go back after adding
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Category')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            spacing: 16,
            children: [
              // Category Name
              TextFormField(
                decoration: const InputDecoration(labelText: 'Category Name'),
                onSaved: (value) => _categoryName = value!.trim(),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter a name' : null,
              ),

              // Budget Amount
              TextFormField(
                decoration: const InputDecoration(labelText: 'Budget Amount'),
                keyboardType: TextInputType.number,
                onSaved: (value) =>
                    _budget = double.tryParse(value ?? '0') ?? 0,
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter a budget amount'
                    : null,
              ),

              DropdownButtonFormField<String>(
                initialValue: "Month",
                items: [
                  DropdownMenuItem(value: "Week", child: Text("Week")),
                  DropdownMenuItem(value: "Month", child: Text("Month")),
                  DropdownMenuItem(value: "Quarter", child: Text("Quarter")),
                  DropdownMenuItem(value: "Year", child: Text("Year")),
                ],
                onChanged: (v) => setState(() {
                  if (v == "Week") {
                    _interval = BudgetInterval.week;
                  } else if (v == "Month") {
                    _interval = BudgetInterval.month;
                  } else if (v == "Quarter") {
                    _interval = BudgetInterval.quarter;
                  } else if (v == "Year") {
                    _interval = BudgetInterval.year;
                  }
                }),
                decoration: const InputDecoration(labelText: 'Interval'),
              ),

              Spacer(),

              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Save Category'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
