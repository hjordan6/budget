import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class NutritionEntry {
  final String id;
  final String mealName;
  final double calories;
  final double carbs;
  final double fats;
  final double protein;
  final double fiber;
  final DateTime date;

  NutritionEntry({
    String? id,
    required this.mealName,
    required this.calories,
    required this.carbs,
    required this.fats,
    required this.protein,
    this.fiber = 0,
    required this.date,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mealName': mealName,
      'calories': calories,
      'carbs': carbs,
      'fats': fats,
      'protein': protein,
      'fiber': fiber,
      'date': date,
    };
  }

  factory NutritionEntry.fromJson(Map<String, dynamic> json, String docId) {
    return NutritionEntry(
      id: json['id'] ?? docId,
      mealName: json['mealName'] as String,
      calories: (json['calories'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fats: (json['fats'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      fiber: (json['fiber'] as num? ?? 0).toDouble(),
      date: (json['date'] as Timestamp).toDate(),
    );
  }
}
