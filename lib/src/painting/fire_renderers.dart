// Internal: not exported from the package.
// ignore_for_file: public_member_api_docs

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../effects.dart';
import '../palette.dart';
import '../presets.dart' show fireworkRiseSeconds, fireworkSparkSeconds;
import 'kit.dart';
import 'renderer.dart';

/// Firework shells that rise, burst into streaking sparks and fade.
///
/// Shells launch at even steps across the window, so their bursts can be
/// lined up with a sound.
class FireworksRenderer extends EffectRenderer {
  FireworksRenderer(FireworksEffect effect, CelebrationPalette palette,
      Color accent, double total, int seed)
      : shells = math.max(0, effect.shells),
        sparks = math.max(4, effect.sparks),
        _ramp = ColorRamp.of(palette, accent),
        super(effect.start, effect.end, total) {
    final rng = SeededRandom(seed);
    final area = areaBounds(effect.area);
    final usable = span - fireworkRiseSeconds - fireworkSparkSeconds;
    final gap = shells > 1 ? math.max(0.0, usable) / (shells - 1) : 0.0;
    _launch = Float64List(shells);
    _x = Float64List(shells);
    _y = Float64List(shells);
    _radius = Float64List(shells);
    _angle = Float64List(shells * sparks);
    _speed = Float64List(shells * sparks);
    final offset = rng.next();
    for (var i = 0; i < shells; i++) {
      _launch[i] = startS + i * gap;
      // Golden-ratio steps spread the shells evenly without a visible pattern.
      final spread = (offset + i * 0.618034) % 1.0;
      _x[i] = area[0] + 0.1 + (area[2] - area[0] - 0.2) * spread;
      _y[i] =
          rng.range(area[1] + 0.04, math.max(area[1] + 0.05, area[3] - 0.06));
      _radius[i] = rng.range(0.19, 0.29) * effect.size;
      for (var j = 0; j < sparks; j++) {
        _angle[i * sparks + j] =
            2 * math.pi * j / sparks + rng.range(-0.09, 0.09);
        _speed[i * sparks + j] = rng.range(0.72, 1.0);
      }
    }
    for (var group = 0; group < 2; group++) {
      final n = (sparks - group + 1) ~/ 2;
      _lines.add(Float32List(n * 4));
      _heads.add(Float32List(n * 2));
    }
  }

  final int shells;
  final int sparks;
  final ColorRamp _ramp;
  final GlowBrush _glow = GlowBrush();
  final Paint _streak = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _head = Paint()..strokeCap = StrokeCap.round;
  late final Float64List _launch, _x, _y, _radius, _angle, _speed;
  final List<Float32List> _lines = <Float32List>[];
  final List<Float32List> _heads = <Float32List>[];
  final Float32List _trail = Float32List(4);
  final Float32List _rocketHead = Float32List(2);

  @override
  bool isActive(double now) =>
      shells > 0 &&
      now >= startS &&
      now <= _launch[shells - 1] + fireworkRiseSeconds + fireworkSparkSeconds;

  double _riseY(double u, double burstY, double height) {
    final e = 1 - (1 - u) * (1 - u);
    return height * 1.02 + (burstY - height * 1.02) * e;
  }

  @override
  void paint(Canvas canvas, Size size, double now) {
    final s = size.shortestSide;
    for (var i = 0; i < shells; i++) {
      final t = now - _launch[i];
      if (t < 0 || t > fireworkRiseSeconds + fireworkSparkSeconds) continue;
      final slot = _ramp.slot(i * 7, now);
      final bx = _x[i] * size.width;
      final by = _y[i] * size.height;
      if (t < fireworkRiseSeconds) {
        _paintRocket(canvas, size, t / fireworkRiseSeconds, bx, by, slot, s);
      } else {
        _paintBurst(canvas, i, t - fireworkRiseSeconds, bx, by, slot, s);
      }
    }
  }

  void _paintRocket(Canvas canvas, Size size, double u, double x, double burstY,
      int slot, double s) {
    final y = _riseY(u, burstY, size.height);
    final tail = _riseY(math.max(0, u - 0.22), burstY, size.height);
    _trail
      ..[0] = x
      ..[1] = tail
      ..[2] = x
      ..[3] = y;
    _streak
      ..strokeWidth = s * 0.006
      ..color = _ramp.light(slot, 0.55);
    canvas.drawRawPoints(ui.PointMode.lines, _trail, _streak);
    _rocketHead
      ..[0] = x
      ..[1] = y;
    _head
      ..strokeWidth = s * 0.013
      ..color = AlphaRamp.hot.at(1);
    canvas.drawRawPoints(ui.PointMode.points, _rocketHead, _head);
  }

