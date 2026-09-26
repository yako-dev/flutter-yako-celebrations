// Internal: not exported from the package.
// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:flutter/widgets.dart';

import '../effects.dart';
import '../painting/kit.dart';
import '../palette.dart';
import 'shake.dart';

/// The title slam and the subtitle under it.
///
/// Built once; every frame only moves, scales and fades the two cached
/// pictures through a [Flow], so the text is never laid out again while it
/// animates.
class TitleLayer extends StatelessWidget {
  const TitleLayer({
    super.key,
    required this.effect,
    required this.progress,
    required this.totalSeconds,
    required this.title,
    required this.subtitle,
    required this.palette,
    required this.accent,
    required this.shake,
  });

  final TitleSlamEffect effect;
  final Animation<double> progress;
  final double totalSeconds;
  final ValueListenable<String?> title;
  final ValueListenable<String?> subtitle;
  final CelebrationPalette palette;
  final Color accent;
  final ShakeNotifier shake;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.maybeSizeOf(context) ?? const Size(400, 800);
    final fontSize =
        (size.shortestSide * 0.15).clamp(34.0, 120.0) * effect.fontSize;
    final glowColor = effect.glowColor ?? palette.representative(accent);
    final outline = Color.lerp(glowColor, const Color(0xFF000000), 0.6)!;
    final gradient =
        effect.colors ?? _gradientColors(palette.resolve(accent), accent);
    final startSeconds = effect.start * totalSeconds;
    final shimmer = effect.shimmer
        ? MappedShimmer(progress, totalSeconds, startSeconds)
        : null;
    final base = celebrationTextStyle(context)
        .copyWith(
          color: const Color(0xFFFFFFFF),
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          height: 1.05,
          letterSpacing: fontSize * 0.02,
        )
        .merge(effect.style);

    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[title, subtitle]),
      builder: (context, _) {
        final text = title.value ?? '';
        final sub = subtitle.value ?? '';
        return Semantics(
          liveRegion: true,
          container: true,
          label: <String>[text, sub].where((s) => s.isNotEmpty).join('. '),
          child: ExcludeSemantics(
            child: Flow(
              delegate: _TitleFlowDelegate(
                effect: effect,
                progress: progress,
                totalSeconds: totalSeconds,
                shake: shake,
              ),
              children: <Widget>[
                RepaintBoundary(
                  child: text.isEmpty
                      ? const SizedBox.shrink()
                      : _TitleText(
                          text: text,
                          style: base,
                          gradient: effect.gradient ? gradient : null,
                          outline: outline,
                          glowColor: effect.glow ? glowColor : null,
                          shimmer: shimmer,
                        ),
                ),
                RepaintBoundary(
                  child: sub.isEmpty
                      ? const SizedBox.shrink()
                      : _SubtitlePill(
                          text: sub,
                          fontSize: fontSize * 0.34,
                          accent: glowColor,
                          style: effect.subtitleStyle,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static List<Color> _gradientColors(CelebrationPalette palette, Color accent) {
    if (palette.cycleHues) {
      return const <Color>[
        Color(0xFFFF5E7E),
        Color(0xFFFFD84D),
        Color(0xFF6BFF9E),
        Color(0xFF4FC3FF),
        Color(0xFFD07BFF),
      ];
    }
    final main = palette.colors.isEmpty ? accent : palette.colors.first;
    return <Color>[
      Color.lerp(main, const Color(0xFFFFFFFF), 0.85)!,
      Color.lerp(main, const Color(0xFFFFFFFF), 0.35)!,
      main,
    ];
  }
}

/// The app's display font, without the debug style an overlay would
/// otherwise inherit.
TextStyle celebrationTextStyle(BuildContext context) {
  final display = Theme.of(context).textTheme.displayLarge;
  return TextStyle(
    fontFamily: display?.fontFamily,
    fontFamilyFallback: display?.fontFamilyFallback,
    decoration: TextDecoration.none,
    inherit: false,
    textBaseline: TextBaseline.alphabetic,
  );
}

class _TitleText extends StatelessWidget {
  const _TitleText({
    required this.text,
    required this.style,
    required this.gradient,
    required this.outline,
    required this.glowColor,
    this.shimmer,
  });

  final String text;
  final TextStyle style;
  final List<Color>? gradient;
  final Color outline;
  final Color? glowColor;

  /// Where the light band is, from about -1 to 2 across the letters.
  final Animation<double>? shimmer;

  @override
  Widget build(BuildContext context) {
    final fontSize = style.fontSize ?? 48;
    final glow = glowColor;
    final colors = gradient;
    final fill = Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 2,
      style: style.copyWith(
          color: colors == null ? style.color : const Color(0xFFFFFFFF)),
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        padding: EdgeInsets.all(fontSize * 0.25),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: style.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = fontSize * 0.1
                  ..strokeJoin = StrokeJoin.round
                  ..color = outline,
                shadows: glow == null
                    ? null
                    : <Shadow>[
                        Shadow(
                            color: glow.withValues(alpha: 0.9),
                            blurRadius: fontSize * 0.25),
                        Shadow(
                            color: glow.withValues(alpha: 0.6),
                            blurRadius: fontSize * 0.7),
                      ],
              ),
            ),
            if (colors == null)
              fill
            else
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (rect) {
                  final vertical = colors.length <= 3;
                  return LinearGradient(
                    begin:
                        vertical ? Alignment.topCenter : Alignment.centerLeft,
                    end: vertical
                        ? Alignment.bottomCenter
                        : Alignment.centerRight,
                    colors: colors,
                  ).createShader(rect);
                },
                child: fill,
              ),
          ],
        ),
      ),
    );
  }
}

