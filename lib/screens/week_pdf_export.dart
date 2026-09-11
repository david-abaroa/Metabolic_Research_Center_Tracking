import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../db/database_helper.dart';
import '../models/timeline_entry.dart';
import '../widgets/timeline_painter.dart' show hourLabel, minutesSinceMidnight;
import '../widgets/timeline_tile.dart' show entryStyles;
import 'summary_screen.dart';

const double _pdfRowHeight = 34.0;
const double _pdfLabelWidth = 74.0;

/// Builds a two-page PDF for the given week — a summary page (same data as
/// the Week Summary view) and a timeline grid page (same data as the Grid
/// view) — then hands it to the OS share sheet.
Future<void> exportWeekAsPdf(BuildContext context, DateTime weekStart) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final entriesByDay = <List<TimelineEntry>>[];
    final summaries = <DaySummary>[];
    for (final d in days) {
      final entries = await DatabaseHelper.instance.entriesForDay(d);
      entriesByDay.add(entries);
      summaries.add(await DaySummary.compute(entries));
    }

    final doc = pw.Document();
    doc.addPage(_summaryPage(days, summaries));
    doc.addPage(_gridPage(days, entriesByDay, summaries));
    final bytes = await doc.save();

    if (context.mounted) Navigator.pop(context);

    final label = DateFormat('yyyyMMdd').format(weekStart);
    await Printing.sharePdf(bytes: bytes, filename: 'week_$label.pdf');
  } catch (e) {
    if (context.mounted) Navigator.pop(context);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }
}

bool _isToday(DateTime d) {
  final now = DateTime.now();
  return d.year == now.year && d.month == now.month && d.day == now.day;
}

// ---------------------------------------------------------------------------
// Summary page
// ---------------------------------------------------------------------------

pw.Page _summaryPage(List<DateTime> days, List<DaySummary> summaries) {
  int totalMeals = 0, totalBars = 0, totalPills = 0, tirzDays = 0, gacDays = 0;
  double totalCal = 0, totalWater = 0, totalProtein = 0, totalVeggie = 0;
  for (final s in summaries) {
    totalMeals += s.mealCount;
    totalBars += s.proteinBarDrinkCount;
    totalCal += s.estimatedCalories;
    totalWater += s.totalWaterOz;
    totalProtein += s.totalProteinGrams;
    totalVeggie += s.totalVeggieGrams;
    totalPills += s.pillCount;
    if (s.tookTirzepatide) tirzDays++;
    if (s.tookGac) gacDays++;
  }
  final rangeLabel = '${DateFormat('MMM d').format(days.first)} - '
      '${DateFormat('MMM d').format(days.last)}';

  return pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    build: (pwContext) => [
      pw.Header(level: 0, text: 'Week Summary'),
      pw.Text(rangeLabel,
          style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700)),
      pw.SizedBox(height: 14),
      pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.teal50,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _statRow('Meals logged', '$totalMeals'),
            _statRow('Protein drinks/bars', '$totalBars'),
            _statRow('Total calories', '~${totalCal.toStringAsFixed(0)} kcal'),
            _statRow('Total water', '${totalWater.toStringAsFixed(0)} fl oz'),
            _statRow('Total protein', '${totalProtein.toStringAsFixed(0)}g'),
            _statRow('Total veggies', '${totalVeggie.toStringAsFixed(0)}g'),
            _statRow('Total pills', '$totalPills'),
            _statRow('Tirzepatide days', '$tirzDays / 7'),
            _statRow('GAC days', '$gacDays / 7'),
          ],
        ),
      ),
      pw.SizedBox(height: 16),
      for (int i = 0; i < days.length; i++) _dayCard(days[i], summaries[i]),
    ],
  );
}

pw.Widget _statRow(String label, String value) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
          pw.Text(value,
              style:
                  pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );

pw.Widget _dayCard(DateTime day, DaySummary s) {
  final label =
      DateFormat('EEE, MMM d').format(day) + (_isToday(day) ? ' (today)' : '');
  final badge = _badge(s);
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 8),
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey400),
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style:
                    pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            if (badge != null) badge,
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Wrap(spacing: 12, runSpacing: 2, children: [
          _mini('${s.proteinBarDrinkCount} drinks/bars'),
          _mini('${s.estimatedCalories.toStringAsFixed(0)} kcal'),
          _mini('${s.totalWaterOz.toStringAsFixed(0)} oz water'),
          _mini('${s.totalProteinGrams.toStringAsFixed(0)}g protein'),
          _mini('${s.totalVeggieGrams.toStringAsFixed(0)}g veggie'),
          _mini('${s.pillCount} pills'),
        ]),
      ],
    ),
  );
}

pw.Widget _mini(String text) => pw.Text(text,
    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800));

/// A filled amber dot for a tirzepatide day (outline otherwise), circled in
/// teal if GAC was also taken. Drawn as shapes rather than a star glyph
/// since the base PDF fonts don't reliably include one.
pw.Widget? _badge(DaySummary s) {
  if (!s.tookTirzepatide && !s.tookGac) return null;
  final dot = pw.Container(
    width: 9,
    height: 9,
    decoration: pw.BoxDecoration(
      shape: pw.BoxShape.circle,
      color: s.tookTirzepatide ? PdfColors.amber700 : PdfColors.white,
      border: pw.Border.all(
        color: s.tookTirzepatide ? PdfColors.amber700 : PdfColors.grey500,
        width: 1,
      ),
    ),
  );
  if (!s.tookGac) return dot;
  return pw.Container(
    padding: const pw.EdgeInsets.all(2),
    decoration: pw.BoxDecoration(
      shape: pw.BoxShape.circle,
      border: pw.Border.all(color: PdfColors.teal, width: 1.2),
    ),
    child: dot,
  );
}

