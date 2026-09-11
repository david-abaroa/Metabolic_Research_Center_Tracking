import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/timeline_entry.dart';
import '../utils/units.dart';
import 'dual_unit_field.dart';

Future<void> showAddEntrySheet(BuildContext context, VoidCallback onSaved,
    {TimeOfDay? initialTime}) async {
  await showModalBottomSheet(
    context: context,
    builder: (ctx) {
      return SafeArea(
        child: Wrap(
          children: [
            _optionTile(ctx, Icons.wb_sunny, Colors.orange, 'Woke up', () async {
              Navigator.pop(ctx);
              await _quickAdd(context, EntryType.wake, onSaved,
                  initialTime: initialTime);
            }),
            _optionTile(
                ctx, Icons.local_drink, Colors.blue, 'Protein drink', () async {
              Navigator.pop(ctx);
              await _showProteinForm(context, EntryType.proteinDrink, onSaved,
                  initialTime: initialTime);
            }),
            _optionTile(ctx, Icons.icecream, Colors.brown, 'Protein bar', () async {
              Navigator.pop(ctx);
              await _showProteinForm(context, EntryType.proteinBar, onSaved,
                  initialTime: initialTime);
            }),
            _optionTile(ctx, Icons.restaurant, Colors.green, 'Meal', () async {
              Navigator.pop(ctx);
              await _showMealForm(context, onSaved, initialTime: initialTime);
            }),
            _optionTile(
                ctx, Icons.directions_run, Colors.red, 'Exercise', () async {
              Navigator.pop(ctx);
              await _showExerciseForm(context, onSaved, initialTime: initialTime);
            }),
            _optionTile(ctx, Icons.water_drop, Colors.cyan, 'Water', () async {
              Navigator.pop(ctx);
              await _showWaterForm(context, onSaved, initialTime: initialTime);
            }),
            _optionTile(ctx, Icons.bedtime, Colors.indigo, 'Bed time', () async {
              Navigator.pop(ctx);
              await _quickAdd(context, EntryType.bed, onSaved,
                  initialTime: initialTime);
            }),
          ],
        ),
      );
    },
  );
}

/// Opens the right form, pre-filled, to view/edit an existing entry.
Future<void> showEntryDetailSheet(
    BuildContext context, TimelineEntry entry, VoidCallback onSaved) async {
  switch (entry.type) {
    case EntryType.meal:
      await _showMealForm(context, onSaved, existing: entry);
      return;
    case EntryType.exercise:
      await _showExerciseForm(context, onSaved, existing: entry);
      return;
    case EntryType.water:
      await _showWaterForm(context, onSaved, existing: entry);
      return;
    case EntryType.proteinDrink:
    case EntryType.proteinBar:
      await _showProteinForm(context, entry.type, onSaved, existing: entry);
      return;
    case EntryType.wake:
    case EntryType.bed:
      await _showSimpleEditForm(context, entry, onSaved);
      return;
  }
}

Widget _optionTile(
    BuildContext ctx, IconData icon, Color color, String label, VoidCallback onTap) {
  return ListTile(
    leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color)),
    title: Text(label),
    onTap: onTap,
  );
}

Future<TimeOfDay?> _pickTime(BuildContext context, {TimeOfDay? initial}) {
  return showTimePicker(
      context: context, initialTime: initial ?? TimeOfDay.now());
}

DateTime _combineToday(TimeOfDay t, {DateTime? day}) {
  final base = day ?? DateTime.now();
  return DateTime(base.year, base.month, base.day, t.hour, t.minute);
}

Future<void> _deleteAndClose(
    BuildContext sheetCtx, int id, VoidCallback onSaved) async {
  await DatabaseHelper.instance.deleteEntry(id);
  onSaved();
  Navigator.pop(sheetCtx);
}

Future<void> _quickAdd(
    BuildContext context, EntryType type, VoidCallback onSaved,
    {TimeOfDay? initialTime}) async {
  final time = await _pickTime(context, initial: initialTime);
  if (time == null) return;
  final entry = TimelineEntry(type: type, timestamp: _combineToday(time));
  await DatabaseHelper.instance.insertEntry(entry);
  onSaved();
}

