// Internal: not exported from the package.
// ignore_for_file: public_member_api_docs

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../effects.dart';
import '../palette.dart';

/// A tiny deterministic random source (xorshift32).
///
/// Uses only shifts and xors, so it gives the same numbers on every platform.
class SeededRandom {
  SeededRandom(int seed) : _state = _scramble(seed) {
    for (var i = 0; i < 6; i++) {
      next();
    }
  }

  int _state;

  static int _scramble(int seed) {
    var x = (seed ^ 0x6C8E9CF5) & 0xFFFFFFFF;
    x = (x ^ (x >> 16)) & 0xFFFFFFFF;
    return x == 0 ? 0x9E3779B9 : x;
  }

  /// A number in [0, 1).
  double next() {
    var x = _state;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= x >> 17;
    x ^= (x << 5) & 0xFFFFFFFF;
    _state = x & 0xFFFFFFFF;
    return _state / 4294967296.0;
  }

  double range(double min, double max) => min + (max - min) * next();

  int nextInt(int max) => math.min(max - 1, (next() * max).floor());

  bool chance(double probability) => next() < probability;
}

/// Colours of one palette, prepared once with 32 opacity steps each so
/// painting never has to create a [Color].
class ColorRamp {
  ColorRamp._(this._bases, this.cycles, this.hueSpeed, Color lightTarget) {
    for (final base in _bases) {
      final light = Color.lerp(base, lightTarget, 0.5)!;
      final dark = Color.lerp(base, const Color(0xFF000000), 0.3)!;
      final mid = Color.lerp(base, const Color(0xFF000000), 0.12)!;
      final deep = Color.lerp(base, const Color(0xFF000000), 0.55)!;
      for (var level = 0; level < levels; level++) {
        final a = level / (levels - 1);
        _base.add(base.withValues(alpha: a));
        _light.add(light.withValues(alpha: a));
        _dark.add(dark.withValues(alpha: a));
        _mid.add(mid.withValues(alpha: a));
        _deep.add(deep.withValues(alpha: a));
      }
    }
  }

  /// Builds the ramp for [palette], with [accent] standing in for
  /// [CelebrationPalette.accent]. Light shades lean towards [lightTarget].
  factory ColorRamp.of(
    CelebrationPalette palette,
    Color accent, {
    Color lightTarget = const Color(0xFFFFFFFF),
  }) {
    final resolved = palette.resolve(accent);
    if (resolved.cycleHues) {
      final hues = <Color>[
        for (var i = 0; i < 36; i++)
          HSVColor.fromAHSV(1, i * 10.0, 0.82, 1).toColor(),
      ];
      return ColorRamp._(hues, true, resolved.hueSpeed, lightTarget);
    }
    final colors = resolved.colors.isEmpty
        ? const <Color>[Color(0xFFFFFFFF)]
        : resolved.colors;
    return ColorRamp._(colors, false, 0, lightTarget);
  }

  static const int levels = 32;

  final List<Color> _bases;
  final bool cycles;
  final double hueSpeed;
  final List<Color> _base = <Color>[];
  final List<Color> _light = <Color>[];
  final List<Color> _dark = <Color>[];
  final List<Color> _deep = <Color>[];
  final List<Color> _mid = <Color>[];

  int get length => _bases.length;

  /// The colour slot for particle [i] at [now] seconds (hue shifts over time
  /// for cycling palettes).
  int slot(int i, double now) {
    if (!cycles) return i % length;
    return (i + (now * hueSpeed * length).floor()) % length;
  }

  static int _q(double opacity) {
    if (opacity <= 0) return 0;
    if (opacity >= 1) return levels - 1;
    return (opacity * (levels - 1)).round();
  }

