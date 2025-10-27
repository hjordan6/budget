import 'package:budget/screens/account.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import 'expense_form.dart';
import 'category_form.dart';
import 'transactions.dart';
import 'budgets.dart';

class DataPage extends StatelessWidget {
  const DataPage({super.key});

  AppBar appBar(AppPage page) {
    if (page == AppPage.list) {
      return AppBar(title: Text("Transactions"));
    } else if (page == AppPage.categories) {
      return AppBar(title: Text("Budget Categories"));
    } else {
      return AppBar(title: Text("Account Info"));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final currentPage = provider.currentView;

    final pageMap = {
      AppPage.list: const ExpenseListPage(),
      AppPage.categories: const CategorySummaryPage(),
      AppPage.account: AccountPage(),
    };

    return Scaffold(
      appBar: appBar(currentPage),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              child: Center(
                child: Text(
                  'Expense Tracker',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Expense List'),
              selected: currentPage == AppPage.list,
              onTap: () {
                provider.toggleView(AppPage.list);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.pie_chart),
              title: const Text('Category Summary'),
              selected: currentPage == AppPage.categories,
              onTap: () {
                provider.toggleView(AppPage.categories);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Account Actions'),
              selected: currentPage == AppPage.account,
              onTap: () {
                provider.toggleView(AppPage.account);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: pageMap[currentPage] ?? const Center(child: Text('Page not found')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (currentPage == AppPage.list) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExpenseForm()),
            );
          } else if (currentPage == AppPage.categories) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryForm()),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
