import 'package:flutter/foundation.dart';

/// The kinds of haptic feedback Flutter offers without any plugin.
enum CelebrationHapticKind {
  /// A tiny tick, like a picker wheel.
  selection,

  /// A light tap.
  light,

  /// A medium tap.
  medium,

  /// A heavy thump.
  heavy,

  /// A short vibration (on phones without fine haptics too).
  vibrate,
}

/// One haptic tap at a moment of the celebration.
@immutable
class HapticPulse {
  /// A tap of [kind] at [at], a fraction (0–1) of the celebration's length.
  const HapticPulse(this.at, [this.kind = CelebrationHapticKind.medium])
      : assert(at >= 0 && at <= 1, 'at is a fraction from 0 to 1');

  /// When to tap, as a fraction (0–1) of the whole celebration.
  final double at;

  /// What kind of tap.
  final CelebrationHapticKind kind;

  @override
  bool operator ==(Object other) =>
      other is HapticPulse && other.at == at && other.kind == kind;

  @override
  int get hashCode => Object.hash(at, kind);

  @override
  String toString() => 'HapticPulse($at, ${kind.name})';
}

/// A pattern of haptic taps, played on the celebration's clock.
///
/// Uses Flutter's built-in `HapticFeedback`, so no plugin is needed. Turn all
/// haptics off app-wide with `YakoCelebration.configure(haptics: false)`.
@immutable
class CelebrationHaptics {
  /// A pattern made of [pulses].
  const CelebrationHaptics(this.pulses);

  /// No haptics.
  static const CelebrationHaptics none = CelebrationHaptics(<HapticPulse>[]);

  /// The taps, in any order.
  final List<HapticPulse> pulses;

  /// Whether there is nothing to play.
  bool get isEmpty => pulses.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is CelebrationHaptics && listEquals(other.pulses, pulses);

  @override
  int get hashCode => Object.hashAll(pulses);

  @override
  String toString() => 'CelebrationHaptics($pulses)';
}
