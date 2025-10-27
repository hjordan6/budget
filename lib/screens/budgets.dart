import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import 'budget_info.dart';
import '../utils.dart';

class CategorySummaryPage extends StatelessWidget {
  const CategorySummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryTotals = context.watch<ExpenseProvider>().categoryTotals;

    if (categoryTotals.isEmpty) {
      return const Center(child: Text('No budgets created yet'));
    }

    return ListView(
      children: categoryTotals.entries.map((entry) {
        final category = entry.key;
        final total = entry.value;
        return ListTile(
          leading: const Icon(Icons.label),
          title: Text(category),
          trailing: Text(total.asPrice),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BudgetInfo(budgetName: category),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
