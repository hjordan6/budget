import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetCategory {
  String name;
  double budget;
  double balance;
  BudgetInterval interval;
  final String notes;
  DateTime nextUpdate;
  bool savings;

  void pushUpdate() {
    if (interval == BudgetInterval.week) {
      nextUpdate = nextUpdate.add(Duration(days: 7));
    } else if (interval == BudgetInterval.month) {
      nextUpdate = DateTime(
        nextUpdate.year,
        nextUpdate.month + 1,
        nextUpdate.day,
      );
    } else if (interval == BudgetInterval.quarter) {
      nextUpdate = DateTime(
        nextUpdate.year,
        nextUpdate.month + 3,
        nextUpdate.day,
      );
    } else if (interval == BudgetInterval.year) {
      nextUpdate = DateTime(
        nextUpdate.year + 1,
        nextUpdate.month,
        nextUpdate.day,
      );
    }
  }

  static DateTime calculateNextUpdate(BudgetInterval interval) {
    DateTime now = DateTime.now();
    if (interval == BudgetInterval.week) {
      int daysUntilNextSunday = (DateTime.sunday - now.weekday) % 7;
      if (daysUntilNextSunday == 0) daysUntilNextSunday = 7;
      return DateTime(now.year, now.month, now.day + daysUntilNextSunday);
    } else if (interval == BudgetInterval.month) {
      return DateTime(now.year, now.month + 1, 1);
    } else if (interval == BudgetInterval.quarter) {
      int currentQuarter = ((now.month - 1) ~/ 3) + 1;
      int nextQuarter = currentQuarter == 4 ? 1 : currentQuarter + 1;
      int year = currentQuarter == 4 ? now.year + 1 : now.year;
      int nextQuarterStartMonth = (nextQuarter - 1) * 3 + 1;
      return DateTime(year, nextQuarterStartMonth, 1);
    } else if (interval == BudgetInterval.year) {
      return DateTime(now.year + 1, 1, 1);
    } else {
      throw ArgumentError("Invalid period: $interval");
    }
  }

  BudgetCategory({
    required this.name,
    required this.budget,
    required this.balance,
    required this.interval,
    required this.nextUpdate,
    this.savings = false,
    this.notes = '',
  });

  factory BudgetCategory.fromJson(Map<String, dynamic> json) {
    return BudgetCategory(
      name: json['name'] as String,
      budget: (json['budget'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
      interval: BudgetInterval.values.firstWhere(
        (e) => e.toString() == 'BudgetInterval.${json['interval']}',
      ),
      nextUpdate: (json['nextUpdate'] as Timestamp).toDate(),
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'budget': budget,
      'balance': balance,
      'interval': interval.name,
      'nextUpdate': nextUpdate,
      'notes': notes,
      'savings': savings,
    };
  }
}

enum BudgetInterval { week, month, quarter, year, savings }
