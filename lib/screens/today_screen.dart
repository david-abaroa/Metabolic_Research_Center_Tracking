import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/timeline_entry.dart';
import '../widgets/timeline_tile.dart';
import '../widgets/add_entry_sheet.dart';
import '../widgets/timeline_painter.dart';
import 'settings_screen.dart';
import 'summary_screen.dart';
import 'week_summary_view.dart';
import 'week_timeline_view.dart';

enum ViewMode { day, weekSummary, weekTimeline }

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Monday of the week containing [d].
DateTime _mondayOf(DateTime d) {
  final date = _dateOnly(d);
  return date.subtract(Duration(days: date.weekday - 1));
}

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  List<TimelineEntry> _entries = [];
  bool _loading = true;
  bool _scrolledToNow = false;
  final ScrollController _scrollController = ScrollController();

  ViewMode _viewMode = ViewMode.day;
  DateTime _selectedDate = _dateOnly(DateTime.now());
  late DateTime _weekStart = _mondayOf(_selectedDate);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final entries = await DatabaseHelper.instance.entriesForDay(_selectedDate);
    setState(() {
      _entries = entries;
      _loading = false;
    });
    if (_isToday(_selectedDate)) {
      if (!_scrolledToNow) {
        _scrolledToNow = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
      }
    } else if (_entries.isNotEmpty) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToFirstEntry());
    }
  }

  void _goToDay(int deltaDays) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: deltaDays));
      _scrolledToNow = false;
    });
    _load();
  }

  void _goToWeek(int deltaWeeks) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: 7 * deltaWeeks));
    });
  }

  void _jumpToDay(DateTime day) {
    setState(() {
      _selectedDate = _dateOnly(day);
      _scrolledToNow = false;
      _viewMode = ViewMode.day;
    });
    _load();
  }

  /// Switching to the day view via the bottom bar (rather than tapping a
  /// specific day) doesn't change the date, so `_load` wouldn't otherwise
  /// run — but the day view's ScrollView was just torn down and rebuilt
  /// while a week view was showing, so it needs repositioning (and its
  /// data may be stale if something changed while a week view was active).
  void _switchViewMode(ViewMode mode) {
    setState(() {
      _viewMode = mode;
      if (mode == ViewMode.day) _scrolledToNow = false;
    });
    if (mode == ViewMode.day) _load();
  }

  Future<void> _delete(int id) async {
    await DatabaseHelper.instance.deleteEntry(id);
    _load();
  }

  void _scrollToNow() {
    if (!_scrollController.hasClients) return;
    final nowY = timeToY(DateTime.now());
    final target =
        (nowY - 200).clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.jumpTo(target);
  }

  /// For non-today dates there's no "now" to scroll to, so instead line up
  /// the top of the viewport with the day's earliest entry.
  void _scrollToFirstEntry() {
    if (!_scrollController.hasClients || _entries.isEmpty) return;
    final earliest = _entries
        .map((e) => e.timestamp)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final target = timeToY(earliest)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.jumpTo(target);
  }

  double _estimatedTileHeight(TimelineEntry e) {
    if (e.type == EntryType.meal &&
        e.proteinName != null &&
        e.veggieName != null) {
      return 78;
    }
    if (e.type == EntryType.pills && (e.pills?.length ?? 0) > 2) {
      return 78;
    }
    switch (e.type) {
      case EntryType.meal:
      case EntryType.exercise:
      case EntryType.water:
      case EntryType.tirzepatide:
      case EntryType.pills:
        return 64;
      default:
        return 56;
    }
  }

  /// Places entries at their true time-of-day position, nudging later
  /// entries down when two land close enough together to overlap.
  Map<int, double> _layoutPositions(List<TimelineEntry> sorted) {
    final positions = <int, double>{};
    double lastBottom = -8;
    for (final e in sorted) {
      double top = timeToY(e.timestamp);
      if (top < lastBottom + 6) top = lastBottom + 6;
      positions[e.id!] = top;
      lastBottom = top + _estimatedTileHeight(e);
    }
    return positions;
  }

  List<OptimalWindow> _optimalWindows(List<TimelineEntry> entries) {
    const dayMinutes = 24 * 60.0;
    return entries.where((e) => e.startsOptimalWindow).map((e) {
      final start = minutesSinceMidnight(e.timestamp) + 180;
      final end = minutesSinceMidnight(e.timestamp) + 240;
      return OptimalWindow(
          start.clamp(0, dayMinutes), end.clamp(0, dayMinutes));
    }).toList();
  }

  /// Tapping empty space on the timeline opens the add-entry sheet
  /// pre-filled with the time that was tapped.
  void _onTimelineTap(TapUpDetails details) {
    final dx = details.localPosition.dx;
    final dy = details.localPosition.dy;
    if (dx < timelineLeftMargin) return;
    final totalMinutes = (dy / hourHeight * 60).clamp(0.0, 24 * 60 - 1);
    final hour = totalMinutes ~/ 60;
    final minute = (totalMinutes % 60).round().clamp(0, 59);
    showAddEntrySheet(context, _load,
        initialTime: TimeOfDay(hour: hour.toInt(), minute: minute),
        day: _selectedDate);
  }

  String _dayTitle() {
    final label = DateFormat('EEE, MMM d').format(_selectedDate);
    return _isToday(_selectedDate) ? 'Today — $label' : label;
  }

  String _weekTitle() {
    final end = _weekStart.add(const Duration(days: 6));
    return 'Week of ${DateFormat('MMM d').format(_weekStart)} – '
        '${DateFormat('MMM d').format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDayMode = _viewMode == ViewMode.day;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: isDayMode ? 'Previous day' : 'Previous week',
          onPressed: isDayMode ? () => _goToDay(-1) : () => _goToWeek(-1),
        ),
        title: Text(isDayMode ? _dayTitle() : _weekTitle(),
            style: const TextStyle(fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: isDayMode ? 'Next day' : 'Next week',
            onPressed: isDayMode ? () => _goToDay(1) : () => _goToWeek(1),
          ),
          if (isDayMode) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Chip(
                avatar: const Icon(Icons.restaurant, size: 16),
                label: Text(
                    '${_entries.where((e) => e.type == EntryType.meal).length}'),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.assessment_outlined),
              tooltip: 'Day summary',
              onPressed: () =>
                  showDaySummarySheet(context, _selectedDate, _entries),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => showSettingsSheet(context),
          ),
        ],
      ),
      body: _buildBody(colorScheme),
      floatingActionButton: isDayMode
          ? FloatingActionButton(
              onPressed: () =>
                  showAddEntrySheet(context, _load, day: _selectedDate),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Material(
            elevation: 3,
            borderRadius: BorderRadius.circular(28),
            color: colorScheme.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: SegmentedButton<ViewMode>(
                segments: const [
                  ButtonSegment(
                    value: ViewMode.day,
                    icon: Icon(Icons.view_day_outlined),
                    label: Text('Day'),
                  ),
                  ButtonSegment(
                    value: ViewMode.weekSummary,
                    icon: Icon(Icons.table_rows_outlined),
                    label: Text('Week'),
                  ),
                  ButtonSegment(
                    value: ViewMode.weekTimeline,
                    icon: Icon(Icons.calendar_view_week_outlined),
                    label: Text('Grid'),
                  ),
                ],
                selected: {_viewMode},
                showSelectedIcon: false,
                onSelectionChanged: (s) => _switchViewMode(s.first),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    switch (_viewMode) {
      case ViewMode.weekSummary:
        return WeekSummaryView(weekStart: _weekStart, onDayTap: _jumpToDay);
      case ViewMode.weekTimeline:
        return WeekTimelineView(weekStart: _weekStart, onDayTap: _jumpToDay);
      case ViewMode.day:
        return _buildDayBody(colorScheme);
    }
  }

  Widget _buildDayBody(ColorScheme colorScheme) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final sorted = [..._entries]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final positions = _layoutPositions(sorted);
    final maxBottom = positions.isEmpty
        ? 0.0
        : positions.values.reduce((a, b) => a > b ? a : b) + 80;
    final canvasHeight =
        maxBottom > 24 * hourHeight ? maxBottom : 24 * hourHeight;

    return SingleChildScrollView(
      controller: _scrollController,
      child: SizedBox(
        height: canvasHeight,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: _onTimelineTap,
                child: CustomPaint(
                  painter: TimelinePainter(
                    optimalWindows: _optimalWindows(_entries),
                    gridColor: colorScheme.outlineVariant,
                    labelColor: colorScheme.onSurfaceVariant,
                    optimalColor: colorScheme.tertiary.withOpacity(0.16),
                    nowMinutes: _isToday(_selectedDate)
                        ? minutesSinceMidnight(DateTime.now())
                        : null,
                  ),
                ),
              ),
            ),
            for (final e in sorted)
              Positioned(
                top: positions[e.id!],
                left: timelineLeftMargin + 8,
                right: 8,
                child: TimelineTile(
                  entry: e,
                  onDelete: () => _delete(e.id!),
                  onTap: () async {
                    await showEntryDetailSheet(context, e, _load);
                  },
                ),
              ),
            if (_entries.isEmpty)
              const Positioned(
                top: 24,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: Text('Nothing logged yet. Tap the timeline to add.'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
