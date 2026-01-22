import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import 'expense_form.dart';
import '../utils.dart';

class ExpenseListPage extends StatefulWidget {
  const ExpenseListPage({super.key});

  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final allExpenses = List.of(context.watch<ExpenseProvider>().expenses);
    allExpenses.sort((a, b) => b.date.compareTo(a.date));

    final filtered = _query.isEmpty
        ? allExpenses
        : allExpenses
              .where(
                (e) =>
                    e.name.toLowerCase().contains(_query) ||
                    e.category.toLowerCase().contains(_query),
              )
              .toList();

    final header = Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.attach_money),
            label: const Text('Add Expense'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(140, 44)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExpenseForm()),
              );
            },
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 220,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search expenses',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _query = val.toLowerCase()),
            ),
          ),
        ],
      ),
    );

    final children = <Widget>[header];

    if (filtered.isEmpty) {
      children.add(
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Text('No expenses yet.'),
          ),
        ),
      );
    } else {
      children.addAll(
        filtered.map((e) {
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
        }),
      );
    }

    return ListView(children: children);
  }
}
