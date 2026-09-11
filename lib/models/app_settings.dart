class ProteinDefaults {
  final double calories;
  final double proteinGrams;

  const ProteinDefaults({required this.calories, required this.proteinGrams});
}

class AppSettings {
  final ProteinDefaults proteinBar;
  final ProteinDefaults proteinDrink;

  const AppSettings({required this.proteinBar, required this.proteinDrink});

  static const defaults = AppSettings(
    proteinBar: ProteinDefaults(calories: 200, proteinGrams: 20),
    proteinDrink: ProteinDefaults(calories: 160, proteinGrams: 25),
  );
}
