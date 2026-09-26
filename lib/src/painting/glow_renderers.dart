// Internal: not exported from the package.
// ignore_for_file: public_member_api_docs

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../effects.dart';
import '../palette.dart';
import 'kit.dart';
import 'renderer.dart';

/// Darkens the screen behind everything.
class DimRenderer extends EffectRenderer {
  DimRenderer(this.strength, double total) : super(0, 1, total);

  final double strength;
  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size, double now) {
    final a =
        strength * windowEnvelope(now, startS, endS, fadeIn: 0.3, fadeOut: 0.5);
    if (a <= 0.004) return;
    canvas.drawPaint(_paint..color = AlphaRamp.black.at(a));
  }
}

/// A full-screen flash that peaks at the start of its window.
class FlashRenderer extends EffectRenderer {
  FlashRenderer(FlashEffect effect, double total)
      : strength = effect.strength,
        _ramp = AlphaRamp(effect.color),
        super(effect.start, math.max(effect.end, effect.start + 0.05 / total),
            total);

  final double strength;
  final AlphaRamp _ramp;
  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size, double now) {
    final u = (now - startS) / span;
    final rise = 0.06;
    final double a;
    if (u < rise) {
      a = strength * (u / rise);
    } else {
      final v = 1 - (u - rise) / (1 - rise);
      a = strength * v * v;
    }
    if (a <= 0.004) return;
    canvas.drawPaint(_paint..color = _ramp.at(a));
  }
}

/// A soft coloured vignette at the screen edges.
class EdgeGlowRenderer extends EffectRenderer {
  EdgeGlowRenderer(EdgeGlowEffect effect, CelebrationPalette palette,
      Color accent, double total)
      : strength = effect.strength,
        pulse = effect.pulse,
        _ramp = ColorRamp.of(palette, accent),
        super(effect.start, effect.end, total);

  final double strength;
  final double pulse;
  final ColorRamp _ramp;
  final Paint _paint = Paint();
  final Map<int, ui.Shader> _shaders = <int, ui.Shader>{};
  Size _shaderSize = Size.zero;

