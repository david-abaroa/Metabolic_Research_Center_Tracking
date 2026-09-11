import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/timeline_entry.dart';
import '../widgets/timeline_tile.dart';
import '../widgets/add_entry_sheet.dart';
import '../widgets/timeline_painter.dart';
import 'summary_screen.dart';

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

  Future<void> _load() async {
    setState(() => _loading = true);
    final entries = await DatabaseHelper.instance.entriesForDay(DateTime.now());
    setState(() {
      _entries = entries;
      _loading = false;
    });
    if (!_scrolledToNow) {
      _scrolledToNow = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNow());
    }
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

  double _estimatedTileHeight(TimelineEntry e) {
    if (e.type == EntryType.meal &&
        e.proteinName != null &&
        e.veggieName != null) {
      return 78;
    }
    switch (e.type) {
      case EntryType.meal:
      case EntryType.exercise:
      case EntryType.water:
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
      return OptimalWindow(start.clamp(0, dayMinutes), end.clamp(0, dayMinutes));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, MMM d').format(DateTime.now());
    final mealCount = _entries.where((e) => e.type == EntryType.meal).length;
    final sorted = [..._entries]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final positions = _layoutPositions(sorted);
    final maxBottom = positions.isEmpty
        ? 0.0
        : positions.values.reduce((a, b) => a > b ? a : b) + 80;
    final canvasHeight =
        maxBottom > 24 * hourHeight ? maxBottom : 24 * hourHeight;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Today — $today'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Chip(
              avatar: const Icon(Icons.restaurant, size: 16),
              label: Text('$mealCount'),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.assessment_outlined),
            tooltip: 'Day summary',
            onPressed: () =>
                showDaySummarySheet(context, DateTime.now(), _entries),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(child: Text('Nothing logged yet. Tap + to add.'))
              : SingleChildScrollView(
                  controller: _scrollController,
                  child: SizedBox(
                    height: canvasHeight,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: TimelinePainter(
                              optimalWindows: _optimalWindows(_entries),
                              gridColor: colorScheme.outlineVariant,
                              labelColor: colorScheme.onSurfaceVariant,
                              optimalColor:
                                  colorScheme.tertiary.withOpacity(0.16),
                              nowMinutes: minutesSinceMidnight(DateTime.now()),
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
                      ],
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddEntrySheet(context, _load),
        child: const Icon(Icons.add),
      ),
    );
  }
}
