import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';

class ExpenseListPage extends StatelessWidget {
  const ExpenseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>().expenses
      ..sort((a, b) => b.date.compareTo(a.date));

    if (expenses.isEmpty) return const Center(child: Text('No expenses yet.'));

    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final e = expenses[index];
        return Dismissible(
          key: Key(e.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) {
            // Call the provider to remove the expense
            context.read<ExpenseProvider>().deleteExpense(e);
          },
          child: ListTile(
            title: Text(e.name),
            subtitle: Text('${e.category} • \$${e.price.toStringAsFixed(2)}'),
            trailing: Text(
              '${e.date.month}/${e.date.day}/${e.date.year}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}
