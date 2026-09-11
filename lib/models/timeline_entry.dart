enum EntryType { wake, proteinDrink, proteinBar, meal, exercise, bed, water }

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
      waterOz: (map['water_oz'] as num?)?.toDouble(),
      calories: (map['calories'] as num?)?.toDouble(),
    );
  }
}
