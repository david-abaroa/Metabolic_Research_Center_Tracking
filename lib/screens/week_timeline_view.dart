import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/timeline_entry.dart';
import '../widgets/add_entry_sheet.dart';
import '../widgets/timeline_painter.dart';
import '../widgets/timeline_tile.dart';
import '../widgets/tirz_gac_badge.dart';

const double _gutterWidth = 92.0;
const double _headerHeight = 24.0;
const double _rowHeight = 52.0;
const double _rowVPad = 4.0;
const double _iconSize = 18.0;

/// The default (zoomed-in) window the grid opens scrolled to — you can
/// still scroll left/right to see the rest of the day.
const int _focusStartHour = 6;
const int _focusEndHour = 23;

/// The 7 days of the week stacked as horizontal timelines, aligned by time
/// of day, so you can compare what happened when across the week at a
/// glance. Tapping an icon opens that entry; tapping elsewhere on a row
/// (or its label) jumps to the day view for that date. Tirzepatide/GAC
/// don't get plotted on the timeline — they show as a star/circle badge
/// next to the date instead (see the day summary view for the same idea).
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
  bool _scrolledToFocus = false;
  List<DateTime> _days = [];
  List<List<TimelineEntry>> _entriesByDay = [];
  final ScrollController _hScrollController = ScrollController();

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

  @override
  void dispose() {
    _hScrollController.dispose();
    super.dispose();
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
        Expanded(
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _leftColumn(context),
                Expanded(child: _scrollableTimeline(context)),
              ],
            ),
          ),
        ),
        _legend(context),
      ],
    );
  }

  Widget _leftColumn(BuildContext context) {
    return SizedBox(
      width: _gutterWidth,
      child: Column(
        children: [
          const SizedBox(height: _headerHeight),
          for (int i = 0; i < _days.length; i++)
            _dayLabelRow(
                context, _days[i], _entriesByDay[i], _isToday(_days[i])),
        ],
      ),
    );
  }

  Widget _dayLabelRow(BuildContext context, DateTime day,
      List<TimelineEntry> entries, bool isToday) {
    final label = DateFormat('EEE M/d').format(day);
    final tookTz = entries.any((e) => e.type == EntryType.tirzepatide);
    final tookGac = entries.any((e) => e.type == EntryType.gac);
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _rowVPad),
      child: SizedBox(
        height: _rowHeight,
        child: InkWell(
          onTap: () => widget.onDayTap(day),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? colorScheme.primary : null,
                ),
              ),
              if (tookTz || tookGac) ...[
                const SizedBox(width: 4),
                TirzGacBadge(
                    tookTirzepatide: tookTz, tookGac: tookGac, size: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _scrollableTimeline(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final viewportWidth = constraints.maxWidth;
      final pxPerHour = viewportWidth / (_focusEndHour - _focusStartHour);
      final totalWidth = pxPerHour * 24;

      if (!_scrolledToFocus) {
        _scrolledToFocus = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_hScrollController.hasClients) {
            _hScrollController.jumpTo(pxPerHour * _focusStartHour);
          }
        });
      }

      return SingleChildScrollView(
        controller: _hScrollController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalWidth,
          child: Column(
            children: [
              _hourHeader(context, pxPerHour, totalWidth),
              for (int i = 0; i < _days.length; i++)
                _timelineRow(context, _days[i], _entriesByDay[i],
                    _isToday(_days[i]), pxPerHour, totalWidth),
            ],
          ),
        ),
      );
    });
  }

  Widget _hourHeader(
      BuildContext context, double pxPerHour, double totalWidth) {
    return SizedBox(
      height: _headerHeight,
      width: totalWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int h = 0; h <= 24; h += 3)
            Positioned(
              left: (h * pxPerHour - 20).clamp(0.0, totalWidth - 40),
              top: 2,
              child: SizedBox(
                width: 40,
                child: Text(
                  hourLabel(h),
                  textAlign: TextAlign.center,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _timelineRow(
      BuildContext context,
      DateTime day,
      List<TimelineEntry> entries,
      bool isToday,
      double pxPerHour,
      double totalWidth) {
    final colorScheme = Theme.of(context).colorScheme;
    final plottable = entries
        .where(
            (e) => e.type != EntryType.tirzepatide && e.type != EntryType.gac)
        .toList();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _rowVPad),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onDayTap(day),
        child: Container(
          height: _rowHeight,
          width: totalWidth,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(totalWidth, _rowHeight),
                painter: VerticalHourGridPainter(
                  gridColor: colorScheme.outlineVariant,
                  nowX: isToday
                      ? minutesSinceMidnight(DateTime.now()) / 60 * pxPerHour
                      : null,
                ),
              ),
              for (final e in plottable)
                Positioned(
                  left: (minutesSinceMidnight(e.timestamp) / 60 * pxPerHour -
                          _iconSize / 2)
                      .clamp(0.0, totalWidth - _iconSize),
                  // Protein drinks/bars float in the upper lane, everything
                  // else sits in the lower lane.
                  top: (e.type == EntryType.proteinDrink ||
                              e.type == EntryType.proteinBar
                          ? _rowHeight * 0.25
                          : _rowHeight * 0.75) -
                      _iconSize / 2,
                  child: GestureDetector(
                    onTap: () async {
                      await showEntryDetailSheet(context, e, _load);
                    },
                    child: Container(
                      width: _iconSize,
                      height: _iconSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.surface,
                        border: Border.all(
                            color: entryStyles[e.type]!.color, width: 1),
                      ),
                      child: Icon(
                        entryStyles[e.type]!.icon,
                        size: _iconSize * 0.65,
                        color: entryStyles[e.type]!.color,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legend(BuildContext context) {
    const types = [
      EntryType.wake,
      EntryType.proteinDrink,
      EntryType.proteinBar,
      EntryType.meal,
      EntryType.exercise,
      EntryType.water,
      EntryType.pills,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: [
          for (final t in types)
            _legendItem(entryStyles[t]!.icon, entryStyles[t]!.color,
                entryStyles[t]!.label),
          _legendStar(),
          _legendCircle(),
        ],
      ),
    );
  }

  Widget _legendItem(IconData icon, Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      );

  Widget _legendStar() => const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 14, color: Colors.amber),
          SizedBox(width: 4),
          Text('Tirzepatide day', style: TextStyle(fontSize: 11)),
        ],
      );

  Widget _legendCircle() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.teal, width: 1.5),
            ),
          ),
          const SizedBox(width: 4),
          const Text('GAC day', style: TextStyle(fontSize: 11)),
        ],
      );
}
