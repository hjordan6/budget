import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';
import '../models/category.dart';
import 'dart:async';

enum AppPage { list, categories, account }

class ExpenseProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? user;

  List<Expense> _expenses = [];
  Map<String, BudgetCategory> _budgets = {};

  AppPage _currentView = AppPage.categories;

  StreamSubscription<QuerySnapshot>? _expensesSubscription;
  StreamSubscription<QuerySnapshot>? _categoriesSubscription;

  List<Expense> get expenses => _expenses;
  Map<String, BudgetCategory> get budgets => _budgets;
  AppPage get currentView => _currentView;

  void _startListening() {
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user);

    // Listen to expenses collection
    _expensesSubscription = userRef
        .collection('expenses')
        .snapshots()
        .listen(
          (snapshot) {
            _expenses = snapshot.docs.map((doc) {
              return Expense.fromJson(doc.data(), doc.id);
            }).toList();
            notifyListeners();
          },
          onError: (error) {
            print('Error listening to expenses: $error');
          },
        );

    // Listen to categories collection
    _categoriesSubscription = userRef
        .collection('categories')
        .snapshots()
        .listen(
          (snapshot) {
            _budgets = {
              for (var doc in snapshot.docs)
                doc.id: BudgetCategory.fromJson(doc.data()),
            };
            notifyListeners();
          },
          onError: (error) {
            print('Error listening to categories: $error');
          },
        );
  }

  void _stopListening() {
    _expensesSubscription?.cancel();
    _categoriesSubscription?.cancel();
    _expensesSubscription = null;
    _categoriesSubscription = null;
  }

  void setUser(String? newUser) {
    if (user != newUser) {
      _stopListening();
      user = newUser;
      _expenses = [];
      _budgets = {};
      if (user != null) {
        _startListening();
      }
      notifyListeners();
    }
  }

  void updateBudgets() {
    _updateBudgets();
  }

  Future<void> _updateBudgets() async {
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user);
    final now = DateTime.now();

    for (var budget in _budgets.values) {
      if (budget.nextUpdate.isBefore(now)) {
        budget.balance += budget.budget;
        budget.pushUpdate();

        // Update in Firestore
        await userRef
            .collection('categories')
            .doc(budget.name)
            .update(budget.toJson());
      }
    }
  }

  Future<void> moveMoney(String from, String? to, double amount) async {
    if (user == null || to == null) return;

    final userRef = _firestore.collection('users').doc(user);

    // Update from budget
    final fromBudget = _budgets[from];
    if (fromBudget != null) {
      fromBudget.balance -= amount;
      await userRef.collection('categories').doc(from).update({
        'balance': fromBudget.balance,
      });
    }

    // Update to budget
    final toBudget = _budgets[to];
    if (toBudget != null) {
      toBudget.balance += amount;
      await userRef.collection('categories').doc(to).update({
        'balance': toBudget.balance,
      });
    }
  }

  /// Adds a new expense to Firestore and updates the balance
  Future<void> addExpense(Expense expense) async {
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user);

    // Add expense to Firestore
    await userRef.collection('expenses').doc(expense.id).set(expense.toJson());

    // Update budget balance
    final budget = _budgets[expense.category];
    if (budget != null) {
      budget.balance -= expense.price;
      await userRef.collection('categories').doc(budget.name).update({
        'balance': budget.balance,
      });
    }
  }

  /// Adds a new budget category to Firestore
  Future<void> addBudget(BudgetCategory budget) async {
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user);
    await userRef
        .collection('categories')
        .doc(budget.name)
        .set(budget.toJson());
  }

  /// Deletes an expense
  Future<void> deleteExpense(Expense expense) async {
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user);
    await userRef.collection('expenses').doc(expense.id).delete();
    await userRef.collection('categories').doc(expense.category).update({
      'balance': FieldValue.increment(expense.price),
    });
  }

  /// Updates a budget category in Firestore
  Future<void> updateBudget(
    String oldName,
    BudgetCategory updatedBudget,
  ) async {
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user);

    // If name changed, delete old document and create new one
    if (oldName != updatedBudget.name) {
      // Update all expenses that reference the old category name
      final expensesSnapshot = await userRef
          .collection('expenses')
          .where('category', isEqualTo: oldName)
          .get();

      for (var doc in expensesSnapshot.docs) {
        await doc.reference.update({'category': updatedBudget.name});
      }

      // Delete old category and create new one
      await userRef.collection('categories').doc(oldName).delete();
      await userRef
          .collection('categories')
          .doc(updatedBudget.name)
          .set(updatedBudget.toJson());
    } else {
      // Otherwise just update the existing document
      await userRef
          .collection('categories')
          .doc(oldName)
          .update(updatedBudget.toJson());
    }
  }

  /// Deletes a budget
  Future<void> deleteBudget(BudgetCategory budget) async {
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user);
    await userRef.collection('categories').doc(budget.name).delete();
  }

  Future<void> deleteAllExpenses() async {
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user);
    final snapshot = await userRef.collection('expenses').get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> deleteAllBudgets() async {
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user);
    final snapshot = await userRef.collection('categories').get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  /// Switch between list view and summary view
  void toggleView(AppPage view) {
    if (_currentView != view) {
      _currentView = view;
      notifyListeners();
    }
  }

  /// Calculate total spent per category
  Map<String, double> get categoryTotals {
    return {for (var b in _budgets.values) b.name: b.balance};
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }
}
