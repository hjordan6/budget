import 'package:budget/log.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';
import '../models/category.dart';
import 'dart:async';

enum AppPage { list, categories, account, saving }

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
        .orderBy('date', descending: true)
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
            Logger.error(
              "Error listening to expenses",
              data: {"user": user, "error": error.toString()},
            );
          },
        );

    // Listen to categories collection
    _categoriesSubscription = userRef
        .collection('categories')
        .orderBy('savings')
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
            Logger.error(
              "Error listening to categories",
              data: {"user": user, "error": error.toString()},
            );
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
        Logger.info(
          "Updating budget",
          data: {
            "user": user,
            "budget": budget.name,
            "oldBalance": budget.balance,
            "newBalance": budget.balance + budget.budget,
          },
        );
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

    Logger.info(
      "Moving money",
      data: {"from": from, "to": to, "amount": amount, "user": user},
    );

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
    Logger.info(
      "Adding expense",
      data: {
        "user": user,
        "id": expense.id,
        "name": expense.name,
        "price": expense.price,
        "category": expense.category,
        "date": expense.date.toIso8601String(),
      },
    );
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

    try {
      // Save to recentlyDeleted BEFORE deleting
      Logger.info(
        "Backing up expense to recentlyDeleted",
        data: {
          "user": user,
          "id": expense.id,
          "name": expense.name,
          "price": expense.price,
          "category": expense.category,
          "date": expense.date.toIso8601String(),
        },
      );
      await userRef.collection('recentlyDeleted').doc(expense.id).set({
        ...expense.toJson(),
        'deletedAt': FieldValue.serverTimestamp(),
      });

      // Now delete the expense
      await userRef.collection('expenses').doc(expense.id).delete();

      // Update category balance
      await userRef.collection('categories').doc(expense.category).update({
        'balance': FieldValue.increment(expense.price),
      });

      print("deleted expense ${expense.id}");
    } catch (e) {
      print("Error deleting expense: $e");
      Logger.error(
        "Error deleting expense",
        data: {
          "user": user,
          "id": expense.id,
          "name": expense.name,
          "price": expense.price,
          "category": expense.category,
          "date": expense.date.toIso8601String(),
          "error": e.toString(),
        },
      );
      rethrow;
    }
  }

  /// Updates a budget category in Firestore
  Future<void> updateBudget(
    String oldName,
    BudgetCategory updatedBudget,
  ) async {
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user);

    Logger.info(
      "Updating budget",
      data: {
        "user": user,
        "oldName": oldName,
        "updatedName": updatedBudget.name,
        "updatedBudget": updatedBudget.toJson(),
      },
    );

    try {
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
    } catch (e) {
      Logger.error(
        "Error updating budget",
        data: {
          "user": user,
          "oldName": oldName,
          "updatedName": updatedBudget.name,
          "updatedBudget": updatedBudget.toJson(),
          "error": e.toString(),
        },
      );
      rethrow;
    }
  }

  /// Deletes a budget
  Future<void> deleteBudget(BudgetCategory budget) async {
    if (user == null) return;

    Logger.info(
      "Deleting budget",
      data: {
        "user": user,
        "budget": budget.name,
        "balance": budget.balance,
        "budgetedAmount": budget.budget,
      },
    );

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

  void toggleView(AppPage view) {
    if (_currentView != view) {
      _currentView = view;
      notifyListeners();
    }
  }

  Map<String, double> get categoryTotals {
    return {for (var b in _budgets.values) b.name: b.balance};
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }
}
