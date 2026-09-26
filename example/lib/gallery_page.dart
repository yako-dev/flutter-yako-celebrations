import 'package:flutter/material.dart';
import 'package:yako_celebrations/yako_celebrations.dart';

/// Describes one ready-made tier for the gallery.
class TierInfo {
  /// Creates the info.
  const TierInfo(this.tier, this.blurb, this.subtitle, this.color);

  /// The tier.
  final CelebrationTier tier;

  /// What it does.
  final String blurb;

  /// A sample subtitle to show with it.
  final String? subtitle;

  /// The card colour.
  final Color color;
}

/// Every ready-made tier, smallest first.
const List<TierInfo> tierInfos = <TierInfo>[
  TierInfo(CelebrationTier.subtle, 'A quick sparkle and a small chime.', null,
      Color(0xFF40C4FF)),
  TierInfo(CelebrationTier.nice, 'Title pop, confetti burst and sparkles.',
      null, Color(0xFF00E676)),
  TierInfo(
      CelebrationTier.great,
      'Title slam, light rays, confetti cannons, streamers.',
      '+50 XP',
      Color(0xFF2979FF)),
  TierInfo(
      CelebrationTier.epic,
      'Flames, coins, fireworks, brand storm, flash and shake.',
      '+500 XP',
      Color(0xFFB14DFF)),
  TierInfo(
      CelebrationTier.legendary,
      'Rainbow flames, fire wall, giant brand pops, fireworks. Everything.',
      'NEW RECORD',
      Color(0xFFFFB300)),
];

/// The Lottie ladder, smallest first.
const List<TierInfo> lottieTierInfos = <TierInfo>[
  TierInfo(CelebrationTier.lottieSubtle, 'Light rays and a confetti pop.', null,
      Color(0xFF859FFF)),
  TierInfo(
      CelebrationTier.lottieNice,
      'Turning violet rays, streamers, a firework cluster.',
      null,
      Color(0xFFB981FF)),
  TierInfo(CelebrationTier.lottieGreat, 'Gold title, confetti and fireworks.',
      '+50 XP', Color(0xFFFFD36B)),
  TierInfo(
      CelebrationTier.lottieEpic,
      'Fire, a coin rain, fireworks, warm flash and shake.',
      '+500 XP',
      Color(0xFFFFA726)),
  TierInfo(
      CelebrationTier.lottieLegendary,
      'Wall of flames, coins in both corners, fireworks everywhere.',
      'NEW RECORD',
      Color(0xFFFFC53D)),
];

/// A card per tier; tap to celebrate.
class GalleryPage extends StatelessWidget {
  /// Creates the gallery.
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        Text(
          'Tap a tier',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'YakoCelebration.show(context, tier: CelebrationTier.epic)',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontFamily: 'monospace', color: Colors.white60),
        ),
        const SizedBox(height: 16),
        for (final info in tierInfos) _TierCard(info: info),
        const SizedBox(height: 16),
        Text(
          'Lottie tiers',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'CelebrationTier.lottieEpic',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontFamily: 'monospace', color: Colors.white60),
        ),
        const SizedBox(height: 16),
        for (final info in lottieTierInfos) _TierCard(info: info),
      ],
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({required this.info});

  final TierInfo info;

  @override
  Widget build(BuildContext context) {
    final seconds = info.tier.config.seconds;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                info.color.withValues(alpha: 0.35),
                info.color.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(color: info.color.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            onTap: () => YakoCelebration.show(
              context,
              tier: info.tier,
              subtitle: info.subtitle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    backgroundColor: info.color,
                    foregroundColor: Colors.black,
                    child: Text('${info.tier.level + 1}'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          info.tier.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(info.blurb),
                        const SizedBox(height: 4),
                        Text(
                          info.tier.isLottie
                              ? '${seconds.toStringAsFixed(1)} s · '
                                  '${info.tier.config.effectsOf<LottieEffect>().length} Lottie layers'
                              : '${seconds.toStringAsFixed(1)} s · '
                                  '${info.tier.config.particleCount} particles',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.play_arrow_rounded, size: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
