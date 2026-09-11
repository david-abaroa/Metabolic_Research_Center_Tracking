import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/timeline_entry.dart';
import '../widgets/add_entry_sheet.dart';
import '../widgets/timeline_painter.dart';
import '../widgets/timeline_tile.dart';

const double _rowGutter = 64.0;
const double _rowHeight = 40.0;

/// The 7 days of the week stacked as horizontal timelines, aligned by time
/// of day, so you can compare what happened when across the week at a
/// glance. Tapping a dot opens that entry; tapping elsewhere on a row (or
/// its label) jumps to the day view for that date.
class WeekTimelineView extends StatefulWidget {
  final DateTime weekStart;
  final ValueChanged<DateTime> onDayTap;

  const WeekTimelineView({
    super.key,
    required this.weekStart,
    required this.onDayTap,
  });

  @override
  State<WeekTimelineView> createState() => _WeekTimelineViewState();
}

class _WeekTimelineViewState extends State<WeekTimelineView> {
  bool _loading = true;
  List<DateTime> _days = [];
  List<List<TimelineEntry>> _entriesByDay = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant WeekTimelineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weekStart != widget.weekStart) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final days =
        List.generate(7, (i) => widget.weekStart.add(Duration(days: i)));
    final lists = <List<TimelineEntry>>[];
    for (final d in days) {
      lists.add(await DatabaseHelper.instance.entriesForDay(d));
    }
    if (!mounted) return;
    setState(() {
      _days = days;
      _entriesByDay = lists;
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              const SizedBox(width: _rowGutter),
              for (int h = 0; h <= 21; h += 3)
                Expanded(
                  child: Text(
                    hourLabel(h),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: _days.length,
            itemBuilder: (ctx, i) => _dayRow(
                context, _days[i], _entriesByDay[i], _isToday(_days[i])),
          ),
        ),
      ],
    );
  }

  Widget _dayRow(BuildContext context, DateTime day,
      List<TimelineEntry> entries, bool isToday) {
    final label = DateFormat('EEE M/d').format(day);
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _rowGutter,
            child: InkWell(
              onTap: () => widget.onDayTap(day),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? colorScheme.primary : null,
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onDayTap(day),
              child: Container(
                height: _rowHeight,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: LayoutBuilder(builder: (ctx, constraints) {
                  final w = constraints.maxWidth;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CustomPaint(
                        size: Size(w, _rowHeight),
                        painter: VerticalHourGridPainter(
                          gridColor: colorScheme.outlineVariant,
                          nowX: isToday
                              ? (minutesSinceMidnight(DateTime.now()) /
                                  1440 *
                                  w)
                              : null,
                        ),
                      ),
                      for (final e in entries)
                        Positioned(
                          left:
                              (minutesSinceMidnight(e.timestamp) / 1440 * w - 5)
                                  .clamp(0.0, w - 10),
                          top: (_rowHeight - 10) / 2,
                          child: GestureDetector(
                            onTap: () async {
                              await showEntryDetailSheet(context, e, _load);
                            },
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: entryStyles[e.type]!.color,
                                border:
                                    Border.all(color: Colors.white, width: 1),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
