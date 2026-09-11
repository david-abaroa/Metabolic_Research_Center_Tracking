import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/timeline_entry.dart';
import '../utils/units.dart';

class DaySummary {
  final int mealCount;
  final double totalProteinGrams;
  final double totalVeggieGrams;
  final double totalWaterOz;
  final int totalExerciseMinutes;
  final Duration? sleepDuration;
  final double estimatedCalories;

  DaySummary({
    required this.mealCount,
    required this.totalProteinGrams,
    required this.totalVeggieGrams,
    required this.totalWaterOz,
    required this.totalExerciseMinutes,
    required this.sleepDuration,
    required this.estimatedCalories,
  });

  static Future<DaySummary> compute(List<TimelineEntry> entries) async {
    int mealCount = 0;
    double protein = 0;
    double veggie = 0;
    double water = 0;
    int exerciseMinutes = 0;
    double calories = 0;
    TimelineEntry? wake;

    for (final e in entries) {
      switch (e.type) {
        case EntryType.meal:
          mealCount++;
          protein += e.proteinGrams ?? 0;
          veggie += e.veggieGrams ?? 0;
          calories += estimateMealCalories(
              proteinGrams: e.proteinGrams, veggieGrams: e.veggieGrams);
          break;
        case EntryType.proteinDrink:
        case EntryType.proteinBar:
          protein += e.proteinGrams ?? 0;
          calories += e.calories ?? 0;
          break;
        case EntryType.water:
          water += e.waterOz ?? 0;
          break;
        case EntryType.exercise:
          exerciseMinutes += e.exerciseMinutes ?? 0;
          break;
        case EntryType.wake:
          wake ??= e;
          break;
        default:
          break;
      }
    }

    Duration? sleep;
    if (wake != null) {
      final bed = await DatabaseHelper.instance.mostRecentBedBefore(wake.timestamp);
      if (bed != null) {
        sleep = wake.timestamp.difference(bed.timestamp);
      }
    }

    return DaySummary(
      mealCount: mealCount,
      totalProteinGrams: protein,
      totalVeggieGrams: veggie,
      totalWaterOz: water,
      totalExerciseMinutes: exerciseMinutes,
      sleepDuration: sleep,
      estimatedCalories: calories,
    );
  }
}

Future<void> showDaySummarySheet(
    BuildContext context, DateTime day, List<TimelineEntry> entries) async {
  final summary = await DaySummary.compute(entries);
  if (!context.mounted) return;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Summary — ${DateFormat('EEEE, MMM d').format(day)}',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              _statRow(ctx, Icons.restaurant, 'Meals logged',
                  '${summary.mealCount}'),
              _statRow(ctx, Icons.local_fire_department, 'Estimated calories',
                  '~${summary.estimatedCalories.toStringAsFixed(0)} kcal'),
              _statRow(
                  ctx,
                  Icons.egg_alt,
                  'Total protein',
                  '${summary.totalProteinGrams.toStringAsFixed(0)}g '
                      '(${gramsToOz(summary.totalProteinGrams).toStringAsFixed(1)} oz)'),
              _statRow(
                  ctx,
                  Icons.eco,
                  'Total veggies',
                  '${summary.totalVeggieGrams.toStringAsFixed(0)}g '
                      '(${gramsToOz(summary.totalVeggieGrams).toStringAsFixed(1)} oz)'),
              _statRow(ctx, Icons.water_drop, 'Water',
                  '${summary.totalWaterOz.toStringAsFixed(1)} fl oz'),
              _statRow(ctx, Icons.directions_run, 'Exercise',
                  '${summary.totalExerciseMinutes} min'),
              _statRow(
                  ctx,
                  Icons.bedtime,
                  'Sleep',
                  summary.sleepDuration == null
                      ? '—'
                      : _formatDuration(summary.sleepDuration!)),
              const SizedBox(height: 12),
              Text(
                'Estimated calories: meals use a rough guide from logged '
                'protein/veggie weight (protein ~4 kcal/g, veggies ~0.3 '
                'kcal/g); protein bars/drinks use their default or '
                'overridden calorie value. Not a precise food-database count.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    },
  );
}

String _formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  return '${h}h ${m}m';
}

Widget _statRow(BuildContext context, IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