  void _paintBurst(Canvas canvas, int shell, double t, double bx, double by,
      int slot, double s) {
    final life = fireworkSparkSeconds;
    final u = t / life;
    final fade = math.pow(1 - u, 1.3).toDouble();
    final radius = _radius[shell] * s;
    final sag = 0.5 * 0.22 * s * t * t;
    final spread = 1 - math.exp(-4.2 * t);
    final before = math.max(0.0, t - 0.09);
    final spreadBefore = 1 - math.exp(-4.2 * before);
    final sagBefore = 0.5 * 0.22 * s * before * before;

    // The pop of light at the moment of the burst.
    if (t < 0.22) {
      final k = t / 0.22;
      canvas.drawCircle(Offset(bx, by), radius * 0.3 * math.sqrt(k),
          _glow.forRadius(radius * 0.6, _ramp.light(slot, (1 - k) * 0.9)));
    }
    canvas.drawCircle(Offset(bx, by + sag), radius * 0.55 * spread,
        _glow.forRadius(radius, _ramp.base(slot, 0.18 * fade)));

    // Two groups twinkle out of step once the sparks start to die.
    for (var group = 0; group < 2; group++) {
      final lines = _lines[group];
      final heads = _heads[group];
      var n = 0;
      for (var j = group; j < sparks; j += 2) {
        final k = shell * sparks + j;
        final dx = math.cos(_angle[k]) * _speed[k] * radius;
        final dy = math.sin(_angle[k]) * _speed[k] * radius;
        lines[n * 4] = bx + dx * spreadBefore;
        lines[n * 4 + 1] = by + dy * spreadBefore + sagBefore;
        lines[n * 4 + 2] = bx + dx * spread;
        lines[n * 4 + 3] = by + dy * spread + sag;
        heads[n * 2] = lines[n * 4 + 2];
        heads[n * 2 + 1] = lines[n * 4 + 3];
        n++;
      }
      var a = fade;
      if (u > 0.5) a *= 0.55 + 0.45 * math.sin(t * 38 + group * math.pi);
      _streak
        ..strokeWidth = s * 0.007
        ..color = _ramp.base(slot, a);
      canvas.drawRawPoints(ui.PointMode.lines, lines, _streak);
      _head
        ..strokeWidth = s * 0.013 * (1 - u * 0.5)
        ..color = _ramp.light(slot, a);
      canvas.drawRawPoints(ui.PointMode.points, heads, _head);
    }
  }
}

/// A wall of big flames along the bottom edge, with rising embers.
class FireWallRenderer extends EffectRenderer {
  FireWallRenderer(FireWallEffect effect, CelebrationPalette palette,
      Color accent, double total, int seed)
      : height = effect.height,
        fixedTongues = effect.tongues,
        embers = math.max(0, effect.embers),
        _ramp =
            ColorRamp.of(palette, accent, lightTarget: const Color(0xFFFFD84D)),
        _glowColor = palette.representative(accent),
        super(effect.start, effect.end, total) {
    final rng = SeededRandom(seed);
    for (var i = 0; i < _maxTongues; i++) {
      _jitter[i] = rng.range(-0.25, 0.25);
      _tall[i] = rng.range(0.7, 1.15);
      _wide[i] = rng.range(2.4, 3.4);
      _f1[i] = rng.range(2.2, 3.4);
      _f2[i] = rng.range(4.5, 6.5);
      _f3[i] = rng.range(8, 11);
      _p1[i] = rng.range(0, math.pi * 2);
      _p2[i] = rng.range(0, math.pi * 2);
      _p3[i] = rng.range(0, math.pi * 2);
    }
    _ex = Float64List(embers);
    _es = Float64List(embers);
    _ep = Float64List(embers);
    for (var i = 0; i < embers; i++) {
      _ex[i] = rng.next();
      _es[i] = rng.range(0.25, 0.6);
      _ep[i] = rng.next();
    }
    for (var b = 0; b < _buckets; b++) {
      _emberBuffers.add(Float32List(embers * 2));
    }
  }

  static const int _maxTongues = 32;
  static const int _buckets = 4;
  static const List<double> _layerHeight = <double>[1.0, 0.8, 0.56, 0.3];
  static const List<double> _layerWidth = <double>[1.0, 0.82, 0.62, 0.4];

  final double height;
  final int fixedTongues;
  final int embers;
  final ColorRamp _ramp;
  final Color _glowColor;
  final Paint _bedPaint = Paint();
  final Paint _tonguePaint = Paint();
  final Paint _glowPaint = Paint();
  final Map<int, ui.Shader> _tongueShaders = <int, ui.Shader>{};
  final Paint _emberPaint = Paint()..strokeCap = StrokeCap.round;
  final Float64List _jitter = Float64List(_maxTongues),
      _tall = Float64List(_maxTongues),
      _wide = Float64List(_maxTongues),
      _f1 = Float64List(_maxTongues),
      _f2 = Float64List(_maxTongues),
      _f3 = Float64List(_maxTongues),
      _p1 = Float64List(_maxTongues),
      _p2 = Float64List(_maxTongues),
      _p3 = Float64List(_maxTongues);
  late final Float64List _ex, _es, _ep;
  final List<Float32List> _emberBuffers = <Float32List>[];
  late final ui.Shader _glowShader = ui.Gradient.linear(
    Offset.zero,
    const Offset(0, 1),
    <Color>[
      _glowColor.withValues(alpha: 0),
      _glowColor.withValues(alpha: 0.45),
      _glowColor.withValues(alpha: 0.85),
    ],
    const <double>[0, 0.55, 1],
  );

