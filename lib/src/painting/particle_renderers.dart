// Internal: not exported from the package.
// ignore_for_file: public_member_api_docs

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/painting.dart';

import '../effects.dart';
import '../palette.dart';
import 'kit.dart';
import 'renderer.dart';

/// Motion shared by confetti, streamers and flames: a launch that slows down
/// with air drag while gravity pulls towards a steady falling speed.
///
/// All values are in "shorter screen side" units per second, so motion looks
/// the same on phones, tablets and desktops.
class _Ballistics {
  _Ballistics(int n)
      : ox = Float64List(n),
        oy = Float64List(n),
        vx = Float64List(n),
        vy = Float64List(n),
        drag = Float64List(n),
        fall = Float64List(n),
        delay = Float64List(n);

  final Float64List ox, oy, vx, vy, drag, fall, delay;

  /// Launches particle [i] from normalised ([x], [y]).
  void set(int i, double x, double y, double speedX, double speedY, double k,
      double terminal, double wait) {
    ox[i] = x;
    oy[i] = y;
    vx[i] = speedX;
    vy[i] = speedY;
    drag[i] = k;
    fall[i] = terminal;
    delay[i] = wait;
  }

  double x(int i, double t, Size size) {
    final k = drag[i];
    return ox[i] * size.width +
        vx[i] * size.shortestSide * (1 - math.exp(-k * t)) / k;
  }

  double y(int i, double t, Size size) {
    final k = drag[i];
    final d = (1 - math.exp(-k * t)) / k;
    return oy[i] * size.height +
        size.shortestSide * (vy[i] * d + fall[i] * (t - d));
  }

  /// Horizontal speed at [t] (shorter-side units per second).
  double speedX(int i, double t) => vx[i] * math.exp(-drag[i] * t);

  /// Fills slot [i] for a [launch] style.
  void launch(
    int i,
    ConfettiLaunch launch,
    SeededRandom rng,
    List<double> area, {
    required double span,
    double speed = 1,
  }) {
    final k = rng.range(1.3, 2.1);
    final terminal = rng.range(0.24, 0.4);
    switch (launch) {
      case ConfettiLaunch.cannons:
        final left = i.isEven;
        final angle = rng.range(50, 82) * math.pi / 180;
        final v = rng.range(1.5, 2.6) * speed;
        final second = i % 3 == 2;
        set(
          i,
          left ? -0.02 : 1.02,
          1.02,
          (left ? 1 : -1) * math.cos(angle) * v,
          -math.sin(angle) * v,
          k,
          terminal,
          (second ? 0.32 : 0) + rng.range(0, 0.08),
        );
      case ConfettiLaunch.burst:
        final cx = (area[0] + area[2]) / 2;
        final cy = (area[1] + area[3]) / 2;
        final angle = -math.pi / 2 + rng.range(-math.pi, math.pi) * 0.9;
        final v = rng.range(0.6, 1.9) * speed;
        set(
            i,
            cx + rng.range(-0.02, 0.02),
            cy + rng.range(-0.02, 0.02),
            math.cos(angle) * v,
            math.sin(angle) * v,
            k,
            terminal,
            rng.range(0, 0.06));
      case ConfettiLaunch.rain:
        set(i, rng.range(area[0], area[2]), -0.04, rng.range(-0.05, 0.05), 0, k,
            terminal * 0.85, rng.range(0, span * 0.6));
    }
  }
}

/// Fluttering paper confetti.
class ConfettiRenderer extends EffectRenderer {
  ConfettiRenderer(ConfettiEffect effect, CelebrationPalette palette,
      Color accent, double total, int seed)
      : count = math.max(0, effect.count),
        _ramp = ColorRamp.of(palette, accent),
        super(effect.start, effect.end, total) {
    final rng = SeededRandom(seed);
    final area = areaBounds(effect.area);
    _motion = _Ballistics(count);
    _w = Float64List(count);
    _h = Float64List(count);
    _shape = Uint8List(count);
    _rot = Float64List(count);
    _spin = Float64List(count);
    _flip = Float64List(count);
    _phase = Float64List(count);
    _sway = Float64List(count);
    _swayF = Float64List(count);
    for (var i = 0; i < count; i++) {
      _motion.launch(i, effect.launch, rng, area, span: span);
      final w = rng.range(0.014, 0.026) * effect.size;
      final pick = rng.next();
      if (pick < 0.6) {
        _shape[i] = 0; // rectangle
        _w[i] = w;
        _h[i] = w * rng.range(0.45, 0.7);
      } else if (pick < 0.85) {
        _shape[i] = 0; // thin strip
        _w[i] = w * 1.5;
        _h[i] = w * 0.22;
      } else {
        _shape[i] = 1; // dot
        _w[i] = w * 0.7;
        _h[i] = w * 0.7;
      }
      _rot[i] = rng.range(0, math.pi * 2);
      _spin[i] = rng.range(-7, 7);
      _flip[i] = rng.range(5, 12);
      _phase[i] = rng.range(0, math.pi * 2);
      _sway[i] = rng.range(0.008, 0.028);
      _swayF[i] = rng.range(1.4, 3.2);
    }
  }

