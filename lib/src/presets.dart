// Internal: not exported from the package.
// ignore_for_file: public_member_api_docs

import 'package:flutter/painting.dart';

import 'config.dart';
import 'effects.dart';
import 'haptics.dart';
import 'palette.dart';
import 'sound.dart';
import 'tier.dart';

// Timings shared with the sound script: tool/sound_timings.json.
// `impact` is the second the title first lands (the big hit in the sound);
// fireworks burst at `firstBurst + i * burstGap`.

/// Seconds a firework shell takes to rise before it bursts.
const double fireworkRiseSeconds = 0.5;

/// Seconds a firework's sparks live after the burst.
const double fireworkSparkSeconds = 1.3;

/// The ready-made config for tier [level] (0 = subtle ... 4 = legendary).
CelebrationConfig presetConfig(int level) => _presets[level];

final List<CelebrationConfig> _presets = <CelebrationConfig>[
  _subtle(),
  _nice(),
  _great(),
  _epic(),
  _legendary(),
];

Duration _seconds(double s) => Duration(microseconds: (s * 1e6).round());

/// Fraction of [total] at which a title slam must start to land at [impact].
double _slamStart(double impact, double total, TitleSlamEffect probe) =>
    ((impact - probe.impactDelay) / total).clamp(0.0, 1.0);

double _at(double seconds, double total) => (seconds / total).clamp(0.0, 1.0);

/// The start/end window that makes [shells] fireworks burst at
/// `firstBurst + i * gap`.
FireworksEffect _fireworks({
  required double firstBurst,
  required double gap,
  required int shells,
  required double total,
  int sparks = 42,
  double size = 1,
  CelebrationPalette? palette,
}) {
  final launch = firstBurst - fireworkRiseSeconds;
  final window =
      (shells - 1) * gap + fireworkRiseSeconds + fireworkSparkSeconds;
  return FireworksEffect(
    shells: shells,
    sparks: sparks,
    size: size,
    palette: palette,
    start: _at(launch, total),
    end: _at(launch + window, total),
  );
}

CelebrationConfig _subtle() {
  const total = 1.2;
  return CelebrationConfig(
    duration: _seconds(total),
    color: const Color(0xFF40C4FF),
    effects: const <CelebrationEffect>[
      LightRaysEffect(rays: 8, size: 0.28, opacity: 0.45, spin: 0.1, end: 0.85),
      SparklesEffect(count: 18, size: 1.2, end: 0.9),
    ],
    sound: const CelebrationSound.builtIn(CelebrationTier.subtle),
    haptics: const CelebrationHaptics(<HapticPulse>[
      HapticPulse(0.04, CelebrationHapticKind.selection),
    ]),
  );
}

CelebrationConfig _nice() {
  const total = 2.2;
  const impact = 0.12;
  const probe = TitleSlamEffect(slamFrom: 1.6, slamDuration: 0.6);
  return CelebrationConfig(
    duration: _seconds(total),
    title: 'Nice!',
    color: const Color(0xFF00E676),
    effects: <CelebrationEffect>[
      TitleSlamEffect(
        slamFrom: probe.slamFrom,
        slamDuration: probe.slamDuration,
        fontSize: 0.8,
        start: _slamStart(impact, total, probe),
      ),
      ConfettiEffect(
        count: 80,
        launch: ConfettiLaunch.burst,
        start: _at(impact - 0.02, total),
      ),
      SparklesEffect(count: 20, start: _at(impact, total), end: 0.85),
    ],
    sound: const CelebrationSound.builtIn(CelebrationTier.nice),
    haptics: CelebrationHaptics(<HapticPulse>[
      HapticPulse(_at(impact, total), CelebrationHapticKind.light),
      HapticPulse(_at(impact + 0.12, total), CelebrationHapticKind.light),
    ]),
  );
}

CelebrationConfig _great() {
  const total = 3.4;
  const impact = 0.25;
  const probe = TitleSlamEffect(slamFrom: 2.0, slamDuration: 0.7);
  return CelebrationConfig(
    duration: _seconds(total),
    title: 'Great!',
    color: const Color(0xFF2979FF),
    backgroundDim: 0.22,
    effects: <CelebrationEffect>[
      TitleSlamEffect(
        slamFrom: probe.slamFrom,
        slamDuration: probe.slamDuration,
        fontSize: 0.9,
        start: _slamStart(impact, total, probe),
      ),
      LightRaysEffect(rays: 10, opacity: 0.35, start: _at(impact, total)),
      ConfettiEffect(count: 140, start: _at(impact - 0.02, total)),
      StreamersEffect(count: 8, start: _at(impact, total)),
      SparklesEffect(count: 26, start: _at(impact, total), end: 0.9),
      BrandPopEffect(
        count: 5,
        maxSize: 0.22,
        start: _at(impact + 0.25, total),
        end: 0.9,
      ),
      EdgeGlowEffect(strength: 0.3, start: _at(impact, total)),
    ],
    sound: const CelebrationSound.builtIn(CelebrationTier.great),
    haptics: CelebrationHaptics(<HapticPulse>[
      HapticPulse(_at(impact, total), CelebrationHapticKind.medium),
      HapticPulse(_at(impact + 0.12, total), CelebrationHapticKind.light),
    ]),
  );
}

