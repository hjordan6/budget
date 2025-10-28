import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetCategory {
  final String name;
  final double budget;
  double balance;
  BudgetInterval interval;
  final String notes;
  DateTime nextUpdate;

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

  BudgetCategory({
    required this.name,
    required this.budget,
    required this.balance,
    required this.interval,
    required this.nextUpdate,
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
      'interval': interval.name, // "week" | "month" | ...
      'nextUpdate': nextUpdate,
      'notes': notes,
    };
  }
}

enum BudgetInterval {
  week,
  month,
  quarter,
  year,
}