/// Time-only edit sheet for wake / bed time.
Future<void> _showSimpleEditForm(
    BuildContext context, TimelineEntry entry, VoidCallback onSaved) async {
  TimeOfDay time = TimeOfDay.fromDateTime(entry.timestamp);
  await showModalBottomSheet(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Edit entry', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Time: ${time.format(ctx)}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final t = await _pickTime(context, initial: time);
                    if (t != null) setState(() => time = t);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                        onPressed: () =>
                            _deleteAndClose(ctx, entry.id!, onSaved),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          await DatabaseHelper.instance.updateEntry(
                            entry.copyWith(timestamp: _combineToday(time)),
                          );
                          onSaved();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Save'),
                      ),
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

/// Add/edit sheet for protein bar & protein drink — pre-filled from the
/// user's saved defaults (see Settings), with a "Change values" toggle to
/// override calories/protein for just this entry.
Future<void> _showProteinForm(
    BuildContext context, EntryType type, VoidCallback onSaved,
    {TimelineEntry? existing, TimeOfDay? initialTime}) async {
  final settings = await DatabaseHelper.instance.getSettings();
  final defaults =
      type == EntryType.proteinBar ? settings.proteinBar : settings.proteinDrink;
  final label = type == EntryType.proteinBar ? 'Protein bar' : 'Protein drink';

  if (!context.mounted) return;

  TimeOfDay time = existing != null
      ? TimeOfDay.fromDateTime(existing.timestamp)
      : (initialTime ?? TimeOfDay.now());
  double proteinGrams = existing?.proteinGrams ?? defaults.proteinGrams;
  double calories = existing?.calories ?? defaults.calories;
  bool customizing = existing != null &&
      (existing.proteinGrams != defaults.proteinGrams ||
          existing.calories != defaults.calories);
  final caloriesCtrl = TextEditingController(text: formatNum(calories));

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(existing == null ? 'Add $label' : 'Edit $label',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Time: ${time.format(ctx)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final t = await _pickTime(context, initial: time);
                  if (t != null) setState(() => time = t);
                },
              ),
              const SizedBox(height: 8),
              if (!customizing) ...[
                Text(
                  '${formatNum(proteinGrams)}g protein • ${formatNum(calories)} kcal (default)',
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.tune),
                    label: const Text('Change values'),
                    onPressed: () => setState(() => customizing = true),
                  ),
                ),
              ] else ...[
                DualUnitField(
                  label: 'Protein',
                  initialGrams: proteinGrams,
                  onGramsChanged: (g) => proteinGrams = g ?? 0,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: caloriesCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Calories (kcal)'),
                  onChanged: (v) => calories = double.tryParse(v) ?? calories,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() {
                      customizing = false;
                      proteinGrams = defaults.proteinGrams;
                      calories = defaults.calories;
                      caloriesCtrl.text = formatNum(calories);
                    }),
                    child: const Text('Reset to default'),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (existing != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                        onPressed: () =>
                            _deleteAndClose(ctx, existing.id!, onSaved),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final entry = TimelineEntry(
                          id: existing?.id,
                          type: type,
                          timestamp: _combineToday(time),
                          proteinGrams: proteinGrams,
                          calories: calories,
                        );
                        if (existing == null) {
                          await DatabaseHelper.instance.insertEntry(entry);
                        } else {
                          await DatabaseHelper.instance.updateEntry(entry);
                        }
                        onSaved();
                        Navigator.pop(ctx);
                      },
                      child: Text('Save $label'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      });
    },
  );
}

Future<void> _showWaterForm(BuildContext context, VoidCallback onSaved,
    {TimelineEntry? existing, TimeOfDay? initialTime}) async {
  TimeOfDay time = existing != null
      ? TimeOfDay.fromDateTime(existing.timestamp)
      : (initialTime ?? TimeOfDay.now());
  final ozCtrl = TextEditingController(
      text: existing?.waterOz != null ? existing!.waterOz!.toStringAsFixed(1) : '');

  Future<void> save(double? oz) async {
    if (oz == null || oz <= 0) return;
    if (existing == null) {
      await DatabaseHelper.instance.insertEntry(
        TimelineEntry(
          type: EntryType.water,
          timestamp: _combineToday(time),
          waterOz: oz,
        ),
      );
    } else {
      await DatabaseHelper.instance.updateEntry(
        existing.copyWith(timestamp: _combineToday(time), waterOz: oz),
      );
    }
    onSaved();
  }

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(existing == null ? 'Add water' : 'Edit water',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Time: ${time.format(ctx)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final t = await _pickTime(context, initial: time);
                  if (t != null) setState(() => time = t);
                },
              ),
              if (existing == null) ...[
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.local_drink),
                  label: Text('Quick bottle (${waterBottleOz.toStringAsFixed(1)} fl oz)'),
                  onPressed: () async {
                    await save(waterBottleOz);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 8),
                const Text('— or enter a custom amount —',
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
              ] else
                const SizedBox(height: 12),
              TextField(
                controller: ozCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Fluid ounces'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (existing != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                        onPressed: () =>
                            _deleteAndClose(ctx, existing.id!, onSaved),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        await save(double.tryParse(ozCtrl.text));
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      });
    },
  );
}

