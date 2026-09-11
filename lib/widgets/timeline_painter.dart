import 'package:flutter/material.dart';

const double hourHeight = 70.0;
const double timelineLeftMargin = 52.0;

/// A shaded band on the timeline background, in minutes-since-midnight.
class OptimalWindow {
  final double startMinutes;
  final double endMinutes;
  const OptimalWindow(this.startMinutes, this.endMinutes);
}

double minutesSinceMidnight(DateTime t) => t.hour * 60.0 + t.minute + t.second / 60.0;

double timeToY(DateTime t) => minutesSinceMidnight(t) / 60.0 * hourHeight;

class TimelinePainter extends CustomPainter {
  final List<OptimalWindow> optimalWindows;
  final Color gridColor;
  final Color labelColor;
  final Color optimalColor;
  final double? nowMinutes;

  TimelinePainter({
    required this.optimalWindows,
    required this.gridColor,
    required this.labelColor,
    required this.optimalColor,
    this.nowMinutes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Optimal windows first, so gridlines/labels draw on top.
    final windowPaint = Paint()..color = optimalColor;
    for (final w in optimalWindows) {
      final top = (w.startMinutes / 60.0) * hourHeight;
      final bottom = (w.endMinutes / 60.0) * hourHeight;
      canvas.drawRect(
        Rect.fromLTRB(timelineLeftMargin, top, size.width, bottom),
        windowPaint,
      );
    }

    final linePaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int h = 0; h <= 24; h++) {
      final y = h * hourHeight;
      _drawDottedLine(canvas, Offset(timelineLeftMargin, y),
          Offset(size.width, y), linePaint);
      if (h < 24) {
        final label = _hourLabel(h);
        textPainter.text = TextSpan(
          text: label,
          style: TextStyle(color: labelColor, fontSize: 11),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(4, y + 2));
      }
    }

    if (nowMinutes != null) {
      final y = (nowMinutes! / 60.0) * hourHeight;
      final nowPaint = Paint()
        ..color = Colors.redAccent
        ..strokeWidth = 1.5;
      canvas.drawLine(
          Offset(timelineLeftMargin, y), Offset(size.width, y), nowPaint);
      canvas.drawCircle(Offset(timelineLeftMargin, y), 3, nowPaint);
    }
  }

  String _hourLabel(int h) {
    final period = h < 12 ? 'AM' : 'PM';
    int hour12 = h % 12;
    if (hour12 == 0) hour12 = 12;
    return '$hour12 $period';
  }

  void _drawDottedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    final totalLength = (end.dx - start.dx);
    double covered = 0;
    while (covered < totalLength) {
      final dashEnd = (covered + dashWidth).clamp(0, totalLength);
      canvas.drawLine(
        Offset(start.dx + covered, start.dy),
        Offset(start.dx + dashEnd, start.dy),
        paint,
      );
      covered += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant TimelinePainter oldDelegate) {
    return oldDelegate.optimalWindows != optimalWindows ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.nowMinutes != nowMinutes;
  }
}