  final int count;
  final ColorRamp _ramp;
  final Paint _paint = Paint();
  late final _Ballistics _motion;
  late final Float64List _w, _h, _rot, _spin, _flip, _phase, _sway, _swayF;
  late final Uint8List _shape;

  @override
  void paint(Canvas canvas, Size size, double now) {
    final s = size.shortestSide;
    final fade = windowEnvelope(now, startS, endS, fadeIn: 0.001, fadeOut: 0.6);
    for (var i = 0; i < count; i++) {
      final t = now - startS - _motion.delay[i];
      if (t < 0) continue;
      final swayIn = math.min(1.0, t * 1.2);
      final x = _motion.x(i, t, size) +
          _sway[i] * s * math.sin(_swayF[i] * t + _phase[i]) * swayIn;
      final y = _motion.y(i, t, size);
      if (y > size.height + s * 0.05 ||
          x < -s * 0.1 ||
          x > size.width + s * 0.1) {
        continue;
      }
      final flip = math.cos(_flip[i] * t + _phase[i]);
      final slot = _ramp.slot(i, now);
      final color = flip >= 0 ? _ramp.base(slot, fade) : _ramp.dark(slot, fade);
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(_rot[i] + _spin[i] * t)
        ..scale(_w[i] * s, _h[i] * s * (0.15 + 0.85 * flip.abs()));
      _paint.color = color;
      if (_shape[i] == 1) {
        canvas.drawCircle(Offset.zero, 0.5, _paint);
      } else {
        canvas.drawRect(Shapes.unitSquare, _paint);
      }
      canvas.restore();
    }
  }
}

/// Long curly ribbons that follow their own path.
class StreamersRenderer extends EffectRenderer {
  StreamersRenderer(StreamersEffect effect, CelebrationPalette palette,
      Color accent, double total, int seed)
      : count = math.max(0, effect.count),
        sizeFactor = effect.size,
        _ramp = ColorRamp.of(palette, accent),
        super(effect.start, effect.end, total) {
    final rng = SeededRandom(seed);
    _motion = _Ballistics(count);
    _step = Float64List(count);
    _phase = Float64List(count);
    _wave = Float64List(count);
    for (var i = 0; i < count; i++) {
      _motion.launch(i, effect.launch, rng, areaBounds(CelebrationArea.center),
          span: span, speed: 1.1);
      _motion.drag[i] = rng.range(1.0, 1.5);
      _motion.fall[i] = rng.range(0.2, 0.3);
      _step[i] = rng.range(0.018, 0.028);
      _phase[i] = rng.range(0, math.pi * 2);
      _wave[i] = rng.range(0.7, 1.2);
    }
  }

  static const int _segments = 20;

  final int count;
  final double sizeFactor;
  final ColorRamp _ramp;
  final Path _path = Path();
  final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  late final _Ballistics _motion;
  late final Float64List _step, _phase, _wave;

  @override
  void paint(Canvas canvas, Size size, double now) {
    final s = size.shortestSide;
    final fade = windowEnvelope(now, startS, endS, fadeIn: 0.001, fadeOut: 0.6);
    final amp = s * 0.024 * sizeFactor;
    _paint.strokeWidth = s * 0.009 * sizeFactor;
    for (var i = 0; i < count; i++) {
      final t = now - startS - _motion.delay[i];
      if (t < 0) continue;
      final headY = _motion.y(i, t, size);
      if (headY > size.height + s * 0.4) continue;
      _path.reset();
      for (var j = 0; j <= _segments; j++) {
        final tj = math.max(0.0, t - j * _step[i]);
        final wave = math.sin(j * 1.1 * _wave[i] - t * 9 + _phase[i]) *
            amp *
            math.min(1.0, j / 3);
        final x = _motion.x(i, tj, size) + wave;
        final y = _motion.y(i, tj, size) + wave * 0.45;
        if (j == 0) {
          _path.moveTo(x, y);
        } else {
          _path.lineTo(x, y);
        }
      }
      _paint.color = _ramp.base(_ramp.slot(i * 2, now), fade);
      canvas.drawPath(_path, _paint);
    }
  }
}