  ui.Shader _shaderFor(int slot, Size size) {
    if (size != _shaderSize) {
      _shaders.clear();
      _shaderSize = size;
    }
    return _shaders.putIfAbsent(slot, () {
      final color = _ramp.solid(slot);
      final radius = size.longestSide * 0.62 + size.shortestSide * 0.2;
      return ui.Gradient.radial(
        size.center(Offset.zero),
        radius,
        <Color>[
          color.withValues(alpha: 0),
          color.withValues(alpha: 0),
          color.withValues(alpha: 0.55),
          color,
        ],
        const <double>[0, 0.58, 0.86, 1],
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size, double now) {
    var a = strength *
        windowEnvelope(now, startS, endS, fadeIn: 0.25, fadeOut: 0.6);
    if (pulse > 0) a *= 0.72 + 0.28 * math.sin(now * pulse * 2 * math.pi);
    if (a <= 0.004) return;
    // Rainbow edges drift slowly around the wheel.
    final slot = _ramp.cycles ? _ramp.slot(0, now) ~/ 3 * 3 : 0;
    _paint
      ..shader = _shaderFor(slot, size)
      ..color = AlphaRamp.white.at(a);
    canvas.drawPaint(_paint);
  }

  @override
  void dispose() => _shaders.clear();
}

/// Turning beams of light and a soft glow behind the title.
class LightRaysRenderer extends EffectRenderer {
  LightRaysRenderer(LightRaysEffect effect, CelebrationPalette palette,
      Color accent, double total)
      : rays = math.max(3, effect.rays),
        size = effect.size,
        spin = effect.spin,
        opacity = effect.opacity,
        alignment = effect.alignment,
        _ramp = ColorRamp.of(palette, accent),
        _accent = palette.representative(accent),
        super(effect.start, effect.end, total) {
    _main = _wedges(rays, 0, 0.42);
    _thin = _wedges(rays, math.pi / rays, 0.18);
  }

  final int rays;
  final double size;
  final double spin;
  final double opacity;
  final Alignment alignment;
  final ColorRamp _ramp;
  final Color _accent;
  late final Path _main;
  late final Path _thin;
  final Paint _rayPaint = Paint();
  final Paint _glowPaint = Paint();
  final Map<int, ui.Shader> _rayShaders = <int, ui.Shader>{};
  late final ui.Shader _glowShader = ui.Gradient.radial(
    Offset.zero,
    1,
    <Color>[
      const Color(0xFFFFFFFF),
      _accent.withValues(alpha: 0.7),
      _accent.withValues(alpha: 0),
    ],
    const <double>[0, 0.35, 1],
  );

  static Path _wedges(int count, double offset, double width) {
    final path = Path();
    final half = math.pi / count * width;
    for (var k = 0; k < count; k++) {
      final a = offset + 2 * math.pi * k / count;
      path
        ..moveTo(0, 0)
        ..lineTo(math.cos(a - half), math.sin(a - half))
        ..lineTo(math.cos(a + half), math.sin(a + half))
        ..close();
    }
    return path;
  }

  ui.Shader _rayShader(int slot) => _rayShaders.putIfAbsent(slot, () {
        final color = _ramp.cycles ? _ramp.solid(slot) : _accent;
        final light = Color.lerp(color, const Color(0xFFFFFFFF), 0.55)!;
        return ui.Gradient.radial(
          Offset.zero,
          1,
          <Color>[
            light,
            color.withValues(alpha: 0.5),
            color.withValues(alpha: 0)
          ],
          const <double>[0.05, 0.4, 1],
        );
      });

  @override
  void paint(Canvas canvas, Size size, double now) {
    final t = now - startS;
    final env = windowEnvelope(now, startS, endS, fadeIn: 0.3, fadeOut: 0.6);
    if (env <= 0) return;
    final grow = easeOutBack(t / 0.5, 1.4);
    final cx = (alignment.x + 1) / 2 * size.width;
    final cy = (alignment.y + 1) / 2 * size.height;
    final reach = 0.5 *
        math.sqrt(size.width * size.width + size.height * size.height) *
        this.size *
        grow;
    final slot = _ramp.cycles ? _ramp.slot(0, now) ~/ 3 * 3 : 0;
    final turn = spin * t * 2 * math.pi;

    canvas
      ..save()
      ..translate(cx, cy)
      ..rotate(turn)
      ..scale(reach);
    _rayPaint
      ..shader = _rayShader(slot)
      ..color = AlphaRamp.white.at(opacity * env);
    canvas
      ..drawPath(_main, _rayPaint)
      ..rotate(-2.6 * turn);
    _rayPaint.color = AlphaRamp.white.at(opacity * env * 0.7);
    canvas
      ..drawPath(_thin, _rayPaint)
      ..restore();

    final glow = size.shortestSide * 0.42 * this.size * grow;
    _glowPaint
      ..shader = _glowShader
      ..color = AlphaRamp.white.at(opacity * env * 0.9);
    canvas
      ..save()
      ..translate(cx, cy)
      ..scale(glow)
      ..drawCircle(Offset.zero, 1, _glowPaint)
      ..restore();
  }

  @override
  void dispose() => _rayShaders.clear();
}

/// Four-pointed stars that twinkle.
class SparklesRenderer extends EffectRenderer {
  SparklesRenderer(SparklesEffect effect, CelebrationPalette palette,
      Color accent, double total, int seed)
      : count = math.max(0, effect.count),
        _ramp = ColorRamp.of(palette, accent),
        super(effect.start, effect.end, total) {
    final rng = SeededRandom(seed);
    final b = areaBounds(effect.area);
    final cx = (b[0] + b[2]) / 2;
    final cy = (b[1] + b[3]) / 2;
    _x = Float64List(count);
    _y = Float64List(count);
    _dx = Float64List(count);
    _dy = Float64List(count);
    _delay = Float64List(count);
    _life = Float64List(count);
    _size = Float64List(count);
    _spin = Float64List(count);
    _phase = Float64List(count);
    _twinkle = Float64List(count);
    for (var i = 0; i < count; i++) {
      _x[i] = rng.range(b[0], b[2]);
      _y[i] = rng.range(b[1], b[3]);
      _dx[i] = (_x[i] - cx) * 0.35;
      _dy[i] = (_y[i] - cy) * 0.35 - 0.01;
      final life = math.min(rng.range(0.4, 0.95), span * 0.9);
      _life[i] = math.max(0.2, life);
      _delay[i] = math.pow(rng.next(), 1.5) * math.max(0, span - _life[i]);
      _size[i] = rng.range(0.016, 0.04) * effect.size;
      _spin[i] = rng.range(-1.6, 1.6);
      _phase[i] = rng.range(0, math.pi * 2);
      _twinkle[i] = rng.range(9, 17);
    }
  }

  final int count;
  final ColorRamp _ramp;
  final GlowBrush _glow = GlowBrush();
  final Paint _paint = Paint();
  late final Float64List _x,
      _y,
      _dx,
      _dy,
      _delay,
      _life,
      _size,
      _spin,
      _phase,
      _twinkle;

  @override
  void paint(Canvas canvas, Size size, double now) {
    final s = size.shortestSide;
    final fade = windowEnvelope(now, startS, endS, fadeIn: 0.01, fadeOut: 0.25);
    for (var i = 0; i < count; i++) {
      final t = now - startS - _delay[i];
      if (t < 0 || t > _life[i]) continue;
      final u = t / _life[i];
      final env = math.pow(math.sin(math.pi * u), 0.8).toDouble();
      final tw = 0.7 + 0.3 * math.sin(t * _twinkle[i] + _phase[i]);
      final a = env * tw * fade;
      if (a <= 0.01) continue;
      final r = _size[i] * s * env * (0.85 + 0.15 * tw);
      final x = (_x[i] + _dx[i] * t) * size.width;
      final y = (_y[i] + _dy[i] * t) * size.height;
      final slot = _ramp.slot(i, now);
      canvas.drawCircle(Offset(x, y), r * 0.8,
          _glow.forRadius(r * 1.6, _ramp.base(slot, a * 0.55)));
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(_phase[i] + _spin[i] * t)
        ..scale(r)
        ..drawPath(Shapes.star4, _paint..color = _ramp.light(slot, a))
        ..scale(0.55)
        ..drawPath(Shapes.star4, _paint..color = AlphaRamp.white.at(a))
        ..restore();
    }
  }
}
