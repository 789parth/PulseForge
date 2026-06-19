import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Performance-optimised background widget.
///
/// The two ambient orbs are drawn by a single [CustomPainter] in one canvas
/// pass rather than via multiple [Positioned] + [Container] subtrees.
/// [_OrbPainter.shouldRepaint] always returns `false` — the background is
/// completely static and never needs a repaint.
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.background : const Color(0xFFF8F9FA),
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F0F1A), AppColors.background],
                stops: [0.0, 0.4],
              )
            : null,
      ),
      child: CustomPaint(
        painter: _OrbPainter(isDark: isDark),
        child: child,
      ),
    );
  }
}

/// Draws both ambient-orb radial gradients in a **single** canvas pass.
///
/// Shaders are stored as instance fields (computed once per paint lifecycle)
/// but [shouldRepaint] always returns `false` so they are computed at most once
/// per [_OrbPainter] instance — and instances are reused across frames.
class _OrbPainter extends CustomPainter {
  const _OrbPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (!isDark) return; // Light mode — no orbs needed

    // --- Orb 1: top-right, purple tint ---
    const orb1Radius = 120.0;
    final orb1Center = Offset(size.width + 60, -80);
    final orb1Shader = ui.Gradient.radial(
      orb1Center,
      orb1Radius,
      [
        const Color(0x268B5CF6), // primaryPurple @ 15% alpha
        const Color(0x008B5CF6),
      ],
    );
    canvas.drawCircle(
      orb1Center,
      orb1Radius,
      Paint()..shader = orb1Shader,
    );

    // --- Orb 2: upper-left, blue tint ---
    const orb2Radius = 90.0;
    final orb2Center = Offset(-40, 120 + orb2Radius);
    final orb2Shader = ui.Gradient.radial(
      orb2Center,
      orb2Radius,
      [
        const Color(0x1F00D4FF), // primaryBlue @ 12% alpha
        const Color(0x0000D4FF),
      ],
    );
    canvas.drawCircle(
      orb2Center,
      orb2Radius,
      Paint()..shader = orb2Shader,
    );
  }

  /// The background is fully static — never request a repaint.
  @override
  bool shouldRepaint(_OrbPainter oldDelegate) => false;
}
