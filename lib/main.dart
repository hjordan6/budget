import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/expense_provider.dart';
import 'screens/data_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  ExpenseProvider provider = ExpenseProvider();
  provider.loadUser();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => provider)],
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
