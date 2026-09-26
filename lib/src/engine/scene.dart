// Internal: not exported from the package.
// ignore_for_file: public_member_api_docs

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../brand.dart';
import '../config.dart';
import '../effects.dart';
import '../painting/fire_renderers.dart';
import '../painting/glow_renderers.dart';
import '../painting/kit.dart';
import '../painting/particle_renderers.dart';
import '../painting/renderer.dart';
import 'brand_pop.dart';
import 'shake.dart';
import 'title.dart';

/// Adds a default title slam when there is a title but no [TitleSlamEffect].
CelebrationConfig withTitleEffect(CelebrationConfig config, String? title) {
  final hasTitle = title != null && title.isNotEmpty;
  if (!hasTitle || config.effects.any((e) => e is TitleSlamEffect)) {
    return config;
  }
  return config.withEffects(const <CelebrationEffect>[TitleSlamEffect()]);
}

/// Draws a celebration at whatever point [progress] is at.
///
/// Pure rendering: no sound, no haptics, no timers. [LiveCelebration] and
/// [CelebrationPreview] both use it.
class CelebrationScene extends StatefulWidget {
  const CelebrationScene({
    super.key,
    required this.config,
    required this.progress,
    required this.title,
    required this.subtitle,
    required this.brand,
    required this.seed,
    required this.shake,
  });

  final CelebrationConfig config;
  final Animation<double> progress;
  final ValueListenable<String?> title;
  final ValueListenable<String?> subtitle;
  final CelebrationBrand? brand;
  final int seed;

  /// Receives the shake offset every frame (the title reads it too).
  final ShakeNotifier shake;

  @override
  State<CelebrationScene> createState() => _CelebrationSceneState();
}

class _Layer {
  _Layer.paint(this.z, EffectRenderer this.renderer) : builder = null;
  _Layer.widget(this.z, WidgetBuilder this.builder) : renderer = null;

  final int z;
  final EffectRenderer? renderer;
  final WidgetBuilder? builder;
}

class _CelebrationSceneState extends State<CelebrationScene> {
  late List<Widget Function(BuildContext)> _builders;
  final List<EffectRenderer> _renderers = <EffectRenderer>[];
  late List<ShakeEffect> _shakes;

  double get _total =>
      widget.config.seconds <= 0 ? 0.001 : widget.config.seconds;

  @override
  void initState() {
    super.initState();
    _build();
    widget.progress.addListener(_tick);
    _tick();
  }

