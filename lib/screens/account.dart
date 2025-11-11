import 'package:budget/providers/expense_provider.dart';
import 'package:budget/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

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

  void _logout(BuildContext context, AuthProvider authProvider) async {
    await authProvider.signOut();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ExpenseProvider provider = context.watch<ExpenseProvider>();
    AuthProvider authProvider = context.watch<AuthProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                "Account Information",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                "Email: ${authProvider.user?.email ?? 'Not available'}",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                "User ID: ${authProvider.userId ?? 'Not available'}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // --- LOGOUT BUTTON ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ElevatedButton(
            onPressed: () => _logout(context, authProvider),
            child: const Text("Logout"),
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
