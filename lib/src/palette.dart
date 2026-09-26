import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// The colours an effect draws with.
///
/// Use one of the ready-made palettes ([gold], [fire], [party], [rainbow],
/// [accent]) or pass your own list:
///
/// ```dart
/// const CelebrationPalette([Color(0xFF00E5FF), Color(0xFF7C4DFF)])
/// ```
///
/// Particles pick colours from [colors] in turn. When [cycleHues] is true the
/// palette ignores [colors] and walks around the whole colour wheel over time
/// instead (that is what [rainbow] does).
@immutable
class CelebrationPalette {
  /// A palette made of [colors].
  ///
  /// An empty [colors] list (without [cycleHues]) draws in white.
  const CelebrationPalette(
    this.colors, {
    this.cycleHues = false,
    this.hueSpeed = 0.3,
  }) : _usesAccent = false;

  const CelebrationPalette._accent()
      : colors = const <Color>[],
        cycleHues = false,
        hueSpeed = 0,
        _usesAccent = true;

  /// Shades of the given [color]: lighter, the colour itself and darker.
  factory CelebrationPalette.shadesOf(Color color) {
    final hsl = HSLColor.fromColor(color);
    Color shade(double lightness, [double saturation = 0]) => hsl
        .withLightness(lightness.clamp(0.0, 1.0))
        .withSaturation((hsl.saturation + saturation).clamp(0.0, 1.0))
        .toColor();
    return CelebrationPalette(<Color>[
      color,
      shade(hsl.lightness + 0.16),
      shade(hsl.lightness - 0.08, 0.05),
      shade(hsl.lightness + 0.28),
    ]);
  }

  /// Warm golds, for coins and trophies.
  static const CelebrationPalette gold = CelebrationPalette(<Color>[
    Color(0xFFFFC62B),
    Color(0xFFFFB300),
    Color(0xFFFFE07A),
    Color(0xFFF59E0B),
  ]);

  /// Reds, oranges and yellows, for flames.
  static const CelebrationPalette fire = CelebrationPalette(<Color>[
    Color(0xFFFF3D00),
    Color(0xFFFF6D00),
    Color(0xFFFF9100),
    Color(0xFFFFAB00),
    Color(0xFFE53935),
  ]);

  /// Bright mixed colours, for confetti and streamers.
  static const CelebrationPalette party = CelebrationPalette(<Color>[
    Color(0xFFFF4081),
    Color(0xFFFFD740),
    Color(0xFF18FFFF),
    Color(0xFF69F0AE),
    Color(0xFFB388FF),
    Color(0xFFFF9100),
    Color(0xFF448AFF),
  ]);

  /// Every hue, shifting over time.
  static const CelebrationPalette rainbow = CelebrationPalette(
    <Color>[],
    cycleHues: true,
    hueSpeed: 0.35,
  );

  /// Shades of the celebration's own colour ([CelebrationConfig.color]).
  ///
  /// This is the default palette of a [CelebrationConfig].
  static const CelebrationPalette accent = CelebrationPalette._accent();

  /// The colours particles pick from, in turn.
  final List<Color> colors;

  /// Whether to cycle through every hue over time instead of using [colors].
  final bool cycleHues;

  /// How fast the hue turns when [cycleHues] is on, in full turns per second.
  final double hueSpeed;

  final bool _usesAccent;

  /// Whether this is the [accent] palette.
  bool get usesAccent => _usesAccent;

  /// Replaces [accent] with shades of [accentColor]; returns other palettes
  /// unchanged.
  CelebrationPalette resolve(Color accentColor) =>
      _usesAccent ? CelebrationPalette.shadesOf(accentColor) : this;

  /// A colour that stands for the whole palette (used for glows and titles).
  Color representative(Color accentColor) {
    if (_usesAccent) return accentColor;
    if (cycleHues || colors.isEmpty) return const Color(0xFFFF4DD2);
    return colors.first;
  }

  @override
  bool operator ==(Object other) =>
      other is CelebrationPalette &&
      other._usesAccent == _usesAccent &&
      other.cycleHues == cycleHues &&
      other.hueSpeed == hueSpeed &&
      _listEquals(other.colors, colors);

  @override
  int get hashCode =>
      Object.hash(_usesAccent, cycleHues, hueSpeed, Object.hashAll(colors));

  @override
  String toString() {
    if (_usesAccent) return 'CelebrationPalette.accent';
    if (cycleHues) return 'CelebrationPalette.rainbow';
    return 'CelebrationPalette($colors)';
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
