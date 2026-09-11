enum EntryType { wake, proteinDrink, proteinBar, meal, exercise, bed }

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
  });

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
    };
  }

  factory TimelineEntry.fromMap(Map<String, dynamic> map) {
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
    );
  }
}
