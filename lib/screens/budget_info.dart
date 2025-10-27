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
  final TextEditingController _moveAmountController = TextEditingController();
  String? _selectedBudget;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    Map<String, BudgetCategory> budgets = provider.budgets;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Info'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ListTile(
              title: Text("Budget Name"),
              trailing: Text(widget.budgetName),
            ),
            if (provider.budgets[widget.budgetName] != null)
              ListTile(
                title: Text("Interval"),
                trailing: Text(
                  provider
                          .budgets[widget.budgetName]
                          ?.interval
                          .name
                          .capitalize ??
                      "",
                ),
              ),
            if (provider.budgets[widget.budgetName] != null)
              ListTile(
                title: Text("Budgeted"),
                trailing: Text(
                  provider.budgets[widget.budgetName]?.budget.asPrice ?? "",
                ),
              ),
            if (provider.budgets[widget.budgetName] != null)
              ListTile(
                title: Text("Balance"),
                trailing: Text(
                  provider.budgets[widget.budgetName]?.balance.asPrice ?? "",
                ),
              ),
            if (provider.budgets[widget.budgetName] != null)
              ListTile(
                title: Text("Next Update"),
                trailing: Text(
                  provider
                          .budgets[widget.budgetName]
                          ?.nextUpdate
                          .formattedDate ??
                      "",
                ),
              ),
            const SizedBox(height: 16),

            // Show TextField and Dropdown when _adding is true
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
        ),
      ),
    );
  }

  @override
  void dispose() {
    _moveAmountController.dispose();
    super.dispose();
  }
}
