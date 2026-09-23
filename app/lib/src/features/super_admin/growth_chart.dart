import 'package:flutter/material.dart';

import 'panel_data.dart';

/// "Platform Growth" line chart — real daily counts (see dashboard_data.dart's
/// growthSeriesProvider), tap a legend dot to toggle its series. ponytail: no
/// hover tooltips (canvas hit-testing per point isn't worth it here); the
/// legend toggle is the one interactive bit worth having.
class GrowthChart extends StatefulWidget {
  const GrowthChart({required this.labels, required this.series, required this.colors, super.key});

  final List<String> labels;
  final Map<String, List<double>> series;
  final Map<String, Color> colors;

  @override
  State<GrowthChart> createState() => _GrowthChartState();
}

class _GrowthChartState extends State<GrowthChart> {
  final Set<String> _hidden = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          children: [
            for (final key in widget.series.keys)
              InkWell(
                onTap: () => setState(
                  () => _hidden.contains(key) ? _hidden.remove(key) : _hidden.add(key),
                ),
                child: Opacity(
                  opacity: _hidden.contains(key) ? 0.35 : 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: widget.colors[key],
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(key,
                          style: const TextStyle(fontSize: 12.5, color: AC.ink600)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          width: double.infinity,
          child: CustomPaint(
            painter: _ChartPainter(
              hidden: _hidden,
              labels: widget.labels,
              series: widget.series,
              colors: widget.colors,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.hidden,
    required this.labels,
    required this.series,
    required this.colors,
  });

  final Set<String> hidden;
  final List<String> labels;
  final Map<String, List<double>> series;
  final Map<String, Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    const padL = 34.0, padR = 6.0, padT = 8.0, padB = 20.0;
    final w = size.width, h = size.height;
    final plotW = w - padL - padR, plotH = h - padT - padB;

    final visibleMax = series.entries
        .where((e) => !hidden.contains(e.key))
        .expand((e) => e.value)
        .fold<double>(0, (m, v) => v > m ? v : m);
    final niceMax = visibleMax <= 5 ? 5.0 : (visibleMax / 5).ceil() * 5.0;
    final max = niceMax == 0 ? 5.0 : niceMax;

    final gridPaint = Paint()
      ..color = AC.line
      ..strokeWidth = 1;
    final labelStyle = TextStyle(fontSize: 10, color: AC.ink400);

    for (var g = 0; g <= 4; g++) {
      final y = padT + g * (plotH / 4);
      canvas.drawLine(Offset(padL, y), Offset(w - padR, y), gridPaint);
      final val = (max - g * (max / 4)).round();
      final text = val >= 1000 ? '${val ~/ 1000}K' : '$val';
      _paintText(canvas, text, Offset(0, y - 6), labelStyle);
    }

    if (series.isEmpty || series.values.first.isEmpty) return;
    final n = series.values.first.length;
    final xStep = n > 1 ? plotW / (n - 1) : 0.0;
    double xAt(int i) => padL + i * xStep;
    double yAt(double v) => padT + plotH - (v / max) * plotH;

    final labelStep = (labels.length / 5).ceil().clamp(1, labels.length);
    for (var i = 0; i < labels.length; i += labelStep) {
      final tp = _textPainter(labels[i], labelStyle);
      tp.paint(canvas, Offset(xAt(i) - tp.width / 2, h - 14));
    }

    for (final entry in series.entries) {
      if (hidden.contains(entry.key)) continue;
      final color = colors[entry.key]!;
      final points = [for (var i = 0; i < entry.value.length; i++) Offset(xAt(i), yAt(entry.value[i]))];

      final area = Path()..moveTo(padL, h - padB);
      for (final p in points) {
        area.lineTo(p.dx, p.dy);
      }
      area
        ..lineTo(xAt(n - 1), h - padB)
        ..close();
      canvas.drawPath(area, Paint()..color = color.withValues(alpha: 0.08));

      final line = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        line.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        line,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );

      for (final p in points) {
        canvas.drawCircle(p, 3.2, Paint()..color = Colors.white);
        canvas.drawCircle(
          p,
          3.2,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  void _paintText(Canvas canvas, String text, Offset offset, TextStyle style) {
    _textPainter(text, style).paint(canvas, offset);
  }

  TextPainter _textPainter(String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp;
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.hidden != hidden || oldDelegate.series != series;
}
