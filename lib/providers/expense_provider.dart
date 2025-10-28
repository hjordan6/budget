import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';
import '../models/category.dart';

enum AppPage { list, categories, account }

class ExpenseProvider extends ChangeNotifier {
  static const String expenseBoxName = 'expenses';
  static const String budgetBoxName = 'categories';
  String? user;
  List<String>? _users;

  List<String> get users => _users ?? [];

  final List<String> _boxes = [expenseBoxName, budgetBoxName];
  List<String> get boxes => _boxes;

  late Box<Expense> _expenseBox;
  late Box<BudgetCategory> _budgetBox;

  AppPage _currentView = AppPage.categories;

  List<Expense> get expenses => _expenseBox.values.toList();
  Map<String, BudgetCategory> get budgets => {
    for (var b in _budgetBox.values) b.name: b,
  };
  AppPage get currentView => _currentView;

  /// Initialize Hive boxes (call this before using the provider)
  Future<void> init() async {
    _expenseBox = Hive.box<Expense>(expenseBoxName);
    _budgetBox = Hive.box<BudgetCategory>(budgetBoxName);
    notifyListeners();
  }

  Future<List<String>> _getUsers() async {
    final usersCol = await FirebaseFirestore.instance.collection('users').get();
    return usersCol.docs.map((d) => d.data().toString()).toList();
  }

  void updateBudgets() {
    _updateBudgets();
    sync();
  }

  void _updateBudgets() {
    for (var b in _budgetBox.values) {
      if (b.nextUpdate.isBefore(DateTime.now())) {
        b.balance += b.budget;
        b.pushUpdate();
        b.save();
      }
    }
  }

  void moveMoney(String from, String? to, double amount) {
    BudgetCategory? f = _budgetBox.get(from);
    f?.balance -= amount;
    f?.save();
    BudgetCategory? t = _budgetBox.get(to);
    t?.balance += amount;
    t?.save();
    notifyListeners();
  }

  /// Adds a new expense to Hive and updates the balance
  void addExpense(Expense expense) {
    _expenseBox.add(expense);

    final budget = _budgetBox.values.firstWhere(
      (b) => b.name == expense.category,
      orElse: () => BudgetCategory(
        name: expense.category,
        budget: 0,
        balance: 0,
        interval: BudgetInterval.month,
        nextUpdate: DateTime.now(),
      ),
    );

    budget.balance -= expense.price;
    budget.save();

    notifyListeners();
  }

  /// Adds a new budget category to Hive
  void addBudget(BudgetCategory budget) {
    _budgetBox.put(budget.name, budget);
    notifyListeners();
  }

  /// Deletes an expense
  void deleteExpense(Expense expense) {
    expense.delete();
    notifyListeners();
  }

  /// Deletes a budget
  void deleteBudget(BudgetCategory budget) {
    budget.delete();
    notifyListeners();
  }

  void deleteAllExpenses() {
    _expenseBox.clear();
  }

  void deleteAllBudgets() {
    _budgetBox.clear();
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
    return {for (var b in _budgetBox.values) b.name: b.balance};
  }

  Future<void> sync() async {
    print("syncing");
    final firestore = FirebaseFirestore.instance;

    if (user == null) return;

    final userRef = firestore.collection('users').doc(user);

    // 1️⃣ --- FETCH REMOTE ---
    final remoteCategories = await userRef.collection('categories').get();
    final remoteExpenses = await userRef.collection('expenses').get();
    _users = await _getUsers();

    // 2️⃣ --- MERGE INTO HIVE ---
    // Budgets: Firestore -> Hive
    for (var doc in remoteCategories.docs) {
      final data = doc.data();
      final category = BudgetCategory.fromJson(data);
      _budgetBox.put(category.name, category);
    }

    // Expenses: Firestore -> Hive
    for (var doc in remoteExpenses.docs) {
      final data = doc.data();
      final expense = Expense.fromJson(data);
      // Avoid duplicates: expense.id must be unique (e.g., Firestore doc id)
      if (!_expenseBox.values.any((e) => e.id == expense.id)) {
        _expenseBox.add(expense);
      }
    }

    // 3️⃣ --- PUSH LOCAL CHANGES TO FIRESTORE ---
    // Budgets Hive -> Firestore
    for (var b in _budgetBox.values) {
      await userRef.collection('categories').doc(b.name).set(b.toJson());
    }

    // Expenses Hive -> Firestore
    for (var e in _expenseBox.values) {
      // use e.id as docId if your model has one
      await userRef.collection('expenses').doc(e.id).set(e.toJson());
    }

    notifyListeners();
    print("sync finished");
  }
}
