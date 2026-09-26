import 'package:flutter/foundation.dart';

import 'config.dart';
import 'presets.dart';

/// How big a celebration is.
///
/// Five ready-made tiers, each bigger and longer than the one before:
///
/// | Tier | Length | What happens |
/// |---|---|---|
/// | [subtle] | 1.2 s | a quick sparkle and a small chime |
/// | [nice] | 2.2 s | title pop, confetti burst, sparkles |
/// | [great] | 3.4 s | title slam, light rays, confetti cannons, streamers, a few brand pops |
/// | [epic] | 5 s | flames, coins, fireworks, brand storm, flash and shake |
/// | [legendary] | 7.5 s | rainbow flames, fire wall, giant brand pops, fireworks, big flash and shake |
///
/// A second ladder, [lottieValues] (`lottieSubtle` ... `lottieLegendary`),
/// has the same five sizes built from designer-made Lottie animations.
///
/// Or make your own with [CelebrationTier.custom].
@immutable
class CelebrationTier {
  const CelebrationTier._(this.name, this.level, [this.isLottie = false])
      : _config = null;

  /// A tier of your own, made from [config].
  ///
  /// Start from scratch or from a preset:
  ///
  /// ```dart
  /// CelebrationTier.custom(
  ///   CelebrationTier.epic.config.copyWith(title: 'Streak!', color: Colors.pink),
  /// )
  /// ```
  const CelebrationTier.custom(CelebrationConfig config, {this.name = 'custom'})
      : level = -1,
        isLottie = false,
        _config = config;

  /// A quick sparkle and a small chime (about 1 s).
  static const CelebrationTier subtle = CelebrationTier._('subtle', 0);

  /// A small title pop with a burst of confetti (about 2 s).
  static const CelebrationTier nice = CelebrationTier._('nice', 1);

  /// Title slam, light rays, confetti cannons and streamers (about 3.5 s).
  static const CelebrationTier great = CelebrationTier._('great', 2);

  /// Flames, coins, fireworks, a storm of brand pops, flash and shake
  /// (about 5 s).
  static const CelebrationTier epic = CelebrationTier._('epic', 3);

  /// Everything at once: rainbow flames, a wall of fire, giant brand pops,
  /// fireworks, a big flash and shake (about 7.5 s).
  static const CelebrationTier legendary = CelebrationTier._('legendary', 4);

  /// The ready-made tiers, smallest first.
  static const List<CelebrationTier> values = <CelebrationTier>[
    subtle,
    nice,
    great,
    epic,
    legendary,
  ];

  /// Lottie ladder: light rays and a small confetti burst in the top band,
  /// an indigo flash (2.4 s).
  static const CelebrationTier lottieSubtle =
      CelebrationTier._('lottie_subtle', 0, true);

  /// Lottie ladder: turning violet rays, streamers and a firework cluster
  /// (3 s).
  static const CelebrationTier lottieNice =
      CelebrationTier._('lottie_nice', 1, true);

  /// Lottie ladder: gold title, confetti and fireworks (3.6 s).
  static const CelebrationTier lottieGreat =
      CelebrationTier._('lottie_great', 2, true);

  /// Lottie ladder: fire from the bottom, a coin rain, fireworks in the top
  /// band and a corner, a warm flash and shake (5.2 s).
  static const CelebrationTier lottieEpic =
      CelebrationTier._('lottie_epic', 3, true);

  /// Lottie ladder: a wall of flames, coins raining in both top corners,
  /// fireworks everywhere, two flashes and three shakes (8 s).
  static const CelebrationTier lottieLegendary =
      CelebrationTier._('lottie_legendary', 4, true);

  /// The Lottie ladder, smallest first: the same five sizes as [values],
  /// built from designer-made Lottie animations instead of code-drawn
  /// particles.
  static const List<CelebrationTier> lottieValues = <CelebrationTier>[
    lottieSubtle,
    lottieNice,
    lottieGreat,
    lottieEpic,
    lottieLegendary,
  ];

  /// The tier's name, e.g. `'epic'`.
  final String name;

  /// Position in [values] or [lottieValues] (0 for the smallest); -1 for a
  /// custom tier.
  final int level;

  /// Whether this tier is on the Lottie ladder ([lottieValues]).
  final bool isLottie;

  final CelebrationConfig? _config;

  /// Whether this tier was made with [CelebrationTier.custom].
  bool get isCustom => _config != null;

  /// Everything about how this tier looks, sounds and feels.
  CelebrationConfig get config =>
      _config ?? (isLottie ? lottiePresetConfig(level) : presetConfig(level));

  // Tiers compare by identity: the ready-made ones are constants, so
  // `CelebrationTier.epic` is always the same object and works as a key in a
  // `const` map (see `YakoCelebration.configure(sounds: ...)`).

  @override
  String toString() => 'CelebrationTier.$name';
}
