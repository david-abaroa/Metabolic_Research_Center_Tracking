import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/app_settings.dart';
import '../utils/units.dart';

Future<void> showSettingsSheet(BuildContext context) async {
  final settings = await DatabaseHelper.instance.getSettings();
  var pillTypes = await DatabaseHelper.instance.getPillTypes();
  if (!context.mounted) return;

  final barCalCtrl =
      TextEditingController(text: formatNum(settings.proteinBar.calories));
  final barProteinCtrl =
      TextEditingController(text: formatNum(settings.proteinBar.proteinGrams));
  final drinkCalCtrl =
      TextEditingController(text: formatNum(settings.proteinDrink.calories));
  final drinkProteinCtrl = TextEditingController(
      text: formatNum(settings.proteinDrink.proteinGrams));
  final tirzDoseCtrl =
      TextEditingController(text: formatNum(settings.tirzepatide.dose));
  String tirzUnit = settings.tirzepatide.unit;
  final newPillNameCtrl = TextEditingController();
  final newPillCountCtrl = TextEditingController(text: '2');

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
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
                Text('Tirzepatide', style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Default unit and dose used when you quick-log tirzepatide.',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tirzDoseCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Default dose'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: tirzUnit,
                      items: const [
                        DropdownMenuItem(value: 'mg', child: Text('mg')),
                        DropdownMenuItem(value: 'ml', child: Text('ml')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => tirzUnit = v);
                      },
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
                      tirzepatide: TirzepatideDefaults(
                        unit: tirzUnit,
                        dose: double.tryParse(tirzDoseCtrl.text) ??
                            settings.tirzepatide.dose,
                      ),
                    );
                    await DatabaseHelper.instance.saveSettings(newSettings);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save settings'),
                ),
                const SizedBox(height: 28),
                Text('Pills', style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Pill types you can check off when logging pills, and the '
                  'count you normally take of each.',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                for (final p in pillTypes)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(p.name)),
                        SizedBox(
                          width: 72,
                          child: TextField(
                            controller:
                                TextEditingController(text: '${p.defaultCount}'),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Count'),
                            onChanged: (v) {
                              final count = int.tryParse(v);
                              if (count != null) {
                                DatabaseHelper.instance
                                    .updatePillTypeCount(p.id!, count);
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await DatabaseHelper.instance.deletePillType(p.id!);
                            final updated =
                                await DatabaseHelper.instance.getPillTypes();
                            setState(() => pillTypes = updated);
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: newPillNameCtrl,
                        decoration: const InputDecoration(labelText: 'New pill name'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 72,
                      child: TextField(
                        controller: newPillCountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Count'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () async {
                        final name = newPillNameCtrl.text.trim();
                        final count = int.tryParse(newPillCountCtrl.text) ?? 1;
                        if (name.isEmpty) return;
                        await DatabaseHelper.instance.addPillType(name, count);
                        final updated =
                            await DatabaseHelper.instance.getPillTypes();
                        newPillNameCtrl.clear();
                        newPillCountCtrl.text = '2';
                        setState(() => pillTypes = updated);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      });
    },
  );
}
