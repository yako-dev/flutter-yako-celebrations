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

/// The ready-made config for Lottie tier [level].
CelebrationConfig lottiePresetConfig(int level) => _lottiePresets[level];

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

// ---------------------------------------------------------------------------
// The Lottie ladder: designer-made Lottie animations (LottieFiles, Lottie
// Simple License) laid out in the top band and along the bottom edge, with an
// edge vignette, a title that slams in at 0.25 s with a light sweep, a flash
// and a shake. Every rung is longer, darker at the edges, slams from further,
// shakes harder and flashes brighter than the one below.

final List<CelebrationConfig> _lottiePresets = <CelebrationConfig>[
  _lottieSubtle(),
  _lottieNice(),
  _lottieGreat(),
  _lottieEpic(),
  _lottieLegendary(),
];

const Color _indigo = Color(0xFF859FFF);
const Color _violet = Color(0xFFB981FF);
const Color _warmGold = Color(0xFFFFD36B);
const Alignment _topTitle = Alignment(0, -0.58);

/// The gold title, left to right.
const List<Color> _goldTitle = <Color>[
  Color(0xFFFFB020),
  Color(0xFFFFE9A8),
  Color(0xFFFFFFFF),
  Color(0xFFFFE9A8),
  Color(0xFFFF9A1F),
];

/// A light title with a coloured glow: pale tints of [c] around white.
List<Color> _lightTitle(Color c) {
  final pale = Color.lerp(c, const Color(0xFFFFFFFF), 0.72)!;
  final light = Color.lerp(c, const Color(0xFFFFFFFF), 0.45)!;
  return <Color>[light, pale, const Color(0xFFFFFFFF), pale, light];
}

/// Seconds after the start at which every Lottie tier's title lands.
const double lottieImpactSeconds = 0.35;

TitleSlamEffect _lottieTitle(
    double total, double from, List<Color> colors, Color glow,
    {double fontSize = 0.9}) {
  const probe = TitleSlamEffect(slamDuration: 0.55);
  return TitleSlamEffect(
    slamFrom: from,
    slamDuration: probe.slamDuration,
    fontSize: fontSize,
    alignment: _topTitle,
    colors: colors,
    glowColor: glow,
    shimmer: true,
    start: _slamStart(lottieImpactSeconds, total, probe),
    end: _at(total - 0.1, total),
  );
}

EdgeGlowEffect _vignette(double dim) => EdgeGlowEffect(
      strength: (dim * 1.4).clamp(0.0, 1.0),
      pulse: 0,
      palette: const CelebrationPalette(<Color>[Color(0xFF000000)]),
    );

LottieEffect _fx(
  CelebrationLottie animation,
  LottieAnchor anchor,
  double start,
  double end,
  double total, {
  double scale = 1,
  bool loop = true,
  double opacity = 1,
  Color? tint,
  double spinTurns = 0,
  BoxFit? fit,
  bool fadeBottom = false,
}) =>
    LottieEffect(
      animation,
      anchor: anchor,
      scale: scale,
      loop: loop,
      opacity: opacity,
      tint: tint,
      spinTurns: spinTurns,
      fit: fit,
      fadeBottom: fadeBottom,
      start: _at(start, total),
      end: _at(end, total),
    );

ShakeEffect _hit(double start, double length, double strength, double total) =>
    ShakeEffect(
      strength: strength,
      start: _at(start, total),
      end: _at(start + length, total),
    );

FlashEffect _flash(
        double start, double length, Color color, double peak, double total) =>
    FlashEffect(
      strength: peak,
      color: color,
      start: _at(start, total),
      end: _at(start + length, total),
    );

