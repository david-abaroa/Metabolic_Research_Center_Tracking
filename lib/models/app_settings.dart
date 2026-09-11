class ProteinDefaults {
  final double calories;
  final double proteinGrams;

  const ProteinDefaults({required this.calories, required this.proteinGrams});
}

/// 'mg' or 'ml' — which unit tirzepatide doses are entered/displayed in.
/// There's no fixed conversion between the two (it depends on the
/// compounded concentration), so this only picks the default unit; it does
/// not convert existing values.
class TirzepatideDefaults {
  final String unit;
  final double dose;

  const TirzepatideDefaults({required this.unit, required this.dose});
}

class AppSettings {
  final ProteinDefaults proteinBar;
  final ProteinDefaults proteinDrink;
  final TirzepatideDefaults tirzepatide;
  final double gacDefaultMl;

  const AppSettings({
    required this.proteinBar,
    required this.proteinDrink,
    required this.tirzepatide,
    required this.gacDefaultMl,
  });

  static const defaults = AppSettings(
    proteinBar: ProteinDefaults(calories: 200, proteinGrams: 20),
    proteinDrink: ProteinDefaults(calories: 160, proteinGrams: 25),
    tirzepatide: TirzepatideDefaults(unit: 'mg', dose: 3),
    gacDefaultMl: 100,
  );
}
