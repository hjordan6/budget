import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

part 'expense.g.dart';

@HiveType(typeId: 2)
class Expense extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String category;

  @HiveField(2)
  final double price;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String notes;

  @HiveField(5)
  final String? id;

  Expense({
    String? id,
    required this.name,
    required this.category,
    required this.price,
    required this.date,
    this.notes = '',
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'date': date,
      'notes': notes,
    };
  }

  /// Create Expense from Firestore / JSON
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      name: json['name'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      date: (json['date'] as Timestamp).toDate(),
      notes: json['notes'] ?? '',
    );
  }
}
