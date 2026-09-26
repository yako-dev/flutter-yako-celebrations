import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'effects.dart';
import 'haptics.dart';
import 'palette.dart';
import 'sound.dart';

/// Builds one of your own layers on the celebration's clock.
///
/// [progress] runs from 0 to 1 over the celebration and follows slow motion
/// and cancelling like every built-in effect. Your widget is drawn above the
/// particles and below the title, and never receives touches.
typedef CelebrationLayerBuilder = Widget Function(
  BuildContext context,
  Animation<double> progress,
);

/// Everything about how a celebration looks, sounds and feels.
///
/// Every ready-made tier is a [CelebrationConfig]; get one with
/// `CelebrationTier.epic.config` and tweak it with [copyWith], or build your
/// own from scratch:
///
/// ```dart
/// final config = CelebrationConfig(
///   duration: const Duration(seconds: 4),
///   color: Colors.teal,
///   title: 'Level up!',
///   effects: const [
///     TitleSlamEffect(),
///     ConfettiEffect(count: 120),
///     CoinsEffect(count: 40, start: 0.1, end: 0.8),
///     FlashEffect(strength: 0.5, start: 0.03, end: 0.12),
///   ],
///   sound: CelebrationSound.builtIn(CelebrationTier.great),
/// );
/// YakoCelebration.show(context, tier: CelebrationTier.custom(config));
/// ```
@immutable
class CelebrationConfig {
  /// Creates a celebration config.
  const CelebrationConfig({
    this.duration = const Duration(seconds: 3),
    this.effects = const <CelebrationEffect>[],
    this.title,
    this.subtitle,
    this.color = const Color(0xFFFFB300),
    this.palette = CelebrationPalette.accent,
    this.backgroundDim = 0,
    this.sound,
    this.haptics = CelebrationHaptics.none,
    this.showBrandBadge = false,
    this.extraLayers = const <CelebrationLayerBuilder>[],
    this.reducedMotion,
    this.seed,
  }) : assert(backgroundDim >= 0 && backgroundDim <= 1,
            'backgroundDim goes from 0 to 1');

  /// How long the whole celebration lasts.
  final Duration duration;

  /// The effects to run. Their order does not matter: each kind has its own
  /// depth (for example flash on top of everything, rays behind the title).
  final List<CelebrationEffect> effects;

  /// The big title text. `null` or empty shows no title.
  ///
  /// Shown by a [TitleSlamEffect]; if [effects] has none, a default one is
  /// added whenever there is a title.
  final String? title;

  /// A smaller line under the title, e.g. a price or "NEW RECORD".
  final String? subtitle;

  /// The celebration's own colour, used for glows, the title outline and
  /// [CelebrationPalette.accent].
  final Color color;

  /// The default colours of every effect that has no palette of its own.
  final CelebrationPalette palette;

  /// How much to darken the screen behind the effects, from 0 to 1.
  final double backgroundDim;

  /// The sound to play. `null` plays nothing.
  final CelebrationSound? sound;

  /// Haptic taps to play on the celebration's clock.
  final CelebrationHaptics haptics;

  /// Whether to show a small badge with the brand's icon and name at the top.
  final bool showBrandBadge;

  /// Your own layers, drawn on the same clock. See [CelebrationLayerBuilder].
  final List<CelebrationLayerBuilder> extraLayers;

  /// The calm version to show when the user asked for reduced motion.
  ///
  /// `null` builds one automatically; see [toReducedMotion].
  final CelebrationConfig? reducedMotion;

  /// Fixes the random layout (particle positions, pop sizes, ...).
  ///
  /// `null` picks a new layout every time.
  final int? seed;

  /// The length in seconds.
  double get seconds =>
      duration.inMicroseconds / Duration.microsecondsPerSecond;

  /// Roughly how many things are drawn in total. Bigger means busier.
  int get particleCount =>
      effects.fold(0, (sum, effect) => sum + effect.particleCount);

  /// The effects of type [T].
  Iterable<T> effectsOf<T extends CelebrationEffect>() =>
      effects.whereType<T>();

  /// A copy without any effect of type [T].
  CelebrationConfig without<T extends CelebrationEffect>() =>
      copyWith(effects: effects.where((e) => e is! T).toList());

  /// A copy with [extra] added to the effects.
  CelebrationConfig withEffects(List<CelebrationEffect> extra) =>
      copyWith(effects: <CelebrationEffect>[...effects, ...extra]);

  /// A copy with the given fields replaced.
  ///
  /// To remove the title, pass an empty string.
  CelebrationConfig copyWith({
    Duration? duration,
    List<CelebrationEffect>? effects,
    String? title,
    String? subtitle,
    Color? color,
    CelebrationPalette? palette,
    double? backgroundDim,
    CelebrationSound? sound,
    CelebrationHaptics? haptics,
    bool? showBrandBadge,
    List<CelebrationLayerBuilder>? extraLayers,
    CelebrationConfig? reducedMotion,
    int? seed,
  }) {
    return CelebrationConfig(
      duration: duration ?? this.duration,
      effects: effects ?? this.effects,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      color: color ?? this.color,
      palette: palette ?? this.palette,
      backgroundDim: backgroundDim ?? this.backgroundDim,
      sound: sound ?? this.sound,
      haptics: haptics ?? this.haptics,
      showBrandBadge: showBrandBadge ?? this.showBrandBadge,
      extraLayers: extraLayers ?? this.extraLayers,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      seed: seed ?? this.seed,
    );
  }

  /// The version shown when the user turned on reduced motion
  /// (`MediaQuery.disableAnimations`).
  ///
  /// Returns [reducedMotion] if you set one. Otherwise: at most 1.4 seconds,
  /// no flash, no shake, nothing flying around; the title fades in without a
  /// slam, a few sparkles and the edge glow stay, and so do sound, the first
  /// haptic tap and your [extraLayers].
  CelebrationConfig toReducedMotion() {
    final custom = reducedMotion;
    if (custom != null) return custom;
    final seconds = math.min(this.seconds, 1.4);
    final calm = <CelebrationEffect>[];
    for (final effect in effects) {
      switch (effect) {
        case TitleSlamEffect():
          calm.add(TitleSlamEffect(
            slamFrom: 1,
            slamDuration: 0.3,
            fontSize: effect.fontSize,
            style: effect.style,
            subtitleStyle: effect.subtitleStyle,
            alignment: effect.alignment,
            gradient: effect.gradient,
            glow: effect.glow,
            palette: effect.palette,
          ));
        case SparklesEffect():
          calm.add(SparklesEffect(
            count: math.min(effect.count, 10),
            size: effect.size,
            area: effect.area,
            palette: effect.palette,
          ));
        case EdgeGlowEffect():
          calm.add(EdgeGlowEffect(
            strength: effect.strength * 0.6,
            pulse: 0,
            palette: effect.palette,
          ));
        default:
          break;
      }
    }
    final firstPulse = haptics.pulses.isEmpty
        ? CelebrationHaptics.none
        : CelebrationHaptics(<HapticPulse>[
            HapticPulse(0, haptics.pulses.first.kind),
          ]);
    return CelebrationConfig(
      duration: Duration(microseconds: (seconds * 1e6).round()),
      effects: calm,
      title: title,
      subtitle: subtitle,
      color: color,
      palette: palette,
      backgroundDim: backgroundDim * 0.5,
      sound: sound,
      haptics: firstPulse,
      showBrandBadge: showBrandBadge,
      extraLayers: extraLayers,
      seed: seed,
    );
  }

  @override
  String toString() => 'CelebrationConfig(${seconds}s, '
      '${effects.map((e) => e.runtimeType).join(', ')})';
}
