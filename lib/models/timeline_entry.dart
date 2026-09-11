import 'dart:convert';
import 'pill_type.dart';

enum EntryType {
  wake,
  proteinDrink,
  proteinBar,
  meal,
  exercise,
  bed,
  water,
  tirzepatide,
  pills,
  gac,
}

class TimelineEntry {
  final int? id;
  final EntryType type;
  final DateTime timestamp;

  // Meal-specific
  final String? proteinName;
  final double? proteinGrams;
  final String? veggieName;
  final double? veggieGrams;

  // Exercise-specific
  final String? exerciseDescription;
  final int? exerciseMinutes;

  // Water-specific
  final double? waterOz;

  // Protein bar / protein drink specific (defaults come from AppSettings,
  // but can be overridden per entry)
  final double? calories;

  // Tirzepatide-specific
  final double? tirzepatideDose;
  final String? tirzepatideUnit; // 'mg' or 'ml'

  // Pills-specific
  final List<PillDose>? pills;

  // GAC-specific
  final double? gacMl;

  TimelineEntry({
    this.id,
    required this.type,
    required this.timestamp,
    this.proteinName,
    this.proteinGrams,
    this.veggieName,
    this.veggieGrams,
    this.exerciseDescription,
    this.exerciseMinutes,
    this.waterOz,
    this.calories,
    this.tirzepatideDose,
    this.tirzepatideUnit,
    this.pills,
    this.gacMl,
  });

  /// True for entry types after which there's an optimal 3-4hr window to
  /// have a follow-up meal or protein.
  bool get startsOptimalWindow =>
      type == EntryType.meal ||
      type == EntryType.proteinDrink ||
      type == EntryType.proteinBar;

  TimelineEntry copyWith({
    int? id,
    EntryType? type,
    DateTime? timestamp,
    String? proteinName,
    double? proteinGrams,
    String? veggieName,
    double? veggieGrams,
    String? exerciseDescription,
    int? exerciseMinutes,
    double? waterOz,
    double? calories,
    double? tirzepatideDose,
    String? tirzepatideUnit,
    List<PillDose>? pills,
    double? gacMl,
  }) {
    return TimelineEntry(
      id: id ?? this.id,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      proteinName: proteinName ?? this.proteinName,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      veggieName: veggieName ?? this.veggieName,
      veggieGrams: veggieGrams ?? this.veggieGrams,
      exerciseDescription: exerciseDescription ?? this.exerciseDescription,
      exerciseMinutes: exerciseMinutes ?? this.exerciseMinutes,
      waterOz: waterOz ?? this.waterOz,
      calories: calories ?? this.calories,
      tirzepatideDose: tirzepatideDose ?? this.tirzepatideDose,
      tirzepatideUnit: tirzepatideUnit ?? this.tirzepatideUnit,
      pills: pills ?? this.pills,
      gacMl: gacMl ?? this.gacMl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'protein_name': proteinName,
      'protein_grams': proteinGrams,
      'veggie_name': veggieName,
      'veggie_grams': veggieGrams,
      'exercise_description': exerciseDescription,
      'exercise_minutes': exerciseMinutes,
      'water_oz': waterOz,
      'calories': calories,
      'tirzepatide_dose': tirzepatideDose,
      'tirzepatide_unit': tirzepatideUnit,
      'pills_json': pills == null
          ? null
          : jsonEncode(pills!.map((p) => p.toJson()).toList()),
      'gac_ml': gacMl,
    };
  }

  factory TimelineEntry.fromMap(Map<String, dynamic> map) {
    final pillsJson = map['pills_json'] as String?;
    return TimelineEntry(
      id: map['id'] as int?,
      type: EntryType.values.firstWhere((e) => e.name == map['type']),
      timestamp: DateTime.parse(map['timestamp'] as String),
      proteinName: map['protein_name'] as String?,
      proteinGrams: (map['protein_grams'] as num?)?.toDouble(),
      veggieName: map['veggie_name'] as String?,
      veggieGrams: (map['veggie_grams'] as num?)?.toDouble(),
      exerciseDescription: map['exercise_description'] as String?,
      exerciseMinutes: map['exercise_minutes'] as int?,
      waterOz: (map['water_oz'] as num?)?.toDouble(),
      calories: (map['calories'] as num?)?.toDouble(),
      tirzepatideDose: (map['tirzepatide_dose'] as num?)?.toDouble(),
      tirzepatideUnit: map['tirzepatide_unit'] as String?,
      pills: pillsJson == null
          ? null
          : (jsonDecode(pillsJson) as List)
              .map((e) => PillDose.fromJson(e as Map<String, dynamic>))
              .toList(),
      gacMl: (map['gac_ml'] as num?)?.toDouble(),
    );
  }
}