/// Spinning gold coins falling from the top.
class CoinsRenderer extends EffectRenderer {
  CoinsRenderer(CoinsEffect effect, CelebrationPalette palette, Color accent,
      double total, int seed)
      : count = math.max(0, effect.count),
        _ramp =
            ColorRamp.of(palette, accent, lightTarget: const Color(0xFFFFF8E1)),
        super(effect.start, effect.end, total) {
    final rng = SeededRandom(seed);
    final area = areaBounds(effect.area);
    _x = Float64List(count);
    _delay = Float64List(count);
    _vy = Float64List(count);
    _g = Float64List(count);
    _drift = Float64List(count);
    _driftF = Float64List(count);
    _flip = Float64List(count);
    _phase = Float64List(count);
    _tilt = Float64List(count);
    _r = Float64List(count);
    for (var i = 0; i < count; i++) {
      _x[i] = rng.range(area[0], area[2]);
      _delay[i] = math.pow(rng.next(), 1.25) * span * 0.62;
      _vy[i] = rng.range(0.12, 0.45);
      _g[i] = rng.range(0.85, 1.35);
      _drift[i] = rng.range(0.004, 0.02);
      _driftF[i] = rng.range(1.0, 2.4);
      _flip[i] = rng.range(5, 11);
      _phase[i] = rng.range(0, math.pi * 2);
      _tilt[i] = rng.range(-0.4, 0.4);
      _r[i] = rng.range(0.02, 0.036) * effect.size;
    }
  }

  final int count;
  final ColorRamp _ramp;
  final Paint _fill = Paint();
  final Paint _ring = Paint()..style = PaintingStyle.stroke;
  late final Float64List _x,
      _delay,
      _vy,
      _g,
      _drift,
      _driftF,
      _flip,
      _phase,
      _tilt,
      _r;

  @override
  void paint(Canvas canvas, Size size, double now) {
    final s = size.shortestSide;
    final fade = windowEnvelope(now, startS, endS, fadeIn: 0.001, fadeOut: 0.5);
    for (var i = 0; i < count; i++) {
      final t = now - startS - _delay[i];
      if (t < 0) continue;
      final r = _r[i] * s;
      final y = -r * 1.2 + s * (_vy[i] * t + 0.5 * _g[i] * t * t);
      if (y - r > size.height) continue;
      final x = _x[i] * size.width +
          _drift[i] * s * math.sin(_driftF[i] * t + _phase[i]);
      final angle = _flip[i] * t + _phase[i];
      final face = math.cos(angle);
      final squash = math.max(face.abs(), 0.07);
      final shine = math.max(0.0, math.sin(angle));
      final slot = _ramp.slot(i, now);
      final front = face >= 0;

      canvas
        ..save()
        ..translate(x, y)
        ..rotate(_tilt[i] + 0.25 * math.sin(t * 1.7 + _phase[i]))
        ..scale(r * squash, r)
        ..drawCircle(Offset.zero, 1, _fill..color = _ramp.deep(slot, fade))
        ..drawCircle(
            Offset.zero,
            0.84,
            _fill
              ..color =
                  front ? _ramp.base(slot, fade) : _ramp.dark(slot, fade));
      _ring
        ..strokeWidth = 0.08
        ..color = _ramp.mid(slot, fade);
      canvas.drawCircle(Offset.zero, 0.62, _ring);
      if (front) {
        canvas
          ..save()
          ..scale(0.34)
          ..drawPath(Shapes.star5, _fill..color = _ramp.light(slot, fade))
          ..restore();
      }
      canvas
        ..drawPath(Shapes.shine,
            _fill..color = AlphaRamp.white.at(fade * (0.25 + 0.6 * shine)))
        ..restore();

      if (shine > 0.96) {
        // A brief glint as the coin turns to face the light.
        final g = (shine - 0.96) / 0.04;
        canvas
          ..save()
          ..translate(x + r * 0.45 * squash, y - r * 0.5)
          ..scale(r * 0.75 * g)
          ..drawPath(Shapes.star4, _fill..color = AlphaRamp.white.at(fade))
          ..restore();
      }
    }
  }
}