CelebrationConfig _epic() {
  const total = 5.0;
  const impact = 0.35;
  const probe = TitleSlamEffect(slamFrom: 2.3, slamDuration: 0.75);
  const firstBurst = 1.35;
  const gap = 0.65;
  return CelebrationConfig(
    duration: _seconds(total),
    title: 'EPIC!',
    color: const Color(0xFFB14DFF),
    backgroundDim: 0.42,
    showBrandBadge: true,
    effects: <CelebrationEffect>[
      TitleSlamEffect(
        slamFrom: probe.slamFrom,
        slamDuration: probe.slamDuration,
        start: _slamStart(impact, total, probe),
      ),
      LightRaysEffect(rays: 12, opacity: 0.5, start: _at(impact, total)),
      FlamesEffect(count: 60, start: _at(impact, total), end: 0.75),
      CoinsEffect(count: 55, start: _at(impact + 0.1, total), end: 0.9),
      ConfettiEffect(count: 160, start: _at(impact - 0.02, total)),
      StreamersEffect(count: 12, start: _at(impact, total)),
      _fireworks(
        firstBurst: firstBurst,
        gap: gap,
        shells: 4,
        total: total,
        palette: CelebrationPalette.party,
      ),
      SparklesEffect(count: 34, start: _at(impact, total), end: 0.92),
      BrandPopEffect(
        count: 12,
        maxSize: 0.38,
        start: _at(impact + 0.2, total),
        end: 0.88,
      ),
      EdgeGlowEffect(strength: 0.5, start: _at(impact, total)),
      FlashEffect(
        strength: 0.45,
        start: _at(impact, total),
        end: _at(impact + 0.35, total),
      ),
      ShakeEffect(
        strength: 8,
        start: _at(impact, total),
        end: _at(impact + 0.55, total),
      ),
    ],
    sound: const CelebrationSound.builtIn(CelebrationTier.epic),
    haptics: CelebrationHaptics(<HapticPulse>[
      HapticPulse(_at(impact, total), CelebrationHapticKind.heavy),
      HapticPulse(_at(impact + 0.1, total), CelebrationHapticKind.medium),
      for (var i = 0; i < 4; i++)
        HapticPulse(
            _at(firstBurst + i * gap, total), CelebrationHapticKind.light),
    ]),
  );
}

CelebrationConfig _legendary() {
  const total = 7.5;
  const impact = 0.5;
  const probe = TitleSlamEffect(slamFrom: 2.6, slamDuration: 0.85);
  const firstBurst = 1.5;
  const gap = 0.6;
  return CelebrationConfig(
    duration: _seconds(total),
    title: 'LEGENDARY!',
    color: const Color(0xFFFFB300),
    palette: CelebrationPalette.rainbow,
    backgroundDim: 0.55,
    showBrandBadge: true,
    effects: <CelebrationEffect>[
      TitleSlamEffect(
        slamFrom: probe.slamFrom,
        slamDuration: probe.slamDuration,
        fontSize: 1.05,
        start: _slamStart(impact, total, probe),
      ),
      LightRaysEffect(
        rays: 16,
        opacity: 0.6,
        size: 1.2,
        start: _at(impact, total),
      ),
      FlamesEffect(
        count: 90,
        size: 1.15,
        palette: CelebrationPalette.rainbow,
        start: _at(impact, total),
        end: 0.7,
      ),
      FlamesEffect(
        count: 50,
        area: CelebrationArea.bottomBand,
        palette: CelebrationPalette.rainbow,
        start: _at(impact + 0.6, total),
        end: 0.9,
      ),
      FireWallEffect(height: 0.3, start: _at(impact - 0.2, total)),
      CoinsEffect(count: 100, size: 1.1, start: _at(impact + 0.1, total)),
      ConfettiEffect(count: 200, start: _at(impact - 0.02, total)),
      ConfettiEffect(
        count: 80,
        launch: ConfettiLaunch.rain,
        area: CelebrationArea.fullScreen,
        start: _at(impact + 1.2, total),
      ),
      StreamersEffect(count: 18, start: _at(impact, total)),
      _fireworks(
        firstBurst: firstBurst,
        gap: gap,
        shells: 8,
        sparks: 48,
        size: 1.15,
        total: total,
      ),
      SparklesEffect(count: 50, size: 1.2, start: _at(impact, total)),
      BrandPopEffect(
        count: 28,
        maxSize: 0.85,
        start: _at(impact + 0.15, total),
        end: 0.9,
      ),
      EdgeGlowEffect(strength: 0.65, start: _at(impact, total)),
      FlashEffect(
        strength: 0.85,
        start: _at(impact, total),
        end: _at(impact + 0.5, total),
      ),
      FlashEffect(
        strength: 0.25,
        start: _at(firstBurst, total),
        end: _at(firstBurst + 0.3, total),
      ),
      ShakeEffect(
        strength: 16,
        start: _at(impact, total),
        end: _at(impact + 0.8, total),
      ),
      ShakeEffect(
        strength: 6,
        start: _at(firstBurst, total),
        end: _at(firstBurst + 0.4, total),
      ),
    ],
    sound: const CelebrationSound.builtIn(CelebrationTier.legendary),
    haptics: CelebrationHaptics(<HapticPulse>[
      HapticPulse(_at(impact, total), CelebrationHapticKind.heavy),
      HapticPulse(_at(impact + 0.08, total), CelebrationHapticKind.heavy),
      HapticPulse(_at(impact + 0.2, total), CelebrationHapticKind.medium),
      for (var i = 0; i < 8; i++)
        HapticPulse(
          _at(firstBurst + i * gap, total),
          i.isEven ? CelebrationHapticKind.medium : CelebrationHapticKind.light,
        ),
    ]),
  );
}
