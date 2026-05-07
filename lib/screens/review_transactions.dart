import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../utils.dart';

class ReviewTransactionsPage extends StatefulWidget {
  const ReviewTransactionsPage({super.key});

  @override
  State<ReviewTransactionsPage> createState() => _ReviewTransactionsPageState();
}

class _ReviewTransactionsPageState extends State<ReviewTransactionsPage> {
  final Map<String, String> _selectedCategoryByTransactionId = {};

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final pending = provider.unreviewedTransactions;
    final categories = provider.budgets.keys.toList()..sort();

    if (pending.isEmpty) {
      return const Center(child: Text('No transactions to review.'));
    }

    return ListView.builder(
      itemCount: pending.length,
      itemBuilder: (context, index) {
        final tx = pending[index];
        final selectedCategory = _selectedCategoryByTransactionId[tx.id];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${tx.price.asPrice} • ${tx.date.formattedDate}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (tx.category.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Source category: ${tx.category}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Assign to category',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: categories
                      .map(
                        (name) =>
                            DropdownMenuItem(value: name, child: Text(name)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      if (value == null) {
                        _selectedCategoryByTransactionId.remove(tx.id);
                      } else {
                        _selectedCategoryByTransactionId[tx.id] = value;
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        await context
                            .read<ExpenseProvider>()
                            .dismissUnreviewedTransaction(tx);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transaction dismissed')),
                        );
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Dismiss'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: selectedCategory == null
                          ? null
                          : () async {
                              await context
                                  .read<ExpenseProvider>()
                                  .approveUnreviewedTransaction(
                                    tx,
                                    selectedCategory,
                                  );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Transaction added'),
                                ),
                              );
                            },
                      icon: const Icon(Icons.check),
                      label: const Text('Add to Category'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
