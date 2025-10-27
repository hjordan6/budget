import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'providers/expense_provider.dart';
import 'screens/data_page.dart';
import 'models/category.dart';
import 'models/expense.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(BudgetCategoryAdapter());
  Hive.registerAdapter(BudgetIntervalAdapter());
  Hive.registerAdapter(ExpenseAdapter());

  // Open Hive boxes
  await Hive.openBox<BudgetCategory>('categories');
  await Hive.openBox<Expense>('expenses');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            ExpenseProvider p = ExpenseProvider();
            p.init();
            return p;
          },
        ),
        // Add other providers here if needed
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print("updating budgets didChangeDependencies");
    updateBudgets();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("updating budgets didChangeAppLifecycleState");
      updateBudgets();
    }
  }

  void updateBudgets() {
    ExpenseProvider provider = Provider.of<ExpenseProvider>(
      context,
      listen: false,
    );
    provider.updateBudgets();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      home: const DataPage(),
    );
  }
}
