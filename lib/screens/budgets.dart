import 'package:budget/models/category.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import 'budget_info.dart';
import 'category_form.dart';
import 'expense_form.dart';
import '../utils.dart';

class CategorySummaryPage extends StatelessWidget {
  const CategorySummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    var categories = context.watch<ExpenseProvider>().budgets.entries.toList();

    // Returns a list tile for the given budget category
    getListTile(MapEntry<String, BudgetCategory> c) {
      final categoryName = c.key;
      final category = c.value;
      return ListTile(
        leading: const Icon(Icons.label),
        title: Text(categoryName),
        trailing: Text(category.balance.asPrice),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BudgetInfo(budgetName: categoryName),
            ),
          );
        },
      );
    }

    // find all of the budget categories
    List<MapEntry<String, BudgetCategory>> budgetCategories = categories
        .where((entry) => !entry.value.savings)
        .toList();

    // find all of the savings categories
    List<MapEntry<String, BudgetCategory>> savingsCategories = categories
        .where((entry) => entry.value.savings)
        .toList();

    // prepare list of list tiles, with divider between the budgets and savings
    List<Widget> listTiles = [];

    // Add Budget + Add Expense buttons at the top (centered, sized)
    listTiles.add(
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Budget'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(140, 44),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CategoryForm()),
                  );
                },
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.attach_money),
                label: const Text('Add Expense'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(140, 44),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExpenseForm()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    // If there are no categories, show a message below the button
    if (budgetCategories.isEmpty && savingsCategories.isEmpty) {
      listTiles.add(
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Text('No budgets created yet'),
          ),
        ),
      );
      return ListView(children: listTiles);
    }

    listTiles.addAll(budgetCategories.map(getListTile).toList());
    if (savingsCategories.isNotEmpty) {
      listTiles.addAll([Center(child: Text("Savings Categories"))]);
      listTiles.addAll(savingsCategories.map(getListTile).toList());
    }

    return ListView(children: listTiles);
  }
}