class _SubtitlePill extends StatelessWidget {
  const _SubtitlePill({
    required this.text,
    required this.fontSize,
    required this.accent,
    required this.style,
  });

  final String text;
  final double fontSize;
  final Color accent;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0x8C000000),
          borderRadius: BorderRadius.circular(fontSize * 2),
          border: Border.all(color: accent.withValues(alpha: 0.9), width: 1.5),
          boxShadow: <BoxShadow>[
            BoxShadow(
                color: accent.withValues(alpha: 0.45), blurRadius: fontSize),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: fontSize * 0.9,
            vertical: fontSize * 0.32,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: celebrationTextStyle(context)
                .copyWith(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: fontSize * 0.08,
                  color: const Color(0xFFFFFFFF),
                )
                .merge(style),
          ),
        ),
      ),
    );
  }
}

/// The shimmer band's position: a sweep across the letters every 1.4 s after
/// the title lands, from -1 (off the left) to 2 (off the right).
class MappedShimmer extends Animation<double>
    with AnimationWithParentMixin<double> {
  MappedShimmer(this.parent, this.totalSeconds, this.startSeconds);

  @override
  final Animation<double> parent;
  final double totalSeconds;
  final double startSeconds;

  @override
  double get value {
    final t = parent.value * totalSeconds - startSeconds;
    if (t < 0) return -1;
    return (t / 1.4) % 1.0 * 3 - 1;
  }
}

class _TitleFlowDelegate extends FlowDelegate {
  _TitleFlowDelegate({
    required this.effect,
    required this.progress,
    required this.totalSeconds,
    required this.shake,
  }) : super(repaint: progress);

  final TitleSlamEffect effect;
  final Animation<double> progress;
  final double totalSeconds;
  final ShakeNotifier shake;
  final Matrix4 _titleMatrix = Matrix4.identity();
  final Matrix4 _subtitleMatrix = Matrix4.identity();

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    final size = constraints.biggest;
    return BoxConstraints(
      maxWidth: size.width * 0.92,
      maxHeight: size.height * (i == 0 ? 0.4 : 0.12),
    );
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    final now = progress.value * totalSeconds;
    final start = effect.start * totalSeconds;
    final end = effect.end * totalSeconds;
    final t = now - start;
    if (t < 0 || now > end) return;
    final size = context.size;
    final slam = math.max(0.05, effect.slamDuration);

    var scale = 1.0;
    var opacity = 1.0;
    if (effect.slamFrom > 1) {
      final u = clamp01(t / slam);
      final f = 1 - math.exp(-5 * u) * math.cos(2.6 * math.pi * u);
      scale = effect.slamFrom + (1 - effect.slamFrom) * f;
      opacity = clamp01(t / 0.08);
    } else {
      scale = 0.96 + 0.04 * easeOutCubic(t / slam);
      opacity = clamp01(t / slam);
    }
    if (t > slam) scale *= 1 + 0.012 * math.sin(2 * math.pi * 0.9 * (t - slam));
    final outLength = math.min(0.35, (end - start) * 0.2);
    var exit = 1.0;
    if (end - now < outLength) {
      final v = 1 - (end - now) / outLength;
      scale *= 1 + 0.12 * v;
      exit = 1 - v;
    }
    opacity *= exit;
    if (opacity <= 0.005) return;

    final cx = (effect.alignment.x + 1) / 2 * size.width + shake.dx;
    final cy = (effect.alignment.y + 1) / 2 * size.height + shake.dy;
    final titleSize = context.getChildSize(0) ?? Size.zero;
    final m = _titleMatrix
      ..setValues(
          scale,
          0,
          0,
          0,
          0,
          scale,
          0,
          0,
          0,
          0,
          1,
          0,
          cx - scale * titleSize.width / 2,
          cy - scale * titleSize.height / 2,
          0,
          1);
    context.paintChild(0, transform: m, opacity: opacity);

    final subtitleSize = context.getChildSize(1) ?? Size.zero;
    if (subtitleSize.isEmpty) return;
    final st = t - effect.impactDelay - 0.1;
    if (st <= 0) return;
    final subOpacity = clamp01(st / 0.25) * exit;
    if (subOpacity <= 0.005) return;
    final slide = (1 - easeOutCubic(st / 0.35)) * size.shortestSide * 0.05;
    final top = cy + titleSize.height * 0.42 + slide;
    final s = _subtitleMatrix
      ..setValues(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0,
          cx - shake.dx * 0.5 - subtitleSize.width / 2, top, 0, 1);
    context.paintChild(1, transform: s, opacity: subOpacity);
  }

  @override
  bool shouldRepaint(_TitleFlowDelegate oldDelegate) =>
      oldDelegate.effect != effect || oldDelegate.progress != progress;
}
