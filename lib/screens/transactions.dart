import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import 'expense_form.dart';
import '../utils.dart';

class ExpenseListPage extends StatelessWidget {
  const ExpenseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>().expenses
      ..sort((a, b) => b.date.compareTo(a.date));

    // Use a header item for the centered Add Expense button
    return ListView.builder(
      itemCount: expenses.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: ElevatedButton.icon(
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
            ),
          );
        }

        final e = expenses[index - 1];
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
            context.read<ExpenseProvider>().deleteExpense(e);
          },
          child: ListTile(
            title: Text(e.name),
            subtitle: Text('${e.category} • ${e.price.asPrice}'),
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
