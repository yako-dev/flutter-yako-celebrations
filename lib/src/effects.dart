import 'package:flutter/painting.dart';

import 'palette.dart';

/// Where on the screen an effect lives.
enum CelebrationArea {
  /// The whole screen.
  fullScreen,

  /// The top part of the screen (roughly the top 40 %).
  topBand,

  /// The middle of the screen, around the title.
  center,

  /// The bottom part of the screen (roughly the bottom 35 %).
  bottomBand,
}

/// How confetti and streamers enter the screen.
enum ConfettiLaunch {
  /// Two cannons in the bottom corners shoot up and inwards.
  cannons,

  /// One burst from the middle of the effect's area, in every direction.
  burst,

  /// Pieces fall from the top edge, fluttering.
  rain,
}

/// One building block of a celebration, such as flames, coins or the title.
///
/// A [CelebrationConfig] is a list of effects plus a few global settings.
/// Every effect runs inside its own time window: [start] and [end] are
/// fractions of [CelebrationConfig.duration], so `start: 0.2, end: 0.8` on a
/// 5 second celebration runs from 1 s to 4 s. Presets scale nicely when you
/// change the duration because of this.
///
/// This class is sealed: the effects below are all there is. To draw
/// something of your own on the same clock, use
/// [CelebrationConfig.extraLayers].
sealed class CelebrationEffect {
  const CelebrationEffect({
    required this.start,
    required this.end,
    this.palette,
  })  : assert(start >= 0 && start <= 1, 'start is a fraction from 0 to 1'),
        assert(end >= 0 && end <= 1, 'end is a fraction from 0 to 1'),
        assert(start <= end, 'start must not be after end');

  /// When the effect begins, as a fraction (0–1) of the whole celebration.
  final double start;

  /// When the effect must be gone, as a fraction (0–1) of the whole
  /// celebration. Particles fade out before this point.
  final double end;

  /// The colours to use. `null` uses [CelebrationConfig.palette].
  final CelebrationPalette? palette;

  /// Roughly how many things this effect draws at most.
  ///
  /// Used to compare how big celebrations are; it has no effect on drawing.
  int get particleCount;
}

/// Four-pointed stars that twinkle, mostly around the title.
class SparklesEffect extends CelebrationEffect {
  /// Creates twinkling sparkles.
  const SparklesEffect({
    this.count = 24,
    this.size = 1,
    this.area = CelebrationArea.center,
    super.start = 0,
    super.end = 1,
    super.palette,
  });

  /// How many sparkles appear over the effect's lifetime.
  final int count;

  /// Size multiplier; 1 is the default size.
  final double size;

  /// Where the sparkles appear.
  final CelebrationArea area;

  @override
  int get particleCount => count;
}

/// Slowly turning beams of light behind the title.
class LightRaysEffect extends CelebrationEffect {
  /// Creates light rays.
  const LightRaysEffect({
    this.rays = 12,
    this.size = 1,
    this.spin = 0.06,
    this.opacity = 0.55,
    this.alignment = const Alignment(0, -0.12),
    super.start = 0,
    super.end = 1,
    super.palette,
  });

  /// How many beams.
  final int rays;

  /// Size multiplier; 1 reaches past the nearest screen edges.
  final double size;

  /// Turning speed in full turns per second.
  final double spin;

  /// How strong the beams are, from 0 to 1.
  final double opacity;

  /// The centre of the beams. Match it to [TitleSlamEffect.alignment].
  final Alignment alignment;

  @override
  int get particleCount => rays * 2;
}

/// Paper confetti: fluttering rectangles, strips and dots.
class ConfettiEffect extends CelebrationEffect {
  /// Creates confetti.
  const ConfettiEffect({
    this.count = 80,
    this.size = 1,
    this.launch = ConfettiLaunch.cannons,
    this.area = CelebrationArea.center,
    super.start = 0,
    super.end = 1,
    super.palette = CelebrationPalette.party,
  });

  /// How many pieces.
  final int count;

  /// Size multiplier.
  final double size;

