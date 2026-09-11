const double gramsPerOunce = 28.3495;

double ozToGrams(double oz) => oz * gramsPerOunce;

double gramsToOz(double grams) => grams / gramsPerOunce;

const double waterBottleOz = 16.9;

/// Rough macro-based estimate — this app has no food database, so this is a
/// ballpark, not a precise calorie count.
const double proteinKcalPerGram = 4.0;
const double veggieKcalPerGram = 0.3;

double estimateMealCalories({double? proteinGrams, double? veggieGrams}) {
  return (proteinGrams ?? 0) * proteinKcalPerGram +
      (veggieGrams ?? 0) * veggieKcalPerGram;
}
