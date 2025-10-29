import 'package:budget/models/category.dart';
import 'package:budget/widgets/price_input.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../utils.dart';

class BudgetInfo extends StatefulWidget {
  const BudgetInfo({super.key, required this.budgetName});
  final String budgetName;

  @override
  State<BudgetInfo> createState() => _BudgetInfoState();
}

class _BudgetInfoState extends State<BudgetInfo> {
  bool _moving = false;
  bool _editing = false;
  final TextEditingController _moveAmountController = TextEditingController();
  String? _selectedBudget;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  BudgetInterval? _selectedInterval;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ExpenseProvider>();
      final budget = provider.budgets[widget.budgetName];
      if (budget != null) {
        _nameController.text = budget.name;
        _budgetController.text = '\$${budget.budget.toStringAsFixed(2)}';
        _balanceController.text = '\$${budget.balance.toStringAsFixed(2)}';
        _selectedInterval = budget.interval;
      }
    });
  }

  void _saveChanges() {
    final provider = context.read<ExpenseProvider>();
    final currentBudget = provider.budgets[widget.budgetName];

    if (currentBudget == null) return;

    final newName = _nameController.text.trim();

    String budgetText = _budgetController.text.replaceAll(RegExp(r'[\$,]'), '');
    final newBudgetAmount = double.tryParse(budgetText) ?? currentBudget.budget;

    String balanceText = _balanceController.text.replaceAll(
      RegExp(r'[\$,]'),
      '',
    );
    final newBalance = double.tryParse(balanceText) ?? currentBudget.balance;

    final newInterval = _selectedInterval ?? currentBudget.interval;

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget name cannot be empty')),
      );
      return;
    }

    if (newName != widget.budgetName && provider.budgets.containsKey(newName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Budget with name "$newName" already exists')),
      );
      return;
    }

    DateTime newNextUpdate = currentBudget.nextUpdate;
    if (newInterval != currentBudget.interval) {
      newNextUpdate = BudgetCategory.calculateNextUpdate(newInterval);
    }

    final updatedBudget = BudgetCategory(
      name: newName,
      budget: newBudgetAmount,
      balance: newBalance,
      interval: newInterval,
      nextUpdate: newNextUpdate,
      notes: currentBudget.notes,
    );

    provider.updateBudget(widget.budgetName, updatedBudget);

    setState(() {
      _editing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Budget updated successfully')),
    );

    // Navigate back if name changed
    if (newName != widget.budgetName) {
      Navigator.pop(context);
    }
  }

  void _deleteBudget() {
    final provider = context.read<ExpenseProvider>();
    final budget = provider.budgets[widget.budgetName];

    if (budget == null) return;

    // Count expenses in this category
    final expenseCount = provider.expenses
        .where((e) => e.category == budget.name)
        .length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${budget.name}"?'),
            if (expenseCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Warning: $expenseCount expense(s) reference this budget. They will not be deleted but will become uncategorized.',
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteBudget(budget);
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Budget "${budget.name}" deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    Map<String, BudgetCategory> budgets = provider.budgets;
    final currentBudget = budgets[widget.budgetName];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Info'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (currentBudget != null && !_editing && !_moving)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _editing = true;
                  _nameController.text = currentBudget.name;
                  _budgetController.text =
                      '\$${currentBudget.budget.toStringAsFixed(2)}';
                  _balanceController.text =
                      '\$${currentBudget.balance.toStringAsFixed(2)}';
                  _selectedInterval = currentBudget.interval;
                });
              },
              tooltip: 'Edit Budget',
            ),
          if (currentBudget != null && !_editing && !_moving)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteBudget,
              tooltip: 'Delete Budget',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            if (currentBudget != null && _editing) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Budget Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _budgetController,
                decoration: const InputDecoration(
                  labelText: 'Budgeted Amount',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _balanceController,
                decoration: const InputDecoration(
                  labelText: 'Balance',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BudgetInterval>(
                initialValue: _selectedInterval,
                decoration: const InputDecoration(
                  labelText: 'Interval',
                  border: OutlineInputBorder(),
                ),
                items: BudgetInterval.values.map((interval) {
                  return DropdownMenuItem(
                    value: interval,
                    child: Text(interval.name.capitalize),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedInterval = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      child: const Text('Save'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _editing = false;
                        });
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ] else if (currentBudget != null && !_editing) ...[
              // View mode
              ListTile(
                title: const Text("Budget Name"),
                trailing: Text(widget.budgetName),
              ),
              ListTile(
                title: const Text("Interval"),
                trailing: Text(currentBudget.interval.name.capitalize),
              ),
              ListTile(
                title: const Text("Budgeted"),
                trailing: Text(currentBudget.budget.asPrice),
              ),
              ListTile(
                title: const Text("Balance"),
                trailing: Text(currentBudget.balance.asPrice),
              ),
              ListTile(
                title: const Text("Next Update"),
                trailing: Text(currentBudget.nextUpdate.formattedDate),
              ),
              const SizedBox(height: 16),

              // Show TextField and Dropdown when _moving is true
              if (_moving) ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedBudget,
                  decoration: InputDecoration(
                    labelText: "Move to",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: budgets.keys
                      .where((key) => key != widget.budgetName)
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBudget = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                PriceTextField(
                  controller: _moveAmountController,
                  displayText: "Amount to move",
                ),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          if (_moving) {
                            provider.moveMoney(
                              widget.budgetName,
                              _selectedBudget,
                              double.parse(
                                _moveAmountController.text.substring(1),
                              ),
                            );
                            _moving = false;
                            _moveAmountController.clear();
                            _selectedBudget = null;
                          } else {
                            _moving = true;
                          }
                        });
                      },
                      child: Text(_moving ? "Move" : "Move Money"),
                    ),
                  ),
                  if (_moving) const SizedBox(width: 16),
                  if (_moving)
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _moving = false;
                            _moveAmountController.clear();
                            _selectedBudget = null;
                          });
                        },
                        child: const Text("Cancel"),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _moveAmountController.dispose();
    _nameController.dispose();
    _budgetController.dispose();
    _balanceController.dispose();
    super.dispose();
  }
}