Future<void> _showMealForm(BuildContext context, VoidCallback onSaved,
    {TimelineEntry? existing, TimeOfDay? initialTime}) async {
  final proteinOptions = await DatabaseHelper.instance.proteinOptions();
  final veggieOptions = await DatabaseHelper.instance.veggieOptions();
  TimeOfDay time = existing != null
      ? TimeOfDay.fromDateTime(existing.timestamp)
      : (initialTime ?? TimeOfDay.now());
  String? protein = existing?.proteinName;
  String? veggie = existing?.veggieName;
  double? proteinGrams = existing?.proteinGrams;
  double? veggieGrams = existing?.veggieGrams;
  final newProteinCtrl = TextEditingController();
  final newVeggieCtrl = TextEditingController();
  bool addingNewProtein = existing != null &&
      existing.proteinName != null &&
      !proteinOptions.contains(existing.proteinName);
  bool addingNewVeggie = existing != null &&
      existing.veggieName != null &&
      !veggieOptions.contains(existing.veggieName);
  if (addingNewProtein) newProteinCtrl.text = existing.proteinName ?? '';
  if (addingNewVeggie) newVeggieCtrl.text = existing.veggieName ?? '';

  if (!context.mounted) return;
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(existing == null ? 'Add meal' : 'Edit meal',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Time: ${time.format(ctx)}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final t = await _pickTime(context, initial: time);
                    if (t != null) setState(() => time = t);
                  },
                ),
                const SizedBox(height: 8),
                if (!addingNewProtein)
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Protein source'),
                    value: protein,
                    items: [
                      ...proteinOptions
                          .map((p) => DropdownMenuItem(value: p, child: Text(p))),
                      const DropdownMenuItem(
                          value: '__new__', child: Text('+ Add new...')),
                    ],
                    onChanged: (v) {
                      if (v == '__new__') {
                        setState(() => addingNewProtein = true);
                      } else {
                        setState(() => protein = v);
                      }
                    },
                  )
                else
                  TextField(
                    controller: newProteinCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'New protein name',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => addingNewProtein = false),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                DualUnitField(
                  label: 'Protein',
                  initialGrams: proteinGrams,
                  onGramsChanged: (g) => proteinGrams = g,
                ),
                const SizedBox(height: 16),
                if (!addingNewVeggie)
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Veggie'),
                    value: veggie,
                    items: [
                      ...veggieOptions
                          .map((v) => DropdownMenuItem(value: v, child: Text(v))),
                      const DropdownMenuItem(
                          value: '__new__', child: Text('+ Add new...')),
                    ],
                    onChanged: (v) {
                      if (v == '__new__') {
                        setState(() => addingNewVeggie = true);
                      } else {
                        setState(() => veggie = v);
                      }
                    },
                  )
                else
                  TextField(
                    controller: newVeggieCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'New veggie name',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => addingNewVeggie = false),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                DualUnitField(
                  label: 'Veggies',
                  initialGrams: veggieGrams,
                  onGramsChanged: (g) => veggieGrams = g,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (existing != null) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                          onPressed: () =>
                              _deleteAndClose(ctx, existing.id!, onSaved),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          final proteinName = addingNewProtein
                              ? newProteinCtrl.text.trim()
                              : protein;
                          final veggieName =
                              addingNewVeggie ? newVeggieCtrl.text.trim() : veggie;
                          if (proteinName != null && proteinName.isNotEmpty) {
                            await DatabaseHelper.instance
                                .addProteinOption(proteinName);
                          }
                          if (veggieName != null && veggieName.isNotEmpty) {
                            await DatabaseHelper.instance
                                .addVeggieOption(veggieName);
                          }
                          final entry = TimelineEntry(
                            id: existing?.id,
                            type: EntryType.meal,
                            timestamp: _combineToday(time),
                            proteinName: (proteinName?.isNotEmpty ?? false)
                                ? proteinName
                                : null,
                            proteinGrams: proteinGrams,
                            veggieName: (veggieName?.isNotEmpty ?? false)
                                ? veggieName
                                : null,
                            veggieGrams: veggieGrams,
                          );
                          if (existing == null) {
                            await DatabaseHelper.instance.insertEntry(entry);
                          } else {
                            await DatabaseHelper.instance.updateEntry(entry);
                          }
                          onSaved();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Save meal'),
                      ),
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

Future<void> _showExerciseForm(BuildContext context, VoidCallback onSaved,
    {TimelineEntry? existing, TimeOfDay? initialTime}) async {
  TimeOfDay time = existing != null
      ? TimeOfDay.fromDateTime(existing.timestamp)
      : (initialTime ?? TimeOfDay.now());
  final descCtrl = TextEditingController(text: existing?.exerciseDescription ?? '');
  final minutesCtrl =
      TextEditingController(text: existing?.exerciseMinutes?.toString() ?? '');

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(existing == null ? 'Add exercise' : 'Edit exercise',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Time: ${time.format(ctx)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final t = await _pickTime(context, initial: time);
                  if (t != null) setState(() => time = t);
                },
              ),
              TextField(
                controller: descCtrl,
                decoration:
                    const InputDecoration(labelText: 'Description (e.g. Run, Lift)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: minutesCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Duration (minutes)'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (existing != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                        onPressed: () =>
                            _deleteAndClose(ctx, existing.id!, onSaved),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final entry = TimelineEntry(
                          id: existing?.id,
                          type: EntryType.exercise,
                          timestamp: _combineToday(time),
                          exerciseDescription: descCtrl.text.trim().isEmpty
                              ? null
                              : descCtrl.text.trim(),
                          exerciseMinutes: int.tryParse(minutesCtrl.text),
                        );
                        if (existing == null) {
                          await DatabaseHelper.instance.insertEntry(entry);
                        } else {
                          await DatabaseHelper.instance.updateEntry(entry);
                        }
                        onSaved();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Save exercise'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      });
    },
  );
}