  Color base(int slot, double opacity) => _base[slot * levels + _q(opacity)];
  Color light(int slot, double opacity) => _light[slot * levels + _q(opacity)];
  Color dark(int slot, double opacity) => _dark[slot * levels + _q(opacity)];
  Color deep(int slot, double opacity) => _deep[slot * levels + _q(opacity)];
  Color mid(int slot, double opacity) => _mid[slot * levels + _q(opacity)];

  /// The unshaded colour of [slot].
  Color solid(int slot) => _bases[slot];
}

/// One colour at 32 opacity steps.
class AlphaRamp {
  AlphaRamp(Color color)
      : _colors = List<Color>.generate(
          ColorRamp.levels,
          (i) => color.withValues(alpha: i / (ColorRamp.levels - 1)),
        );

  final List<Color> _colors;

  Color at(double opacity) => _colors[ColorRamp._q(opacity)];

  static final AlphaRamp white = AlphaRamp(const Color(0xFFFFFFFF));
  static final AlphaRamp hot = AlphaRamp(const Color(0xFFFFF4C8));
  static final AlphaRamp black = AlphaRamp(const Color(0xFF000000));
}

/// Blurred paints for soft glows, one per blur size, made once.
class GlowBrush {
  GlowBrush() {
    for (final sigma in _sigmas) {
      _paints
          .add(Paint()..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma));
    }
  }

  static const List<double> _sigmas = <double>[
    1.5, 3, 5, 8, 12, 18, 26, 38, 54, 76 //
  ];

  final List<Paint> _paints = <Paint>[];

  /// A paint whose blur suits a glow of about [radius] pixels, in [color].
  Paint forRadius(double radius, Color color) {
    final wanted = radius * 0.45;
    var index = _sigmas.length - 1;
    for (var i = 0; i < _sigmas.length; i++) {
      if (_sigmas[i] >= wanted) {
        index = i;
        break;
      }
    }
    return _paints[index]..color = color;
  }
}

/// Normalised bounds (left, top, right, bottom) of an area.
List<double> areaBounds(CelebrationArea area) => switch (area) {
      CelebrationArea.fullScreen => const <double>[0.04, 0.04, 0.96, 0.96],
      CelebrationArea.topBand => const <double>[0.06, 0.05, 0.94, 0.4],
      CelebrationArea.center => const <double>[0.18, 0.26, 0.82, 0.6],
      CelebrationArea.bottomBand => const <double>[0.04, 0.66, 0.96, 0.98],
    };

double clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

double easeOutCubic(double t) {
  final u = 1 - clamp01(t);
  return 1 - u * u * u;
}

double easeOutBack(double t, [double overshoot = 1.70158]) {
  final u = clamp01(t) - 1;
  return 1 + (overshoot + 1) * u * u * u + overshoot * u * u;
}

/// A 0→1→0 envelope over a window: rises over [fadeIn] seconds after [start],
/// falls over [fadeOut] seconds before [end].
double windowEnvelope(
  double now,
  double start,
  double end, {
  double fadeIn = 0.15,
  double fadeOut = 0.4,
}) {
  if (now < start || now > end) return 0;
  final span = end - start;
  final inLen = math.min(fadeIn, span * 0.5);
  final outLen = math.min(fadeOut, span * 0.5);
  var v = 1.0;
  if (inLen > 0 && now - start < inLen) v = (now - start) / inLen;
  if (outLen > 0 && end - now < outLen) v = math.min(v, (end - now) / outLen);
  return clamp01(v);
}

/// Unit shapes, built once and drawn with canvas transforms.
abstract final class Shapes {
  /// A flame: tip at (0, -0.95), round bottom at y = 0.36, about 0.84 wide,
  /// with a small side tongue.
  static final Path flame = Path()
    ..moveTo(0, -0.95)
    ..cubicTo(0.08, -0.66, 0.42, -0.46, 0.42, -0.06)
    ..cubicTo(0.42, 0.22, 0.23, 0.36, 0, 0.36)
    ..cubicTo(-0.23, 0.36, -0.42, 0.22, -0.42, -0.06)
    ..cubicTo(-0.42, -0.3, -0.24, -0.42, -0.13, -0.6)
    ..cubicTo(-0.08, -0.7, -0.03, -0.8, 0, -0.95)
    ..close()
    ..moveTo(-0.33, -0.66)
    ..cubicTo(-0.2, -0.5, -0.12, -0.38, -0.2, -0.16)
    ..cubicTo(-0.36, -0.24, -0.42, -0.42, -0.33, -0.66)
    ..close();

