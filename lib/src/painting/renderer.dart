// Internal: not exported from the package.
// ignore_for_file: public_member_api_docs

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

/// Draws one effect straight onto a canvas, as a pure function of time.
///
/// Every particle's position is worked out from its fixed random parameters
/// and the current second, so the same time always gives the same frame
/// (slow motion, scrubbing and tests all see the same thing). Renderers keep
/// their paints, paths and number buffers for their whole life, so painting a
/// frame creates no garbage beyond a few tiny offsets.
abstract class EffectRenderer {
  EffectRenderer(double start, double end, double total)
      : startS = start * total,
        endS = end * total;

  /// When the effect starts, in seconds from the start of the celebration.
  final double startS;

  /// When the effect must be gone, in seconds.
  final double endS;

  /// Length of the effect's window in seconds.
  double get span => endS - startS;

  /// Whether anything can be visible at [now].
  bool isActive(double now) => now >= startS && now <= endS;

  /// Paints the effect at [now] seconds.
  void paint(Canvas canvas, Size size, double now);

  /// Frees shaders and pictures.
  void dispose() {}
}

/// Paints a group of renderers every tick of [progress].
class EffectsPainter extends CustomPainter {
  EffectsPainter({
    required this.progress,
    required this.totalSeconds,
    required this.renderers,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final double totalSeconds;
  final List<EffectRenderer> renderers;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final now = progress.value * totalSeconds;
    for (final renderer in renderers) {
      if (renderer.isActive(now)) renderer.paint(canvas, size, now);
    }
  }

  @override
  bool shouldRepaint(EffectsPainter oldDelegate) =>
      !identical(oldDelegate.renderers, renderers) ||
      oldDelegate.totalSeconds != totalSeconds ||
      oldDelegate.progress != progress;
}
