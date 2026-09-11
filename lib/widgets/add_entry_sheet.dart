import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/timeline_entry.dart';

Future<void> showAddEntrySheet(BuildContext context, VoidCallback onSaved) async {
  await showModalBottomSheet(
    context: context,
    builder: (ctx) {
      return SafeArea(
        child: Wrap(
          children: [
            _optionTile(ctx, Icons.wb_sunny, Colors.orange, 'Woke up', () async {
              Navigator.pop(ctx);
              await _quickAdd(context, EntryType.wake, onSaved);
            }),
            _optionTile(
                ctx, Icons.local_drink, Colors.blue, 'Protein drink', () async {
              Navigator.pop(ctx);
              await _quickAdd(context, EntryType.proteinDrink, onSaved);
            }),
            _optionTile(ctx, Icons.icecream, Colors.brown, 'Protein bar', () async {
              Navigator.pop(ctx);
              await _quickAdd(context, EntryType.proteinBar, onSaved);
            }),
            _optionTile(ctx, Icons.restaurant, Colors.green, 'Meal', () async {
              Navigator.pop(ctx);
              await _showMealForm(context, onSaved);
            }),
            _optionTile(
                ctx, Icons.directions_run, Colors.red, 'Exercise', () async {
              Navigator.pop(ctx);
              await _showExerciseForm(context, onSaved);
            }),
            _optionTile(ctx, Icons.bedtime, Colors.indigo, 'Bed time', () async {
              Navigator.pop(ctx);
              await _quickAdd(context, EntryType.bed, onSaved);
            }),
          ],
        ),
      );
    },
  );
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

Future<TimeOfDay?> _pickTime(BuildContext context) {
  final now = TimeOfDay.now();
  return showTimePicker(context: context, initialTime: now);
}

DateTime _combineToday(TimeOfDay t) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, t.hour, t.minute);
}

Future<void> _quickAdd(
    BuildContext context, EntryType type, VoidCallback onSaved) async {
  final time = await _pickTime(context);
  if (time == null) return;
  final entry = TimelineEntry(type: type, timestamp: _combineToday(time));
  await DatabaseHelper.instance.insertEntry(entry);
  onSaved();
}

Future<void> _showMealForm(BuildContext context, VoidCallback onSaved) async {
  final proteinOptions = await DatabaseHelper.instance.proteinOptions();
  final veggieOptions = await DatabaseHelper.instance.veggieOptions();
  TimeOfDay time = TimeOfDay.now();
  String? protein;
  String? veggie;
  final proteinGramsCtrl = TextEditingController();
  final veggieGramsCtrl = TextEditingController();
  final newProteinCtrl = TextEditingController();
  final newVeggieCtrl = TextEditingController();
  bool addingNewProtein = false;
  bool addingNewVeggie = false;

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
                Text('Add meal', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Time: ${time.format(ctx)}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final t = await _pickTime(context);
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
                TextField(
                  controller: proteinGramsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Protein grams'),
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
                TextField(
                  controller: veggieGramsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Veggie grams'),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    final proteinName =
                        addingNewProtein ? newProteinCtrl.text.trim() : protein;
                    final veggieName =
                        addingNewVeggie ? newVeggieCtrl.text.trim() : veggie;
                    if (proteinName != null && proteinName.isNotEmpty) {
                      await DatabaseHelper.instance.addProteinOption(proteinName);
                    }
                    if (veggieName != null && veggieName.isNotEmpty) {
                      await DatabaseHelper.instance.addVeggieOption(veggieName);
                    }
                    final entry = TimelineEntry(
                      type: EntryType.meal,
                      timestamp: _combineToday(time),
                      proteinName:
                          (proteinName?.isNotEmpty ?? false) ? proteinName : null,
                      proteinGrams: double.tryParse(proteinGramsCtrl.text),
                      veggieName:
                          (veggieName?.isNotEmpty ?? false) ? veggieName : null,
                      veggieGrams: double.tryParse(veggieGramsCtrl.text),
                    );
                    await DatabaseHelper.instance.insertEntry(entry);
                    onSaved();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save meal'),
                ),
              ],
            ),
          ),
        );
      });
    },
  );
}

Future<void> _showExerciseForm(BuildContext context, VoidCallback onSaved) async {
  TimeOfDay time = TimeOfDay.now();
  final descCtrl = TextEditingController();
  final minutesCtrl = TextEditingController();

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
              Text('Add exercise', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Time: ${time.format(ctx)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final t = await _pickTime(context);
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
              FilledButton(
                onPressed: () async {
                  final entry = TimelineEntry(
                    type: EntryType.exercise,
                    timestamp: _combineToday(time),
                    exerciseDescription:
                        descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    exerciseMinutes: int.tryParse(minutesCtrl.text),
                  );
                  await DatabaseHelper.instance.insertEntry(entry);
                  onSaved();
                  Navigator.pop(ctx);
                },
                child: const Text('Save exercise'),
              ),
            ],
          ),
        );
      });
    },
  );
}
