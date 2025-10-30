import 'package:budget/models/category.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import 'budget_info.dart';
import '../utils.dart';

class CategorySummaryPage extends StatelessWidget {
  const CategorySummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    var categories = context.watch<ExpenseProvider>().budgets.entries.toList();

    if (categories.isEmpty) {
      return const Center(child: Text('No budgets created yet'));
    }

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
    listTiles.addAll(budgetCategories.map(getListTile).toList());
    if (savingsCategories.isNotEmpty) {
      listTiles.addAll([Center(child: Text("Savings Categories"))]);
      listTiles.addAll(savingsCategories.map(getListTile).toList());
    }
    return ListView(children: listTiles);
  }
}
