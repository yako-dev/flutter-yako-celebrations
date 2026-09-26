import 'package:flutter/material.dart';
import 'package:yako_celebrations/yako_celebrations.dart';

import 'theme.dart';

/// Describes one ready-made tier for the gallery.
class TierInfo {
  /// Creates the info.
  const TierInfo(this.tier, this.code, this.blurb, this.subtitle, this.color);

  /// The tier.
  final CelebrationTier tier;

  /// How you write it in code, after `CelebrationTier.`.
  final String code;

  /// What it does.
  final String blurb;

  /// A sample subtitle to show with it.
  final String? subtitle;

  /// The tier's colour in the gallery.
  final Color color;
}

/// The code-drawn tiers, smallest first.
const List<TierInfo> tierInfos = <TierInfo>[
  TierInfo(CelebrationTier.subtle, 'subtle',
      'A quick sparkle and a small chime.', null, Color(0xFF40C4FF)),
  TierInfo(CelebrationTier.nice, 'nice',
      'Title pop, a confetti burst and sparkles.', null, Color(0xFF00E676)),
  TierInfo(
      CelebrationTier.great,
      'great',
      'Title slam, light rays, confetti cannons, streamers.',
      '+50 XP',
      Color(0xFF448AFF)),
  TierInfo(
      CelebrationTier.epic,
      'epic',
      'Flames, coins, fireworks, a storm of your icon, flash and shake.',
      '+500 XP',
      Color(0xFFB14DFF)),
  TierInfo(
      CelebrationTier.legendary,
      'legendary',
      'Rainbow flames, a wall of fire, giant icons, fireworks. Everything.',
      'NEW RECORD',
      Color(0xFFFFB300)),
];

/// The Lottie tiers, smallest first.
const List<TierInfo> lottieTierInfos = <TierInfo>[
  TierInfo(CelebrationTier.lottieSubtle, 'lottieSubtle',
      'Light rays and a confetti pop.', null, Color(0xFF859FFF)),
  TierInfo(
      CelebrationTier.lottieNice,
      'lottieNice',
      'Turning violet rays, streamers, a firework cluster.',
      null,
      Color(0xFFB981FF)),
  TierInfo(CelebrationTier.lottieGreat, 'lottieGreat',
      'Gold title, confetti and fireworks.', '+50 XP', Color(0xFFFFD36B)),
  TierInfo(
      CelebrationTier.lottieEpic,
      'lottieEpic',
      'Fire, a coin rain, fireworks, a warm flash and shake.',
      '+500 XP',
      Color(0xFFFFA726)),
  TierInfo(
      CelebrationTier.lottieLegendary,
      'lottieLegendary',
      'A wall of flames, coins in both corners, fireworks everywhere.',
      'NEW RECORD',
      Color(0xFFFFC53D)),
];

const List<String> _sizes = <String>[
  'Subtle',
  'Nice',
  'Great',
  'Epic',
  'Legendary',
];

const List<IconData> _icons = <IconData>[
  Icons.auto_awesome_rounded,
  Icons.celebration_rounded,
  Icons.emoji_events_rounded,
  Icons.local_fire_department_rounded,
  Icons.workspace_premium_rounded,
];

/// Every ready-made tier; tap one to play it.
class GalleryPage extends StatefulWidget {
  /// Creates the gallery.
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  bool _lottie = false;
  TierInfo _last = tierInfos[3];

  void _play(TierInfo info) {
    setState(() => _last = info);
    YakoCelebration.show(context, tier: info.tier, subtitle: info.subtitle);
  }

  @override
  Widget build(BuildContext context) {
    final infos = _lottie ? lottieTierInfos : tierInfos;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: <Widget>[
        const Text(
          'Five sizes, two styles. Tap one to play it.',
          style: TextStyle(color: AppColors.muted, fontSize: 15),
        ),
        const SizedBox(height: 18),
        _StyleSwitch(
          lottie: _lottie,
          onChanged: (v) => setState(() => _lottie = v),
        ),
        const SizedBox(height: 16),
        for (final info in infos) ...<Widget>[
          _TierTile(info: info, onTap: () => _play(info)),
          const SizedBox(height: 10),
        ],
        const SectionLabel('In your code'),
        AppCard(
          child: Text(
            'YakoCelebration.show(\n'
            '  context,\n'
            '  tier: CelebrationTier.${_last.code},\n'
            ');',
            style: const TextStyle(
              fontFamily: 'Menlo',
              fontFamilyFallback: <String>['Roboto Mono', 'monospace'],
              fontSize: 13,
              height: 1.5,
              color: AppColors.muted,
            ),
          ),
        ),
      ],
    );
  }
}

/// Classic (drawn in code) or Lottie.
class _StyleSwitch extends StatelessWidget {
  const _StyleSwitch({required this.lottie, required this.onChanged});

  final bool lottie;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget option(String label, bool value) {
      final selected = lottie == value;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.surfaceHigh : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.faint,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: <Widget>[
          option('Classic', false),
          option('Lottie', true),
        ],
      ),
    );
  }
}

class _TierTile extends StatelessWidget {
  const _TierTile({required this.info, required this.onTap});

  final TierInfo info;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final level = info.tier.level;
    final color = info.color;
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.12),
        highlightColor: color.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      color.withValues(alpha: 0.95),
                      color.withValues(alpha: 0.45),
                    ],
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(_icons[level], color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            _sizes[level],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _Meter(level: level, color: color),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      info.blurb,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.16),
                    ),
                    child:
                        Icon(Icons.play_arrow_rounded, color: color, size: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${info.tier.config.seconds.toStringAsFixed(1)} s',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.faint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Five little bars: how big the tier is.
class _Meter extends StatelessWidget {
  const _Meter({required this.level, required this.color});

  final int level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        for (var i = 0; i < 5; i++)
          Container(
            width: 4,
            height: 6.0 + i * 2,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: i <= level ? color : AppColors.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }
}