  /// A wide, soft flame tongue for the fire wall: tip at (0, -1), bottom at
  /// y = 0.3, one unit wide.
  static final Path tongue = Path()
    ..moveTo(0, -1)
    ..cubicTo(0.1, -0.74, 0.5, -0.56, 0.5, -0.2)
    ..cubicTo(0.5, 0.1, 0.3, 0.3, 0, 0.3)
    ..cubicTo(-0.3, 0.3, -0.5, 0.1, -0.5, -0.2)
    ..cubicTo(-0.5, -0.48, -0.16, -0.62, 0, -1)
    ..close();

  /// The lighter middle of a flame.
  static final Path flameMid = Path()
    ..moveTo(0.02, -0.6)
    ..cubicTo(0.1, -0.4, 0.29, -0.26, 0.29, 0.02)
    ..cubicTo(0.29, 0.2, 0.16, 0.3, 0, 0.3)
    ..cubicTo(-0.16, 0.3, -0.29, 0.2, -0.29, 0.02)
    ..cubicTo(-0.29, -0.2, -0.12, -0.34, 0.02, -0.6)
    ..close();

  /// The hot core of a flame.
  static final Path flameCore = Path()
    ..moveTo(0, -0.25)
    ..cubicTo(0.07, -0.12, 0.16, -0.02, 0.16, 0.1)
    ..cubicTo(0.16, 0.2, 0.09, 0.26, 0, 0.26)
    ..cubicTo(-0.09, 0.26, -0.16, 0.2, -0.16, 0.1)
    ..cubicTo(-0.16, -0.02, -0.07, -0.12, 0, -0.25)
    ..close();

  /// A four-pointed twinkle star with radius 1.
  static final Path star4 = Path()
    ..moveTo(0, -1)
    ..quadraticBezierTo(0.13, -0.13, 1, 0)
    ..quadraticBezierTo(0.13, 0.13, 0, 1)
    ..quadraticBezierTo(-0.13, 0.13, -1, 0)
    ..quadraticBezierTo(-0.13, -0.13, 0, -1)
    ..close();

  /// A five-pointed star with radius 1.
  static final Path star5 = _star5();

  /// A crescent of light on the upper left of a unit circle.
  static final Path shine = Path()
    ..moveTo(-0.62, -0.1)
    ..cubicTo(-0.62, -0.46, -0.36, -0.7, -0.02, -0.72)
    ..cubicTo(-0.3, -0.6, -0.48, -0.4, -0.5, -0.02)
    ..close();

  /// A unit square centred on the origin.
  static const Rect unitSquare = Rect.fromLTRB(-0.5, -0.5, 0.5, 0.5);

  /// A unit square from the origin to (1, 1).
  static const Rect unitBox = Rect.fromLTRB(0, 0, 1, 1);

  static Path _star5() {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? 1.0 : 0.46;
      final a = -math.pi / 2 + i * math.pi / 5;
      final x = r * math.cos(a);
      final y = r * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path..close();
  }
}

/// A radial gradient of radius 1 around the origin. Scale the canvas to size
/// it; the paint's colour alpha fades it.
ui.Shader unitRadialGlow(Color color, {double core = 0.0}) =>
    ui.Gradient.radial(
      Offset.zero,
      1,
      <Color>[
        color,
        color.withValues(alpha: color.a * 0.45),
        color.withValues(alpha: 0),
      ],
      <double>[core, 0.4, 1],
    );
