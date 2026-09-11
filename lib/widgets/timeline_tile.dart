import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/timeline_entry.dart';

class EntryStyle {
  final IconData icon;
  final Color color;
  final String label;
  const EntryStyle(this.icon, this.color, this.label);
}

const Map<EntryType, EntryStyle> entryStyles = {
  EntryType.wake: EntryStyle(Icons.wb_sunny, Colors.orange, 'Woke up'),
  EntryType.proteinDrink:
      EntryStyle(Icons.local_drink, Colors.blue, 'Protein drink'),
  EntryType.proteinBar: EntryStyle(Icons.icecream, Colors.brown, 'Protein bar'),
  EntryType.meal: EntryStyle(Icons.restaurant, Colors.green, 'Meal'),
  EntryType.exercise:
      EntryStyle(Icons.directions_run, Colors.red, 'Exercise'),
  EntryType.bed: EntryStyle(Icons.bedtime, Colors.indigo, 'Bed time'),
  EntryType.water: EntryStyle(Icons.water_drop, Colors.cyan, 'Water'),
  EntryType.tirzepatide:
      EntryStyle(Icons.vaccines, Colors.deepPurple, 'Tirzepatide'),
  EntryType.pills: EntryStyle(Icons.medication, Colors.pink, 'Pills'),
};

String entrySubtitle(TimelineEntry entry) {
  switch (entry.type) {
    case EntryType.proteinDrink:
    case EntryType.proteinBar:
      final parts = <String>[];
      if (entry.proteinGrams != null) {
        parts.add('${entry.proteinGrams!.toStringAsFixed(0)}g protein');
      }
      if (entry.calories != null) {
        parts.add('${entry.calories!.toStringAsFixed(0)} kcal');
      }
      return parts.join(' • ');
    case EntryType.meal:
      final parts = <String>[];
      if (entry.proteinName != null) {
        final g = entry.proteinGrams?.toStringAsFixed(0) ?? '?';
        parts.add('${entry.proteinName} • ${g}g protein');
      }
      if (entry.veggieName != null) {
        final g = entry.veggieGrams?.toStringAsFixed(0) ?? '?';
        parts.add('${entry.veggieName} • ${g}g veggies');
      }
      return parts.join('\n');
    case EntryType.exercise:
      final desc = entry.exerciseDescription ?? '';
      final mins = entry.exerciseMinutes ?? 0;
      return '$desc • $mins min';
    case EntryType.water:
      final oz = entry.waterOz?.toStringAsFixed(1) ?? '?';
      return '$oz fl oz';
    case EntryType.tirzepatide:
      final dose = entry.tirzepatideDose?.toStringAsFixed(2) ?? '?';
      return '$dose ${entry.tirzepatideUnit ?? 'mg'}';
    case EntryType.pills:
      if (entry.pills == null || entry.pills!.isEmpty) return 'None taken';
      return entry.pills!.map((p) => '${p.count} ${p.name}').join(', ');
    default:
      return '';
  }
}

class TimelineTile extends StatelessWidget {
  final TimelineEntry entry;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const TimelineTile({
    super.key,
    required this.entry,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = entryStyles[entry.type]!;
    final subtitle = entrySubtitle(entry);
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade100,
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      onDismissed: (_) => onDelete(),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 1,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          dense: true,
          leading: CircleAvatar(
            backgroundColor: style.color.withOpacity(0.15),
            child: Icon(style.icon, color: style.color),
          ),
          title: Text(style.label),
          subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
          trailing: Text(DateFormat('h:mm a').format(entry.timestamp)),
        ),
      ),
    );
  }
}
