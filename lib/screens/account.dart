import 'package:budget/providers/expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccountPage extends StatelessWidget {
  AccountPage({super.key});

  final TextEditingController _nameController = TextEditingController();

  void _clearAllData(BuildContext context, ExpenseProvider provider) {
    try {
      provider.deleteAllExpenses();
      provider.deleteAllBudgets();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data cleared successfully!')),
      );
    } catch (e) {
      print('Error clearing data: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error clearing data: $e')));
    }
  }

  void _updateUserName(BuildContext context, ExpenseProvider provider) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid name')),
      );
      return;
    }

    provider.user = name;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Name updated successfully')));
  }

  @override
  Widget build(BuildContext context) {
    ExpenseProvider provider = context.watch<ExpenseProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: provider.user != null
              ? Text("Logged in user: ${provider.user}")
              : Text("No user logged in"),
        ),
        // --- USER NAME INPUT FIELD ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: "Enter your name",
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // --- SAVE BUTTON ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ElevatedButton(
            onPressed: () => _updateUserName(context, provider),
            child: const Text("Save Name"),
          ),
        ),
        const SizedBox(height: 32),

        // --- ERASE ALL DATA BUTTON ---
        SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
              onPressed: () => _showConfirmationDialog(context, provider),
              child: const Text(
                'Erase All Data',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showConfirmationDialog(BuildContext context, ExpenseProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Erase'),
        content: const Text(
          'Are you sure you want to erase all data? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _clearAllData(context, provider);
            },
            child: const Text('Erase'),
          ),
        ],
      ),
    );
  }
}
