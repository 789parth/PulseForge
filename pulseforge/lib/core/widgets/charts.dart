import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

// ============================================================================
// PfLineChart
// ============================================================================

/// Pure [CustomPainter] line chart — zero fl_chart dependency.
///
/// Performance highlights:
/// * [TextPainter]s for labels are built once in [_LineChartPainter]'s
///   constructor, not during [paint].
/// * [Paint] objects are cached as fields.
/// * [shouldRepaint] compares list reference (identity), so the painter is
///   only recreated when the caller supplies a new list object.
/// * Entry is animated left-to-right via [canvas.clipRect] driven by a
///   [TweenAnimationBuilder].
class PfLineChart extends StatelessWidget {
  const PfLineChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 180,
    this.color = AppColors.primaryBlue,
  });

  final List<double> values;
  final List<String> labels;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    return RepaintBoundary(
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, clipProgress, _) {
            return CustomPaint(
              painter: _LineChartPainter(
                values: values,
                labels: labels,
                color: color,
                clipProgress: clipProgress,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.values,
    required this.labels,
    required this.color,
    required this.clipProgress,
  }) : _maxValue = _calculateMaxValue(values) {
    // ── Pre-build label TextPainters ─────────────────────────────────────────
    _labelPainters = [
      for (final l in labels)
        (TextPainter(
          text: TextSpan(
            text: l,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout()),
    ];
  }

  final List<double> values;
  final List<String> labels;
  final Color color;
  final double clipProgress;
  final double _maxValue;

  static double _calculateMaxValue(List<double> values) {
    if (values.isEmpty) return 1.0;
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    return maxVal == 0.0 ? 1.0 : maxVal * 1.2;
  }

  late final List<TextPainter> _labelPainters;

  // ── Cached paints ─────────────────────────────────────────────────────────
  static final _gridPaint = Paint()
    ..color = AppColors.glassBorder
    ..strokeWidth = 0.5;

  // ── Layout constants ─────────────────────────────────────────────────────
  static const _labelHeight = 20.0;
  static const _gridLines = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final chartH = size.height - _labelHeight;
    final chartW = size.width;

    // Clip for left-to-right reveal
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, chartW * clipProgress, size.height));

    // ── 1. Grid lines ─────────────────────────────────────────────────────
    for (var i = 1; i <= _gridLines; i++) {
      final y = chartH * (1 - i / _gridLines);
      canvas.drawLine(Offset(0, y), Offset(chartW, y), _gridPaint);
    }

    if (values.length < 2) {
      canvas.restore();
      return;
    }

    final n = values.length;
    final xStep = chartW / (n - 1);

    // Map values → canvas points
    final pts = [
      for (var i = 0; i < n; i++)
        Offset(i * xStep, chartH * (1 - values[i] / _maxValue)),
    ];

    // ── 2. Filled area below line ──────────────────────────────────────────
    final fillPath = _buildCubicPath(pts);
    fillPath
      ..lineTo(pts.last.dx, chartH)
      ..lineTo(pts.first.dx, chartH)
      ..close();

    final fillShader = ui.Gradient.linear(
      Offset(0, 0),
      Offset(0, chartH),
      [color.withValues(alpha: 0.23), color.withValues(alpha: 0.0)],
    );
    canvas.drawPath(fillPath, Paint()..shader = fillShader);

    // ── 3. Cubic bezier line ───────────────────────────────────────────────
    final linePath = _buildCubicPath(pts);
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // ── 4. Dots ────────────────────────────────────────────────────────────
    final dotFill = Paint()..color = Colors.white;
    final dotStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final pt in pts) {
      canvas.drawCircle(pt, 4, dotFill);
      canvas.drawCircle(pt, 4, dotStroke);
    }

    canvas.restore();

    // ── 5. Labels (drawn outside clip so they don't get cut off) ──────────
    final labelInterval = (n > 10) ? (n / 5).round() : 1;

    for (var i = 0; i < math.min(n, _labelPainters.length); i++) {
      if (i % labelInterval != 0 && i != n - 1) {
        continue;
      }
      final tp = _labelPainters[i];
      final x = (i * xStep) - tp.width / 2;
      tp.paint(canvas, Offset(x.clamp(0, chartW - tp.width), chartH + 4));
    }
  }

  /// Builds a smooth cubic Bezier [Path] through [pts].
  static Path _buildCubicPath(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
      final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i + 1].dx, pts[i + 1].dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(_LineChartPainter old) {
    if (old.clipProgress != clipProgress) return true;
    if (old.values.length != values.length) return true;
    for (var i = 0; i < values.length; i++) {
      if (old.values[i] != values[i]) return true;
    }
    return false;
  }
}

