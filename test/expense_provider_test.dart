import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budget/providers/expense_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExpenseProvider User Persistence Tests', () {
    setUp(() {
      // Clear shared preferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('should load user from shared preferences on initialization', () async {
      // Set up mock data
      SharedPreferences.setMockInitialValues({'user': 'TestUser'});

      // Create provider instance
      final provider = ExpenseProvider();

      // Wait for the provider to finish loading
      // In a real test environment, we would use a proper callback or Future
      // For now, we allow a reasonable time for initialization
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify user was loaded
      expect(provider.user, equals('TestUser'));
    });

    test('should save user to shared preferences when setUser is called', () async {
      // Create provider instance
      final provider = ExpenseProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      // Set user
      provider.setUser('NewUser');

      // Wait for save operation to complete
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify user was saved to shared preferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user'), equals('NewUser'));
      expect(provider.user, equals('NewUser'));
    });

    test('should remove user from shared preferences when setUser is called with null', () async {
      // Set up initial user
      SharedPreferences.setMockInitialValues({'user': 'InitialUser'});

      // Create provider instance
      final provider = ExpenseProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      // Clear user
      provider.setUser(null);
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify user was removed
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user'), isNull);
      expect(provider.user, isNull);
    });

    test('should persist user across provider instances', () async {
      // Create first provider and set user
      final provider1 = ExpenseProvider();
      await Future.delayed(const Duration(milliseconds: 50));
      
      provider1.setUser('PersistentUser');
      await Future.delayed(const Duration(milliseconds: 50));

      // Create second provider to simulate app restart
      final provider2 = ExpenseProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify user persisted
      expect(provider2.user, equals('PersistentUser'));
    });

    test('should not load empty string as user', () async {
      // Set up mock data with empty string
      SharedPreferences.setMockInitialValues({'user': ''});

      // Create provider instance
      final provider = ExpenseProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify empty string is not loaded as user
      expect(provider.user, isNull);
    });
  });
}
