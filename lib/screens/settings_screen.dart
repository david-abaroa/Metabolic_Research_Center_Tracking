import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/app_settings.dart';
import '../utils/units.dart';

Future<void> showSettingsSheet(BuildContext context) async {
  final settings = await DatabaseHelper.instance.getSettings();
  if (!context.mounted) return;

  final barCalCtrl =
      TextEditingController(text: formatNum(settings.proteinBar.calories));
  final barProteinCtrl =
      TextEditingController(text: formatNum(settings.proteinBar.proteinGrams));
  final drinkCalCtrl =
      TextEditingController(text: formatNum(settings.proteinDrink.calories));
  final drinkProteinCtrl = TextEditingController(
      text: formatNum(settings.proteinDrink.proteinGrams));

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Settings', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Default values used when you quick-log a protein bar or '
                'drink. You can still override them per entry.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              Text('Protein bar', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: barCalCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Calories (kcal)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: barProteinCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Protein (g)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Protein drink', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: drinkCalCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Calories (kcal)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: drinkProteinCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Protein (g)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  final newSettings = AppSettings(
                    proteinBar: ProteinDefaults(
                      calories: double.tryParse(barCalCtrl.text) ??
                          settings.proteinBar.calories,
                      proteinGrams: double.tryParse(barProteinCtrl.text) ??
                          settings.proteinBar.proteinGrams,
                    ),
                    proteinDrink: ProteinDefaults(
                      calories: double.tryParse(drinkCalCtrl.text) ??
                          settings.proteinDrink.calories,
                      proteinGrams: double.tryParse(drinkProteinCtrl.text) ??
                          settings.proteinDrink.proteinGrams,
                    ),
                  );
                  await DatabaseHelper.instance.saveSettings(newSettings);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save settings'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
