import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import 'budget_info.dart';
import '../utils.dart';

class CategorySummaryPage extends StatelessWidget {
  const CategorySummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    var categories = context.watch<ExpenseProvider>().budgets.entries.toList()
      ..sort((a, b) {
        if (a.value.savings == b.value.savings) {
          return a.key.compareTo(b.key);
        } else if (a.value.savings) {
          return 1;
        } else {
          return -1;
        }
      });

    if (categories.isEmpty) {
      return const Center(child: Text('No budgets created yet'));
    }

    return ListView(
      children: categories.map((entry) {
        final categoryName = entry.key;
        final category = entry.value;
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
      }).toList(),
    );
  }
}