/// Little flames bursting out, flickering and drifting.
class FlamesRenderer extends EffectRenderer {
  FlamesRenderer(FlamesEffect effect, CelebrationPalette palette, Color accent,
      double total, int seed)
      : count = math.max(0, effect.count),
        _ramp =
            ColorRamp.of(palette, accent, lightTarget: const Color(0xFFFFE27A)),
        super(effect.start, effect.end, total) {
    final rng = SeededRandom(seed);
    final area = areaBounds(effect.area);
    _motion = _Ballistics(count);
    _life = Float64List(count);
    _h = Float64List(count);
    _p1 = Float64List(count);
    _p2 = Float64List(count);
    for (var i = 0; i < count; i++) {
      switch (effect.area) {
        case CelebrationArea.center:
          final early = i < count * 0.6;
          final angle = -math.pi / 2 + rng.range(-math.pi, math.pi) * 0.92;
          final v = rng.range(0.45, 1.5);
          _motion.set(
            i,
            0.5 + rng.range(-0.03, 0.03),
            0.44 + rng.range(-0.03, 0.03),
            math.cos(angle) * v,
            math.sin(angle) * v,
            rng.range(1.8, 2.6),
            rng.range(0.1, 0.22),
            early
                ? rng.range(0, 0.12)
                : rng.range(0.2, math.max(0.25, span * 0.5)),
          );
        case CelebrationArea.bottomBand:
          final angle = -math.pi / 2 + rng.range(-0.38, 0.38);
          final v = rng.range(1.2, 2.1);
          _motion.set(i, rng.range(area[0], area[2]), 1.04, math.cos(angle) * v,
              math.sin(angle) * v, 0.8, 0.9, rng.range(0, span * 0.65));
        case CelebrationArea.topBand:
          _motion.set(
              i,
              rng.range(area[0], area[2]),
              -0.05,
              rng.range(-0.08, 0.08),
              rng.range(0.1, 0.3),
              0.6,
              0.35,
              rng.range(0, span * 0.65));
        case CelebrationArea.fullScreen:
          _motion.set(
              i,
              rng.range(area[0], area[2]),
              rng.range(0.05, 0.8),
              rng.range(-0.08, 0.08),
              rng.range(-0.1, 0.05),
              0.6,
              0.16,
              rng.range(0, span * 0.65));
      }
      final wanted = rng.range(1.0, 1.8);
      _life[i] = math.max(0.3, math.min(wanted, span - _motion.delay[i]));
      _h[i] = rng.range(0.035, 0.075) * effect.size;
      _p1[i] = rng.range(0, math.pi * 2);
      _p2[i] = rng.range(0, math.pi * 2);
    }
  }

  final int count;
  final ColorRamp _ramp;
  final GlowBrush _glow = GlowBrush();
  final Paint _paint = Paint();
  late final _Ballistics _motion;
  late final Float64List _life, _h, _p1, _p2;

  @override
  void paint(Canvas canvas, Size size, double now) {
    final s = size.shortestSide;
    final fade = windowEnvelope(now, startS, endS, fadeIn: 0.001, fadeOut: 0.3);
    for (var i = 0; i < count; i++) {
      final t = now - startS - _motion.delay[i];
      final life = _life[i];
      if (t < 0 || t > life) continue;
      final u = t / life;
      var scale = t < 0.16 ? easeOutBack(t / 0.16, 2.2) : 1.0;
      if (u > 0.65) scale *= math.pow(1 - (u - 0.65) / 0.35, 0.7).toDouble();
      final a = fade * (u > 0.75 ? 1 - (u - 0.75) / 0.25 : 1.0);
      if (scale <= 0.02 || a <= 0.01) continue;
      final x = _motion.x(i, t, size);
      final y = _motion.y(i, t, size);
      final h = _h[i] * s * scale;
      final lean = (-_motion.speedX(i, t) * 0.35).clamp(-0.5, 0.5) +
          0.12 * math.sin(t * 7 + _p1[i]);
      final stretch = 1 +
          0.13 * math.sin(t * 21 + _p1[i]) +
          0.07 * math.sin(t * 33 + _p2[i]);
      final squeeze = 1 - 0.06 * math.sin(t * 17 + _p2[i]);
      final slot = _ramp.slot(i * 5, now);

      canvas.drawCircle(Offset(x, y - h * 0.15), h * 0.45,
          _glow.forRadius(h * 1.1, _ramp.base(slot, a * 0.45)));
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(lean)
        ..scale(h * squeeze, h * stretch)
        ..drawPath(Shapes.flame, _paint..color = _ramp.base(slot, a))
        ..drawPath(Shapes.flameMid, _paint..color = _ramp.light(slot, a))
        ..drawPath(Shapes.flameCore, _paint..color = AlphaRamp.hot.at(a))
        ..restore();
    }
  }
}
