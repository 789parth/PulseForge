import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

/// High-performance glass card that avoids [BackdropFilter] compositing cost.
/// Uses a pure [DecoratedBox] with gradient overlay + a 1-px top-edge highlight.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.borderRadius = AppSpacing.radiusMd,
    this.glowColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double borderRadius;

  /// Optional colored ambient glow rendered as a box-shadow.
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(borderRadius);
    final effectiveGlow = glowColor ?? AppColors.primaryBlue;

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: br,
          color: AppColors.surface,
          // Subtle ambient glow via box shadow
          boxShadow: [
            BoxShadow(
              color: effectiveGlow.withValues(alpha: glowColor != null ? 0.18 : 0.06),
              blurRadius: glowColor != null ? 24 : 16,
              spreadRadius: glowColor != null ? 2 : 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: br,
          child: _GlassInner(
            borderRadius: br,
            padding: padding,
            onTap: onTap,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Inner layer: gradient overlay border + top highlight + tap ripple.
/// Kept as a separate [StatelessWidget] so [RepaintBoundary] above it
/// can isolate the static decoration from the animated ink splash.
class _GlassInner extends StatelessWidget {
  const _GlassInner({
    required this.borderRadius,
    required this.padding,
    required this.onTap,
    required this.child,
  });

  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Widget child;

  // Pre-built static gradient for the border overlay (1-px border simulation).
  static const _borderGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.glassBorder, Color(0x0DFFFFFF)],
    stops: [0.0, 1.0],
  );

  // Pre-built static top-highlight gradient.
  static const _highlightGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0x00FFFFFF), Color(0x26FFFFFF), Color(0x00FFFFFF)],
    stops: [0.0, 0.5, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base fill
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              color: AppColors.glassFill,
            ),
          ),
        ),

        // Gradient border overlay (1-px inset via gradient)
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: _borderGradient,
            ),
          ),
        ),

        // Top edge highlight strip (2 px tall)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: borderRadius.topLeft,
                topRight: borderRadius.topRight,
              ),
              gradient: _highlightGradient,
            ),
          ),
        ),

        // Content + tap ripple
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            splashColor: AppColors.primaryBlue.withValues(alpha: 0.08),
            highlightColor: AppColors.primaryBlue.withValues(alpha: 0.04),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}