  @override
  void didUpdateWidget(CelebrationScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      oldWidget.progress.removeListener(_tick);
      widget.progress.addListener(_tick);
    }
    if (oldWidget.config != widget.config ||
        oldWidget.seed != widget.seed ||
        oldWidget.brand != widget.brand ||
        oldWidget.progress != widget.progress) {
      _disposeRenderers();
      _build();
    }
    _tick();
  }

  @override
  void dispose() {
    widget.progress.removeListener(_tick);
    _disposeRenderers();
    super.dispose();
  }

  void _disposeRenderers() {
    for (final renderer in _renderers) {
      renderer.dispose();
    }
    _renderers.clear();
  }

  void _tick() {
    if (_shakes.isEmpty) return;
    computeShake(_shakes, _total, widget.progress.value * _total, widget.shake);
  }

  void _build() {
    final config = widget.config;
    final total = _total;
    final accent = config.color;
    final layers = <_Layer>[];
    _shakes = config.effects.whereType<ShakeEffect>().toList();

    if (config.backgroundDim > 0) {
      layers.add(_Layer.paint(0, DimRenderer(config.backgroundDim, total)));
    }
    for (var index = 0; index < config.effects.length; index++) {
      final effect = config.effects[index];
      final seed = widget.seed * 7919 + index * 104729 + 17;
      final palette = effect.palette ?? config.palette;
      switch (effect) {
        case EdgeGlowEffect():
          layers.add(_Layer.paint(
              10, EdgeGlowRenderer(effect, palette, accent, total)));
        case LightRaysEffect():
          layers.add(_Layer.paint(
              20, LightRaysRenderer(effect, palette, accent, total)));
        case FireworksEffect():
          layers.add(_Layer.paint(
              30, FireworksRenderer(effect, palette, accent, total, seed)));
        case BrandPopEffect():
          final model = BrandPopModel(effect, total, seed);
          final glow = widget.brand?.color ?? palette.representative(accent);
          layers.add(_Layer.widget(
            40,
            (context) => BrandPopLayer(
              model: model,
              progress: widget.progress,
              totalSeconds: total,
              brand: widget.brand,
              glowColor: glow,
              glow: effect.glow,
            ),
          ));
        case CoinsEffect():
          layers.add(_Layer.paint(
              50, CoinsRenderer(effect, palette, accent, total, seed)));
        case FlamesEffect():
          layers.add(_Layer.paint(
              55, FlamesRenderer(effect, palette, accent, total, seed)));
        case ConfettiEffect():
          layers.add(_Layer.paint(
              60, ConfettiRenderer(effect, palette, accent, total, seed)));
        case StreamersEffect():
          layers.add(_Layer.paint(
              62, StreamersRenderer(effect, palette, accent, total, seed)));
        case FireWallEffect():
          layers.add(_Layer.paint(
              70, FireWallRenderer(effect, palette, accent, total, seed)));
        case TitleSlamEffect():
          layers.add(_Layer.widget(
            80,
            (context) => TitleLayer(
              effect: effect,
              progress: widget.progress,
              totalSeconds: total,
              title: widget.title,
              subtitle: widget.subtitle,
              palette: palette,
              accent: accent,
              shake: widget.shake,
            ),
          ));
        case SparklesEffect():
          layers.add(_Layer.paint(
              85, SparklesRenderer(effect, palette, accent, total, seed)));
        case FlashEffect():
          layers.add(_Layer.paint(100, FlashRenderer(effect, total)));
        case ShakeEffect():
          break;
      }
    }
    for (final extra in config.extraLayers) {
      layers
          .add(_Layer.widget(75, (context) => extra(context, widget.progress)));
    }
    final brand = widget.brand;
    if (config.showBrandBadge && brand != null) {
      layers.add(_Layer.widget(
        90,
        (context) => _BrandBadge(
          brand: brand,
          accent: brand.color ?? config.palette.representative(accent),
          progress: widget.progress,
          totalSeconds: total,
        ),
      ));
    }

    // Stable sort keeps the config's order within the same depth.
    final indexed = layers.asMap().entries.toList()
      ..sort((a, b) {
        final byZ = a.value.z.compareTo(b.value.z);
        return byZ != 0 ? byZ : a.key.compareTo(b.key);
      });

    // Neighbouring painters share one canvas; widgets sit between them.
    _builders = <Widget Function(BuildContext)>[];
    var group = <EffectRenderer>[];
    void flush() {
      if (group.isEmpty) return;
      final renderers = group;
      group = <EffectRenderer>[];
      _builders.add((context) => RepaintBoundary(
            child: CustomPaint(
              painter: EffectsPainter(
                progress: widget.progress,
                totalSeconds: total,
                renderers: renderers,
              ),
              size: Size.infinite,
            ),
          ));
    }

    for (final entry in indexed) {
      final layer = entry.value;
      final renderer = layer.renderer;
      if (renderer != null) {
        _renderers.add(renderer);
        group.add(renderer);
      } else {
        flush();
        _builders.add(layer.builder!);
      }
    }
    flush();
  }

  @override
  Widget build(BuildContext context) {
    final fadeStart = 1 - (0.25 / _total).clamp(0.0, 1.0);
    return IgnorePointer(
      child: FadeTransition(
        opacity: MappedAnimation(widget.progress, _Envelope(0, fadeStart)),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            for (final builder in _builders)
              Positioned.fill(child: Builder(builder: builder)),
          ],
        ),
      ),
    );
  }
}

/// [parent] passed through [curve], without the listeners and disposal a
/// [CurvedAnimation] needs.
class MappedAnimation extends Animation<double>
    with AnimationWithParentMixin<double> {
  MappedAnimation(this.parent, this.curve);

  @override
  final Animation<double> parent;

  final Curve curve;

  @override
  double get value => curve.transform(clamp01(parent.value));
}

/// 1 from [start] to [end], fading to 0 after [end] (a fade-out curve).
class _Envelope extends Curve {
  const _Envelope(this.start, this.end);

  final double start;
  final double end;

  @override
  double transformInternal(double t) {
    if (t < start) return 0;
    if (t <= end || end >= 1) return 1;
    return clamp01(1 - (t - end) / (1 - end));
  }
}

/// A small pill with the brand's icon and name at the top of the screen.
class _BrandBadge extends StatelessWidget {
  const _BrandBadge({
    required this.brand,
    required this.accent,
    required this.progress,
    required this.totalSeconds,
  });

  final CelebrationBrand brand;
  final Color accent;
  final Animation<double> progress;
  final double totalSeconds;

  @override
  Widget build(BuildContext context) {
    final name = brand.name;
    final top = MediaQuery.maybePaddingOf(context)?.top ?? 0;
    final fadeIn = (0.25 / totalSeconds).clamp(0.0, 1.0);
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: top + 14),
        child: FadeTransition(
          opacity: MappedAnimation(
            progress,
            Interval(fadeIn * 0.4, fadeIn * 1.4, curve: Curves.easeOut),
          ),
          child: RepaintBoundary(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xB3000000),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                    color: accent.withValues(alpha: 0.85), width: 1.5),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                      color: accent.withValues(alpha: 0.4), blurRadius: 16),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox.square(
                        dimension: 26, child: brandMark(brand, accent)),
                    if (name != null && name.isNotEmpty) ...<Widget>[
                      const SizedBox(width: 8),
                      Text(
                        name,
                        style: celebrationTextStyle(context).copyWith(
                          color: const Color(0xFFFFFFFF),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
