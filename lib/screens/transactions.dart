import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';

class ExpenseListPage extends StatelessWidget {
  const ExpenseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>().expenses;

    if (expenses.isEmpty) return const Center(child: Text('No expenses yet.'));

    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final e = expenses[index];
        return ListTile(
          title: Text(e.name),
          subtitle: Text('${e.category} • \$${e.price.toStringAsFixed(2)}'),
          trailing: Text(
            '${e.date.month}/${e.date.day}/${e.date.year}',
            style: const TextStyle(fontSize: 12),
          ),
        );
      },
    );
  }
}
