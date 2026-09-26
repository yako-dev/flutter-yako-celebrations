// Internal: not exported from the package.
// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../effects.dart';

/// The current screen-shake offset, updated every frame without creating
/// objects (read [dx] and [dy]; [value] builds an [Offset] on demand).
class ShakeNotifier extends ChangeNotifier implements ValueListenable<Offset> {
  double dx = 0;
  double dy = 0;

  @override
  Offset get value => Offset(dx, dy);

  void set(double x, double y) {
    if (x == dx && y == dy) return;
    dx = x;
    dy = y;
    notifyListeners();
  }

  void reset() => set(0, 0);
}

/// Adds up every [ShakeEffect] at [now] seconds into [out].
void computeShake(
  List<ShakeEffect> shakes,
  double totalSeconds,
  double now,
  ShakeNotifier out,
) {
  var x = 0.0;
  var y = 0.0;
  for (final shake in shakes) {
    final start = shake.start * totalSeconds;
    final end = math.max(shake.end * totalSeconds, start + 0.05);
    if (now < start || now > end) continue;
    final t = now - start;
    final u = t / (end - start);
    final decay = (1 - u) * (1 - u);
    final a = shake.strength * decay;
    final w = 2 * math.pi * shake.frequency;
    x += a * (0.7 * math.sin(w * t) + 0.3 * math.sin(w * 1.73 * t + 1.3));
    y += a *
        (0.6 * math.cos(w * 1.31 * t + 0.5) +
            0.4 * math.sin(w * 0.77 * t + 2.1));
  }
  out.set(x, y);
}

/// Paints its child moved by a shake offset; repaints only when it changes.
class RenderShake extends RenderProxyBox {
  RenderShake(this._shake);

  ShakeNotifier _shake;
  ShakeNotifier get shake => _shake;
  set shake(ShakeNotifier value) {
    if (identical(value, _shake)) return;
    if (attached) _shake.removeListener(markNeedsPaint);
    _shake = value;
    if (attached) _shake.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _shake.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _shake.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    context.paintChild(child, offset.translate(_shake.dx, _shake.dy));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    final shift = Offset(_shake.dx, _shake.dy);
    return result.addWithPaintOffset(
      offset: shift,
      position: position,
      hitTest: (result, transformed) =>
          child.hitTest(result, position: transformed),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(Matrix4.translationValues(_shake.dx, _shake.dy, 0));
  }
}
