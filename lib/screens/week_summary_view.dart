import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../widgets/tirz_gac_badge.dart';
import 'summary_screen.dart';

/// A 7-day breakdown (Monday-start week), plus a totals card for the week
/// as a whole. Tapping a day switches back to the day view for that date.
class WeekSummaryView extends StatefulWidget {
  final DateTime weekStart;
  final ValueChanged<DateTime> onDayTap;

  const WeekSummaryView({
    super.key,
    required this.weekStart,
    required this.onDayTap,
  });

  @override
  State<WeekSummaryView> createState() => _WeekSummaryViewState();
}

class _WeekSummaryViewState extends State<WeekSummaryView> {
  bool _loading = true;
  List<DateTime> _days = [];
  List<DaySummary> _summaries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant WeekSummaryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weekStart != widget.weekStart) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final days =
        List.generate(7, (i) => widget.weekStart.add(Duration(days: i)));
    final summaries = <DaySummary>[];
    for (final d in days) {
      final entries = await DatabaseHelper.instance.entriesForDay(d);
      summaries.add(await DaySummary.compute(entries));
    }
    if (!mounted) return;
    setState(() {
      _days = days;
      _summaries = summaries;
      _loading = false;
    });
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _weekTotalCard(context),
        const SizedBox(height: 16),
        for (int i = 0; i < _days.length; i++)
          _dayCard(context, _days[i], _summaries[i], _isToday(_days[i])),
      ],
    );
  }

  Widget _weekTotalCard(BuildContext context) {
    int totalMeals = 0, totalBarsDrinks = 0, totalPills = 0;
    int tirzDays = 0, gacDays = 0;
    double totalCal = 0, totalWater = 0, totalProtein = 0, totalVeggie = 0;
    for (final s in _summaries) {
      totalMeals += s.mealCount;
      totalBarsDrinks += s.proteinBarDrinkCount;
      totalCal += s.estimatedCalories;
      totalWater += s.totalWaterOz;
      totalProtein += s.totalProteinGrams;
      totalVeggie += s.totalVeggieGrams;
      totalPills += s.pillCount;
      if (s.tookTirzepatide) tirzDays++;
      if (s.tookGac) gacDays++;
    }
    final label = _days.isEmpty
        ? ''
        : '${DateFormat('MMM d').format(_days.first)} – '
            '${DateFormat('MMM d').format(_days.last)}';

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Week of $label',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            statRow(context, Icons.restaurant, 'Meals logged', '$totalMeals'),
            statRow(context, Icons.local_drink, 'Protein drinks/bars',
                '$totalBarsDrinks'),
            statRow(context, Icons.local_fire_department, 'Total calories',
                '~${totalCal.toStringAsFixed(0)} kcal'),
            statRow(context, Icons.water_drop, 'Total water',
                '${totalWater.toStringAsFixed(0)} fl oz'),
            statRow(context, Icons.egg_alt, 'Total protein',
                '${totalProtein.toStringAsFixed(0)}g'),
            statRow(context, Icons.eco, 'Total veggies',
                '${totalVeggie.toStringAsFixed(0)}g'),
            statRow(context, Icons.medication, 'Total pills', '$totalPills'),
            statRow(context, Icons.star, 'Tirzepatide days', '$tirzDays / 7'),
            statRow(context, Icons.circle_outlined, 'GAC days', '$gacDays / 7'),
          ],
        ),
      ),
    );
  }

  Widget _dayCard(
      BuildContext context, DateTime day, DaySummary s, bool isToday) {
    final label = DateFormat('EEE, MMM d').format(day);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => widget.onDayTap(day),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 6),
                    Text('(today)',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                  const Spacer(),
                  TirzGacBadge(
                      tookTirzepatide: s.tookTirzepatide, tookGac: s.tookGac),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 4,
                children: [
                  _mini(Icons.local_drink,
                      '${s.proteinBarDrinkCount} drinks/bars'),
                  _mini(Icons.local_fire_department,
                      '${s.estimatedCalories.toStringAsFixed(0)} kcal'),
                  _mini(Icons.water_drop,
                      '${s.totalWaterOz.toStringAsFixed(0)} oz'),
                  _mini(Icons.egg_alt,
                      '${s.totalProteinGrams.toStringAsFixed(0)}g protein'),
                  _mini(Icons.eco,
                      '${s.totalVeggieGrams.toStringAsFixed(0)}g veggie'),
                  _mini(Icons.medication, '${s.pillCount} pills'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mini(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 3),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      );
}
