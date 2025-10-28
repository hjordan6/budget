import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class Expense {
  final String name;
  final String category;
  final double price;
  final DateTime date;
  final String notes;
  final String id;

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
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'date': date,
      'notes': notes,
    };
  }

  /// Create Expense from Firestore / JSON
  factory Expense.fromJson(Map<String, dynamic> json, String docId) {
    return Expense(
      id: json['id'] ?? docId,
      name: json['name'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      date: (json['date'] as Timestamp).toDate(),
      notes: json['notes'] ?? '',
    );
  }
}
