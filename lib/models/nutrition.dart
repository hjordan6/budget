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
  final String? score;
  final String? breakdown;
  final double? volumePoints;
  final double? netCarbs;
  final double? addedSugar;
  final double? sodium;
  final String? fiberLight;
  final String? sugarLight;
  final String? fatLight;
  final String? counterBalanceTip;

  NutritionEntry({
    String? id,
    required this.mealName,
    required this.calories,
    required this.carbs,
    required this.fats,
    required this.protein,
    this.fiber = 0,
    required this.date,
    this.score,
    this.breakdown,
    this.volumePoints,
    this.netCarbs,
    this.addedSugar,
    this.sodium,
    this.fiberLight,
    this.sugarLight,
    this.fatLight,
    this.counterBalanceTip,
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
      if (score != null) 'score': score,
      if (breakdown != null) 'breakdown': breakdown,
      if (volumePoints != null) 'volumePoints': volumePoints,
      if (netCarbs != null) 'netCarbs': netCarbs,
      if (addedSugar != null) 'addedSugar': addedSugar,
      if (sodium != null) 'sodium': sodium,
      if (fiberLight != null) 'fiberLight': fiberLight,
      if (sugarLight != null) 'sugarLight': sugarLight,
      if (fatLight != null) 'fatLight': fatLight,
      if (counterBalanceTip != null) 'counterBalanceTip': counterBalanceTip,
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
      score: json['score'] as String?,
      breakdown: json['breakdown'] as String?,
      volumePoints: (json['volumePoints'] as num?)?.toDouble(),
      netCarbs: (json['netCarbs'] as num?)?.toDouble(),
      addedSugar: (json['addedSugar'] as num?)?.toDouble(),
      sodium: (json['sodium'] as num?)?.toDouble(),
      fiberLight: json['fiberLight'] as String?,
      sugarLight: json['sugarLight'] as String?,
      fatLight: json['fatLight'] as String?,
      counterBalanceTip: json['counterBalanceTip'] as String?,
    );
  }
}