CelebrationConfig _lottieSubtle() {
  const total = 2.4;
  return CelebrationConfig(
    duration: _seconds(total),
    title: 'NICE',
    color: _indigo,
    effects: <CelebrationEffect>[
      _vignette(0.08),
      _fx(CelebrationLottie.lightRays, LottieAnchor.topBand, 0, 2.3, total,
          scale: 0.34, opacity: 0.22, tint: _indigo),
      _fx(CelebrationLottie.confetti, LottieAnchor.topBand, 0.1, 1.8, total,
          scale: 0.3, loop: false, fit: BoxFit.contain),
      _lottieTitle(total, 1.3, _lightTitle(_indigo), _indigo, fontSize: 0.75),
      _flash(0, 0.25, _indigo, 0.25, total),
      _hit(0, 0.25, 2, total),
    ],
    sound: const CelebrationSound.builtIn(CelebrationTier.lottieSubtle),
    haptics: CelebrationHaptics(<HapticPulse>[
      HapticPulse(_at(lottieImpactSeconds, total), CelebrationHapticKind.light),
    ]),
  );
}

CelebrationConfig _lottieNice() {
  const total = 3.0;
  return CelebrationConfig(
    duration: _seconds(total),
    title: 'SWEET!',
    color: _violet,
    effects: <CelebrationEffect>[
      _vignette(0.12),
      _fx(CelebrationLottie.lightRays, LottieAnchor.topBand, 0, 2.9, total,
          scale: 0.38, opacity: 0.28, tint: _violet, spinTurns: 0.12),
      _fx(CelebrationLottie.streamerBurst, LottieAnchor.topBand, 0.2, 2.8,
          total,
          scale: 0.32, loop: false),
      _fx(CelebrationLottie.fireworksCluster, LottieAnchor.topBand, 0.3, 2.7,
          total,
          scale: 0.28, loop: false, fit: BoxFit.contain),
      _lottieTitle(total, 1.45, _lightTitle(_violet), _violet, fontSize: 0.8),
      _flash(0, 0.3, _violet, 0.3, total),
      _hit(0, 0.3, 4, total),
    ],
    sound: const CelebrationSound.builtIn(CelebrationTier.lottieNice),
    haptics: CelebrationHaptics(<HapticPulse>[
      HapticPulse(
          _at(lottieImpactSeconds, total), CelebrationHapticKind.medium),
    ]),
  );
}

CelebrationConfig _lottieGreat() {
  const total = 3.6;
  return CelebrationConfig(
    duration: _seconds(total),
    title: 'BIG WIN',
    color: const Color(0xFFFFC53D),
    effects: <CelebrationEffect>[
      _vignette(0.15),
      _fx(CelebrationLottie.lightRays, LottieAnchor.topBand, 0, 3.4, total,
          scale: 0.4, opacity: 0.25, tint: const Color(0xFFFFE9A8)),
      _fx(CelebrationLottie.confetti, LottieAnchor.topBand, 0.05, 2.0, total,
          scale: 0.42, loop: false),
      _fx(CelebrationLottie.fireworks, LottieAnchor.topBand, 0.3, 2.0, total,
          scale: 0.42, loop: false),
      _lottieTitle(total, 1.6, _goldTitle, const Color(0xFFFF8A00)),
      _flash(0, 0.3, const Color(0xFFFFFFFF), 0.35, total),
      _hit(0, 0.35, 5, total),
    ],
    sound: const CelebrationSound.builtIn(CelebrationTier.lottieGreat),
    haptics: CelebrationHaptics(<HapticPulse>[
      HapticPulse(
          _at(lottieImpactSeconds, total), CelebrationHapticKind.medium),
      HapticPulse(_at(0.65, total), CelebrationHapticKind.light),
    ]),
  );
}

