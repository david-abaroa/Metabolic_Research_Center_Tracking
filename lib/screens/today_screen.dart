import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/timeline_entry.dart';
import '../widgets/timeline_tile.dart';
import '../widgets/add_entry_sheet.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  List<TimelineEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final entries = await DatabaseHelper.instance.entriesForDay(DateTime.now());
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _delete(int id) async {
    await DatabaseHelper.instance.deleteEntry(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, MMM d').format(DateTime.now());
    return Scaffold(
      appBar: AppBar(title: Text('Today — $today')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(child: Text('Nothing logged yet. Tap + to add.'))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final e = _entries[i];
                    return TimelineTile(entry: e, onDelete: () => _delete(e.id!));
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddEntrySheet(context, _load),
        child: const Icon(Icons.add),
      ),
    );
  }
}
