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
/// Or make your own with [CelebrationTier.custom].
@immutable
class CelebrationTier {
  const CelebrationTier._(this.name, this.level) : _config = null;

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

  /// The tier's name, e.g. `'epic'`.
  final String name;

  /// Position in [values] (0 for [subtle]); -1 for a custom tier.
  final int level;

  final CelebrationConfig? _config;

  /// Whether this tier was made with [CelebrationTier.custom].
  bool get isCustom => _config != null;

  /// Everything about how this tier looks, sounds and feels.
  CelebrationConfig get config => _config ?? presetConfig(level);

  // Tiers compare by identity: the ready-made ones are constants, so
  // `CelebrationTier.epic` is always the same object and works as a key in a
  // `const` map (see `YakoCelebration.configure(sounds: ...)`).

  @override
  String toString() => 'CelebrationTier.$name';
}