  /// A gradient in the tongue's own unit space: bright at the root, fading
  /// out towards the tip, so tongues look soft instead of cut out.
  ui.Shader _tongueShader(int layer, int slot) =>
      _tongueShaders.putIfAbsent(layer * 1000 + slot, () {
        final Color root;
        final Color tip;
        switch (layer) {
          case 0:
            root = _ramp.light(slot, 1);
            tip = _ramp.base(slot, 1);
          case 1:
            root = _ramp.light(slot, 1);
            tip = _ramp.base(slot, 1);
          case 2:
            root = _ramp.light(slot, 1);
            tip = _ramp.light(slot, 1);
          default:
            root = AlphaRamp.hot.at(0.85);
            tip = AlphaRamp.hot.at(0.6);
        }
        return ui.Gradient.linear(
          const Offset(0, 0.3),
          const Offset(0, -1),
          <Color>[root, tip, tip.withValues(alpha: layer == 0 ? 0.35 : 0)],
          const <double>[0, 0.55, 1],
        );
      });

  @override
  void dispose() => _tongueShaders.clear();

  @override
  void paint(Canvas canvas, Size size, double now) {
    final t = now - startS;
    final grow = easeOutCubic(t / 0.6);
    final sink =
        endS - now < 0.8 ? math.pow((endS - now) / 0.8, 2).toDouble() : 1.0;
    final env = grow * sink;
    if (env <= 0.01) return;
    final s = size.shortestSide;
    final wallHeight = size.height * height * env;
    final n = fixedTongues > 0
        ? math.min(fixedTongues, _maxTongues)
        : (size.width / (s * 0.1)).round().clamp(6, _maxTongues);
    final column = size.width / n;

    // Warm light rising from the bottom edge.
    final glowHeight = wallHeight * 1.5;
    _glowPaint
      ..shader = _glowShader
      ..color = AlphaRamp.white.at(env);
    canvas
      ..save()
      ..translate(0, size.height - glowHeight)
      ..scale(size.width, glowHeight)
      ..drawRect(Shapes.unitBox, _glowPaint)
      ..restore();

    // A solid bed of fire so the tongues grow out of something.
    final bedHeight = wallHeight * 0.2;
    _bedPaint.color = _ramp.base(_ramp.slot(0, now), 1);
    canvas
      ..save()
      ..translate(0, size.height - bedHeight)
      ..scale(size.width, bedHeight + 1)
      ..drawRect(Shapes.unitBox, _bedPaint)
      ..restore();

    for (var layer = 0; layer < 4; layer++) {
      for (var i = 0; i < n; i++) {
        // Each layer flickers on its own clock and sits a little to the side,
        // so the inner flames never line up with the outer ones.
        final shift = layer * 1.7;
        final noise =
            0.5 * math.sin(now * _f1[i] * (1 + layer * 0.15) + _p1[i] + shift) +
                0.3 * math.sin(now * _f2[i] + _p2[i] + shift) +
                0.2 * math.sin(now * _f3[i] + _p3[i] + shift);
        final h =
            wallHeight * _tall[i] * (0.72 + 0.3 * noise) * _layerHeight[layer];
        final w = column * _wide[i] * _layerWidth[layer];
        final x = (i +
                0.5 +
                _jitter[i] +
                (layer.isOdd ? 0.3 : -0.15) * math.sin(_p3[i] + layer)) *
            column;
        final slot = _ramp.slot(i * 3 + layer, now);
        _tonguePaint.shader = _tongueShader(layer, slot);
        canvas
          ..save()
          ..translate(x, size.height - bedHeight * (0.6 + layer * 0.15))
          ..skew(0.22 * math.sin(now * _f1[i] * 0.6 + _p2[i] + shift), 0)
          ..scale(i.isEven ? w : -w, h)
          ..drawPath(Shapes.tongue, _tonguePaint)
          ..restore();
      }
    }

    // Embers float up out of the wall and fade. Each fade step is one draw
    // call; embers that belong to another step are parked off screen.
    if (embers == 0) return;
    final rise = wallHeight * 2.2;
    for (final buffer in _emberBuffers) {
      buffer.fillRange(0, buffer.length, -1000);
    }
    for (var i = 0; i < embers; i++) {
      final p = (_ep[i] + now * _es[i]) % 1.0;
      final bucket = math.min(_buckets - 1, (p * _buckets).floor());
      final buffer = _emberBuffers[bucket];
      buffer[i * 2] = _ex[i] * size.width + math.sin(now * 3 + i) * s * 0.012;
      buffer[i * 2 + 1] = size.height - p * rise;
    }
    for (var b = 0; b < _buckets; b++) {
      _emberPaint
        ..strokeWidth = s * 0.008
        ..color = _ramp.light(_ramp.slot(b, now), env * (1 - b / _buckets));
      canvas.drawRawPoints(ui.PointMode.points, _emberBuffers[b], _emberPaint);
    }
  }
}