CelebrationConfig _lottieEpic() {
  const total = 5.2;
  return CelebrationConfig(
    duration: _seconds(total),
    title: 'MASSIVE',
    color: const Color(0xFFFFC53D),
    showBrandBadge: true,
    effects: <CelebrationEffect>[
      _vignette(0.25),
      _fx(CelebrationLottie.lightRays, LottieAnchor.topBand, 0, 5.0, total,
          scale: 0.42, opacity: 0.35, tint: _warmGold, spinTurns: 0.25),
      _fx(CelebrationLottie.fireBurst, LottieAnchor.bottomEdge, 0.1, 3.0, total,
          scale: 0.7),
      _fx(CelebrationLottie.fireworks, LottieAnchor.topBand, 0.35, 4.6, total,
          scale: 0.42),
      _fx(CelebrationLottie.coinRain, LottieAnchor.topBand, 0.7, 5.0, total,
          scale: 0.36, fit: BoxFit.contain, fadeBottom: true),
      _fx(CelebrationLottie.fireworksCluster, LottieAnchor.topLeft, 0.9, 4.8,
          total,
          scale: 0.7),
      _lottieTitle(total, 2.0, _goldTitle, const Color(0xFFFF8A00),
          fontSize: 1),
      _flash(0, 0.4, const Color(0xFFFFE7B0), 0.55, total),
      _hit(0, 0.55, 9, total),
      _hit(0.45, 0.3, 5, total),
    ],
    sound: const CelebrationSound.builtIn(CelebrationTier.lottieEpic),
    haptics: CelebrationHaptics(<HapticPulse>[
      HapticPulse(_at(lottieImpactSeconds, total), CelebrationHapticKind.heavy),
      HapticPulse(_at(0.8, total), CelebrationHapticKind.medium),
      HapticPulse(_at(1.3, total), CelebrationHapticKind.light),
    ]),
  );
}

CelebrationConfig _lottieLegendary() {
  const total = 8.0;
  return CelebrationConfig(
    duration: _seconds(total),
    title: 'LEGENDARY',
    color: const Color(0xFFFFC53D),
    showBrandBadge: true,
    effects: <CelebrationEffect>[
      _vignette(0.35),
      _fx(CelebrationLottie.lightRays, LottieAnchor.topBand, 0, 7.8, total,
          scale: 0.42, opacity: 0.6, tint: _warmGold, spinTurns: 0.35),
      _fx(CelebrationLottie.fireBurst, LottieAnchor.bottomEdge, 0.1, 4.2, total,
          scale: 0.9),
      _fx(CelebrationLottie.flameWall, LottieAnchor.bottomEdge, 0.15, 7.6,
          total,
          scale: 0.8, opacity: 0.9, fit: BoxFit.fill),
      _fx(CelebrationLottie.fireworks, LottieAnchor.topBand, 0.35, 7.0, total,
          scale: 0.42),
      _fx(CelebrationLottie.fireworksCluster, LottieAnchor.topLeft, 0.9, 7.2,
          total,
          scale: 0.8),
      _fx(CelebrationLottie.fireworksCluster, LottieAnchor.topRight, 1.6, 7.4,
          total,
          scale: 0.8),
      _fx(CelebrationLottie.coinRain, LottieAnchor.topLeft, 0.7, 7.8, total,
          scale: 0.5, fit: BoxFit.contain, fadeBottom: true),
      _fx(CelebrationLottie.coinRain, LottieAnchor.topRight, 0.9, 7.8, total,
          scale: 0.5, fit: BoxFit.contain, fadeBottom: true),
      _lottieTitle(total, 2.4, _goldTitle, const Color(0xFFFF8A00),
          fontSize: 1.05),
      _flash(0, 0.55, const Color(0xFFFFFFFF), 0.9, total),
      _flash(2.2, 0.35, _warmGold, 0.35, total),
      _hit(0, 0.9, 16, total),
      _hit(0.45, 0.4, 8, total),
      _hit(2.2, 0.5, 7, total),
    ],
    sound: const CelebrationSound.builtIn(CelebrationTier.lottieLegendary),
    haptics: CelebrationHaptics(<HapticPulse>[
      HapticPulse(_at(lottieImpactSeconds, total), CelebrationHapticKind.heavy),
      HapticPulse(_at(0.8, total), CelebrationHapticKind.heavy),
      HapticPulse(_at(1.4, total), CelebrationHapticKind.medium),
      HapticPulse(_at(2.2, total), CelebrationHapticKind.heavy),
      HapticPulse(_at(3.0, total), CelebrationHapticKind.light),
    ]),
  );
}