  /// How the pieces enter the screen.
  final ConfettiLaunch launch;

  /// For [ConfettiLaunch.burst]: the area whose middle the burst starts from.
  /// For [ConfettiLaunch.rain]: the horizontal span pieces fall across.
  final CelebrationArea area;

  @override
  int get particleCount => count;
}

/// Long curly paper ribbons.
class StreamersEffect extends CelebrationEffect {
  /// Creates streamers.
  const StreamersEffect({
    this.count = 10,
    this.size = 1,
    this.launch = ConfettiLaunch.cannons,
    super.start = 0,
    super.end = 1,
    super.palette = CelebrationPalette.party,
  });

  /// How many ribbons.
  final int count;

  /// Size multiplier (width and length).
  final double size;

  /// How the ribbons enter the screen.
  final ConfettiLaunch launch;

  @override
  int get particleCount => count;
}

/// Spinning gold coins raining from the top.
class CoinsEffect extends CelebrationEffect {
  /// Creates a coin rain.
  const CoinsEffect({
    this.count = 40,
    this.size = 1,
    this.area = CelebrationArea.fullScreen,
    super.start = 0,
    super.end = 1,
    super.palette = CelebrationPalette.gold,
  });

  /// How many coins fall over the effect's lifetime.
  final int count;

  /// Size multiplier.
  final double size;

  /// The horizontal span coins fall across.
  final CelebrationArea area;

  @override
  int get particleCount => count;
}

/// Little flames bursting out, flickering and drifting down.
class FlamesEffect extends CelebrationEffect {
  /// Creates flames.
  ///
  /// [area] picks the motion: [CelebrationArea.center] bursts out from the
  /// middle, [CelebrationArea.bottomBand] shoots up from the bottom edge like
  /// a fountain, [CelebrationArea.topBand] showers down from the top and
  /// [CelebrationArea.fullScreen] drifts down all over the screen.
  const FlamesEffect({
    this.count = 40,
    this.size = 1,
    this.area = CelebrationArea.center,
    super.start = 0,
    super.end = 1,
    super.palette = CelebrationPalette.fire,
  });

  /// How many flames.
  final int count;

  /// Size multiplier.
  final double size;

  /// Where the flames start and how they move.
  final CelebrationArea area;

  @override
  int get particleCount => count;
}

/// Firework shells rising from the bottom and bursting.
class FireworksEffect extends CelebrationEffect {
  /// Creates fireworks.
  const FireworksEffect({
    this.shells = 4,
    this.sparks = 42,
    this.size = 1,
    this.area = CelebrationArea.topBand,
    super.start = 0,
    super.end = 1,
    super.palette,
  });

  /// How many shells burst. They are spread evenly over the time window.
  final int shells;

  /// Sparks per burst.
  final int sparks;

  /// Size multiplier for the bursts.
  final double size;

  /// Where the shells burst.
  final CelebrationArea area;

  @override
  int get particleCount => shells * (sparks + 1);
}

/// A wall of big animated flames along the bottom edge.
class FireWallEffect extends CelebrationEffect {
  /// Creates a wall of fire.
  const FireWallEffect({
    this.height = 0.3,
    this.tongues = 0,
    this.embers = 40,
    super.start = 0,
    super.end = 1,
    super.palette = CelebrationPalette.fire,
  });

  /// Height of the flames as a fraction of the screen height.
  final double height;

  /// Number of flame tongues across the screen; 0 picks one from the width.
  final int tongues;

  /// Glowing embers rising from the wall.
  final int embers;

  @override
  int get particleCount => (tongues == 0 ? 12 : tongues) * 4 + embers;
}

/// Your brand icon popping up all over the screen, in a staggered storm.
///
/// The icon comes from [CelebrationBrand]. Without a brand, a neutral star is
/// used. Pops mix sizes from [minSize] to [maxSize] (fractions of the shorter
/// screen side); the mix is the same every time for the same
/// [CelebrationConfig.seed].
class BrandPopEffect extends CelebrationEffect {
  /// Creates a brand pop storm.
  const BrandPopEffect({
    this.count = 12,
    this.minSize = 0.08,
    this.maxSize = 0.42,
    this.glow = true,
    this.area = CelebrationArea.fullScreen,
    super.start = 0,
    super.end = 1,
    super.palette,
  })  : assert(minSize > 0 && minSize <= maxSize,
            'minSize must be positive and not above maxSize'),
        assert(maxSize <= 2, 'maxSize is a fraction of the screen');