// ---------------------------------------------------------------------------
// Grid page
// ---------------------------------------------------------------------------

pw.Page _gridPage(List<DateTime> days, List<List<TimelineEntry>> entriesByDay,
    List<DaySummary> summaries) {
  return pw.Page(
    pageFormat: PdfPageFormat.a4.landscape,
    margin: const pw.EdgeInsets.all(24),
    build: (pwContext) {
      final width = PdfPageFormat.a4.landscape.width - 48 - _pdfLabelWidth;
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Header(level: 0, text: 'Week Timeline'),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.SizedBox(width: _pdfLabelWidth),
              for (int h = 0; h <= 21; h += 3)
                pw.Expanded(
                  child: pw.Text(hourLabel(h),
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey700)),
                ),
            ],
          ),
          pw.SizedBox(height: 4),
          for (int i = 0; i < days.length; i++)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(
                    width: _pdfLabelWidth,
                    child: pw.Row(children: [
                      pw.Text(
                        DateFormat('EEE M/d').format(days[i]),
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: _isToday(days[i])
                              ? pw.FontWeight.bold
                              : pw.FontWeight.normal,
                        ),
                      ),
                      if (_badge(summaries[i]) != null) ...[
                        pw.SizedBox(width: 3),
                        _badge(summaries[i])!,
                      ],
                    ]),
                  ),
                  _dayRow(days[i], entriesByDay[i], width, _isToday(days[i])),
                ],
              ),
            ),
          pw.SizedBox(height: 14),
          _legend(),
        ],
      );
    },
  );
}

pw.Widget _dayRow(
    DateTime day, List<TimelineEntry> entries, double width, bool isToday) {
  final plottable = entries
      .where((e) => e.type != EntryType.tirzepatide && e.type != EntryType.gac)
      .toList();
  return pw.Container(
    height: _pdfRowHeight,
    width: width,
    decoration: pw.BoxDecoration(
      color: PdfColors.grey100,
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Stack(
      children: [
        pw.CustomPaint(
          size: PdfPoint(width, _pdfRowHeight),
          painter: (canvas, size) {
            for (int h = 0; h <= 24; h += 3) {
              _dottedVLine(canvas, h / 24 * size.x, size.y, PdfColors.grey400);
            }
            if (isToday) {
              final nowX = minutesSinceMidnight(DateTime.now()) / 1440 * size.x;
              canvas
                ..setColor(PdfColors.red)
                ..drawLine(nowX, 0, nowX, size.y)
                ..strokePath();
            }
          },
        ),
        for (final e in plottable)
          pw.Positioned(
            left: (minutesSinceMidnight(e.timestamp) / 1440 * width - 4)
                .clamp(0.0, width - 8),
            top: (e.type == EntryType.proteinDrink ||
                        e.type == EntryType.proteinBar
                    ? _pdfRowHeight * 0.25
                    : _pdfRowHeight * 0.75) -
                4,
            child: pw.Container(
              width: 8,
              height: 8,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                color: PdfColor.fromInt(entryStyles[e.type]!.color.toARGB32()),
                border: pw.Border.all(color: PdfColors.white, width: 0.5),
              ),
            ),
          ),
      ],
    ),
  );
}

void _dottedVLine(PdfGraphics canvas, double x, double height, PdfColor color) {
  const dashLen = 3.0;
  const dashSpace = 3.0;
  canvas.setColor(color);
  double covered = 0;
  while (covered < height) {
    final end = (covered + dashLen).clamp(0.0, height);
    canvas.drawLine(x, covered, x, end);
    canvas.strokePath();
    covered += dashLen + dashSpace;
  }
}

pw.Widget _legend() {
  const types = [
    EntryType.wake,
    EntryType.proteinDrink,
    EntryType.proteinBar,
    EntryType.meal,
    EntryType.exercise,
    EntryType.water,
    EntryType.pills,
  ];
  return pw.Wrap(
    spacing: 14,
    runSpacing: 4,
    children: [
      for (final t in types)
        pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
          pw.Container(
            width: 7,
            height: 7,
            decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                color: PdfColor.fromInt(entryStyles[t]!.color.toARGB32())),
          ),
          pw.SizedBox(width: 4),
          pw.Text(entryStyles[t]!.label,
              style: const pw.TextStyle(fontSize: 9)),
        ]),
      pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
        pw.Container(
          width: 7,
          height: 7,
          decoration: const pw.BoxDecoration(
              shape: pw.BoxShape.circle, color: PdfColors.amber700),
        ),
        pw.SizedBox(width: 4),
        pw.Text('Tirzepatide day', style: const pw.TextStyle(fontSize: 9)),
      ]),
      pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
        pw.Container(
          width: 7,
          height: 7,
          decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: PdfColors.teal, width: 1)),
        ),
        pw.SizedBox(width: 4),
        pw.Text('GAC day', style: const pw.TextStyle(fontSize: 9)),
      ]),
    ],
  );
}
