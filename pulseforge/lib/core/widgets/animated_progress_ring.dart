import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

// ---------------------------------------------------------------------------
// AnimatedProgressRing
// ---------------------------------------------------------------------------

/// GPU-driven progress ring using an explicit [AnimationController].
///
/// Key performance choices:
/// * Explicit [AnimationController] + [CurvedAnimation] instead of
///   [TweenAnimationBuilder] — avoids rebuilding the Widget tree on every tick.
/// * [_RingPainter] caches the gradient shader and background [Paint] so they
///   are not recreated per frame.
/// * [RepaintBoundary] ensures only this subtree is repainted on progress ticks.
class AnimatedProgressRing extends StatefulWidget {
  const AnimatedProgressRing({
    super.key,
    required this.progress,
    required this.size,
    this.strokeWidth = 10,
    this.child,
    this.gradient,
    this.showGlow = true,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Widget? child;
  final Gradient? gradient;

  /// When `true` a soft blurred glow arc is painted behind the progress arc.
  final bool showGlow;

  @override
  State<AnimatedProgressRing> createState() => _AnimatedProgressRingState();
}

class _AnimatedProgressRingState extends State<AnimatedProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late CurvedAnimation _curved;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _curved = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.animateTo(widget.progress.clamp(0.0, 1.0));
  }

  @override
  void didUpdateWidget(AnimatedProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _controller.animateTo(
        widget.progress.clamp(0.0, 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.gradient ?? AppColors.primaryGradient;

    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _curved,
          builder: (context, child) {
            return CustomPaint(
              painter: _RingPainter(
                progress: _curved.value,
                strokeWidth: widget.strokeWidth,
                gradient: gradient,
                showGlow: widget.showGlow,
                // Pass the total size so the painter can cache a correct shader.
                paintSize: Size(widget.size, widget.size),
              ),
              child: child,
            );
          },
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _RingPainter
// ---------------------------------------------------------------------------

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.gradient,
    required this.showGlow,
    required this.paintSize,
  }) {
    // ── Precompute rect & shader once per painter instance ──────────────────
    final center = Offset(paintSize.width / 2, paintSize.height / 2);
    final radius = (paintSize.width - strokeWidth) / 2;
    _rect = Rect.fromCircle(center: center, radius: radius);
    _shader = gradient.createShader(_rect);
  }

  final double progress;
  final double strokeWidth;
  final Gradient gradient;
  final bool showGlow;
  final Size paintSize;

  late final Rect _rect;
  late final Shader _shader;

  // Background track — static, shared across instances.
  static final Paint _trackPaint = Paint()
    ..color = AppColors.surfaceLight
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    // Update stroke width on the shared paint (cheap field write).
    _trackPaint.strokeWidth = strokeWidth;

    // 1. Draw background track
    canvas.drawArc(_rect, 0, math.pi * 2, false, _trackPaint);

    if (progress <= 0) return;

    final sweepAngle = math.pi * 2 * progress;
    const startAngle = -math.pi / 2;

    // 2. Optional glow arc (blurred, behind the main arc)
    if (showGlow) {
      final glowPaint = Paint()
        ..shader = _shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 2.4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..color = AppColors.primaryBlue.withValues(alpha: 0.0); // shader takes over
      // Reduce alpha to 30% by compositing
      canvas.saveLayer(
        _rect.inflate(strokeWidth * 2),
        Paint()..color = const Color(0x4DFFFFFF),
      );
      canvas.drawArc(_rect, startAngle, sweepAngle, false, glowPaint);
      canvas.restore();
    }

    // 3. Main progress arc (gradient)
    final fgPaint = Paint()
      ..shader = _shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(_rect, startAngle, sweepAngle, false, fgPaint);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
