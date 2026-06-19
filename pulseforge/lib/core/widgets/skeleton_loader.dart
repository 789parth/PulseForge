import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

// ---------------------------------------------------------------------------
// SkeletonLoader
// ---------------------------------------------------------------------------

/// High-performance shimmer loader.
///
/// Uses a [CustomPainter] ([ShimmerPainter]) driven by an [AnimationController]
/// via [AnimatedBuilder]. The painter calls [canvas.drawRRect] with a sweeping
/// [LinearGradient] shader — the Container + BoxDecoration subtree from the
/// previous implementation is completely gone, so Flutter never allocates or
/// diffs those objects on the hot path.
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = AppSpacing.radiusSm,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: CustomPaint(
            painter: ShimmerPainter(
              animationValue: _controller.value,
              borderRadius: widget.borderRadius,
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// ShimmerPainter
// ---------------------------------------------------------------------------

/// [CustomPainter] that sweeps a shimmer highlight across an RRect.
///
/// [shouldRepaint] only triggers when [animationValue] changes, keeping
/// repaint granular and avoiding unnecessary layout/paint passes.
class ShimmerPainter extends CustomPainter {
  ShimmerPainter({
    required this.animationValue,
    required this.borderRadius,
  });

  final double animationValue;
  final double borderRadius;

  // Cached base color (never changes).
  static const _baseColor = AppColors.surfaceLight;
  static const _highlightColor = Color(0xFF2C2C2C);

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );

    // Shimmer sweep: the highlight travels from -1.0 to 2.0 over the widget.
    // animationValue ∈ [0, 1] → shimmer center from left to right.
    final shimmerX = size.width * (animationValue * 3 - 1);

    final shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: const [_baseColor, _highlightColor, _baseColor],
      stops: const [0.0, 0.5, 1.0],
      transform: _SlideTransform(shimmerX, size.width),
    ).createShader(Offset.zero & size);

    final paint = Paint()..shader = shader;
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(ShimmerPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

/// A [GradientTransform] that slides the gradient by [dx] pixels.
class _SlideTransform extends GradientTransform {
  const _SlideTransform(this.dx, this.width);

  final double dx;
  final double width;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx - width / 2, 0, 0);
  }
}

// ---------------------------------------------------------------------------
// EmptyState
// ---------------------------------------------------------------------------

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ErrorState
// ---------------------------------------------------------------------------

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