// ============================================================================
// PfBarChart
// ============================================================================

/// Pure [CustomPainter] bar chart — zero fl_chart dependency.
///
/// Bars animate from height=0 to full height via a [TweenAnimationBuilder]
/// `progress` multiplier.
class PfBarChart extends StatelessWidget {
  const PfBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 200,
    this.color = AppColors.primaryBlue,
  });

  final List<double> values;
  final List<String> labels;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    return RepaintBoundary(
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 850),
          curve: Curves.easeOutCubic,
          builder: (context, progress, _) {
            return CustomPaint(
              painter: _BarChartPainter(
                values: values,
                labels: labels,
                color: color,
                progress: progress,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.values,
    required this.labels,
    required this.color,
    required this.progress,
  }) : _maxValue = _calculateMaxValue(values) {
    _labelPainters = [
      for (final l in labels)
        (TextPainter(
          text: TextSpan(
            text: l,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout()),
    ];
  }

  final List<double> values;
  final List<String> labels;
  final Color color;
  final double progress;
  final double _maxValue;

  static double _calculateMaxValue(List<double> values) {
    if (values.isEmpty) return 1.0;
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    return maxVal == 0.0 ? 1.0 : maxVal * 1.2;
  }

  late final List<TextPainter> _labelPainters;

  static final _gridPaint = Paint()
    ..color = AppColors.glassBorder
    ..strokeWidth = 0.5;

  static const _labelHeight = 20.0;
  static const _gridLines = 4;
  static const _barWidth = 22.0;
  static const _barRadius = Radius.circular(AppSpacing.radiusSm / 2);

  @override
  void paint(Canvas canvas, Size size) {
    final chartH = size.height - _labelHeight;
    final chartW = size.width;
    final n = values.length;
    if (n == 0) return;

    // ── 1. Grid lines ─────────────────────────────────────────────────────
    for (var i = 1; i <= _gridLines; i++) {
      final y = chartH * (1 - i / _gridLines);
      canvas.drawLine(Offset(0, y), Offset(chartW, y), _gridPaint);
    }

    final slotW = chartW / n;

    for (var i = 0; i < n; i++) {
      final barH = (chartH * (values[i] / _maxValue) * progress).clamp(0.0, chartH);
      final cx = slotW * i + slotW / 2;
      final left = cx - _barWidth / 2;
      final top = chartH - barH;

      // ── 2. Gradient bar ───────────────────────────────────────────────
      final barRect = Rect.fromLTWH(left, top, _barWidth, barH);
      final shader = ui.Gradient.linear(
        Offset(0, top),
        Offset(0, chartH),
        [
          AppColors.primaryBlue,
          AppColors.primaryPurple.withValues(alpha: 0.5),
        ],
      );
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          barRect,
          topLeft: _barRadius,
          topRight: _barRadius,
        ),
        Paint()..shader = shader,
      );

      // ── 3. Labels ──────────────────────────────────────────────────────
      if (i < _labelPainters.length) {
        final tp = _labelPainters[i];
        tp.paint(
          canvas,
          Offset((cx - tp.width / 2).clamp(0, chartW - tp.width), chartH + 4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) {
    if (old.progress != progress) return true;
    if (old.values.length != values.length) return true;
    for (var i = 0; i < values.length; i++) {
      if (old.values[i] != values[i]) return true;
    }
    return false;
  }
}

// ============================================================================
// TrendBadge
// ============================================================================

class TrendBadge extends StatelessWidget {
  const TrendBadge({super.key, required this.trend});

  final double trend;

  @override
  Widget build(BuildContext context) {
    final isPositive = trend >= 0;
    final trendColor = isPositive ? AppColors.success : AppColors.error;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: trendColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm / 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              size: 14,
              color: trendColor,
            ),
            const SizedBox(width: 4),
            Text(
              '${isPositive ? '+' : ''}${trend.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: trendColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Legacy type aliases (keeps existing call-sites compiling)
// ============================================================================

/// @deprecated Use [PfLineChart] instead.
typedef WeeklyLineChart = PfLineChart;

/// @deprecated Use [PfBarChart] instead.
typedef CalorieBarChart = PfBarChart;