  /// How many pops.
  final int count;

  /// The smallest pop, as a fraction of the shorter screen side.
  final double minSize;

  /// The biggest pop, as a fraction of the shorter screen side.
  final double maxSize;

  /// Whether to draw a soft halo behind each pop.
  final bool glow;

  /// Where the pops appear.
  final CelebrationArea area;

  @override
  int get particleCount => count;
}

/// The big title slamming in from far away with an elastic bounce.
///
/// The text itself comes from [CelebrationConfig.title] (or the `title`
/// argument of `YakoCelebration.show`). The optional subtitle fades in right
/// after the hit.
class TitleSlamEffect extends CelebrationEffect {
  /// Creates a title slam.
  const TitleSlamEffect({
    this.slamFrom = 2.2,
    this.slamDuration = 0.7,
    this.fontSize = 1,
    this.style,
    this.subtitleStyle,
    this.alignment = const Alignment(0, -0.12),
    this.gradient = true,
    this.glow = true,
    super.start = 0,
    super.end = 1,
    super.palette,
  });

  /// The scale the title starts at before it slams down to 1.
  ///
  /// 1 means no slam, only a fade.
  final double slamFrom;

  /// How long the slam and bounce take, in seconds.
  final double slamDuration;

  /// Font size multiplier over the default, which follows the screen size.
  final double fontSize;

  /// Extra style for the title, merged over the default.
  final TextStyle? style;

  /// Extra style for the subtitle, merged over the default.
  final TextStyle? subtitleStyle;

  /// Where the title sits on the screen.
  final Alignment alignment;

  /// Whether to fill the title with a gradient from the palette.
  final bool gradient;

  /// Whether to draw a glow around the title.
  final bool glow;

  @override
  int get particleCount => 1;

  /// Seconds from the start of the slam to the moment it first hits size 1.
  ///
  /// Line up sound, flash and shake with `start + impactDelay`.
  double get impactDelay => slamFrom <= 1 ? 0 : slamDuration * 0.19;
}

/// A full-screen camera flash.
///
/// Peaks at [start] and fades out by [end].
class FlashEffect extends CelebrationEffect {
  /// Creates a flash.
  const FlashEffect({
    this.strength = 0.7,
    this.color = const Color(0xFFFFFFFF),
    super.start = 0,
    super.end = 0.1,
  });

  /// Peak opacity, from 0 to 1.
  final double strength;

  /// Flash colour.
  final Color color;

  @override
  int get particleCount => 1;
}

/// Shakes the screen, strongest at [start] and calming down by [end].
///
/// The title shakes on its own. To shake your own content too, wrap it in
/// a `CelebrationShaker` (for `YakoCelebration.show`) or use
/// `CelebrationOverlay`, which shakes its child.
class ShakeEffect extends CelebrationEffect {
  /// Creates a screen shake.
  const ShakeEffect({
    this.strength = 10,
    this.frequency = 16,
    super.start = 0,
    super.end = 0.15,
  });

  /// Largest movement in logical pixels.
  final double strength;

  /// Shakes per second.
  final double frequency;

  @override
  int get particleCount => 0;
}

/// A soft coloured glow around the screen edges that pulses gently.
class EdgeGlowEffect extends CelebrationEffect {
  /// Creates an edge glow.
  const EdgeGlowEffect({
    this.strength = 0.5,
    this.pulse = 1.2,
    super.start = 0,
    super.end = 1,
    super.palette,
  });

  /// Peak opacity, from 0 to 1.
  final double strength;

  /// Pulses per second; 0 for a steady glow.
  final double pulse;

  @override
  int get particleCount => 1;
}
