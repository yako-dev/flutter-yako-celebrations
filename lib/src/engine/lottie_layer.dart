// Internal: not exported from the package.
// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart' show AssetLottie, Lottie, LottieComposition;

import '../effects.dart';
import '../painting/kit.dart';

/// Parsed Lottie files, loaded once per asset key.
///
/// Parsing is paid for up front (`YakoCelebration.preload`) or on first use;
/// a layer whose file is still loading is simply not drawn yet.
abstract final class CelebrationLottieCache {
  static final Map<String, LottieComposition> _loaded =
      <String, LottieComposition>{};
  static final Map<String, Future<LottieComposition?>> _loading =
      <String, Future<LottieComposition?>>{};

  static LottieComposition? get(String key) => _loaded[key];

  static Future<LottieComposition?> load(String key) =>
      _loading.putIfAbsent(key, () async {
        try {
          final composition = await AssetLottie(key).load();
          _loaded[key] = composition;
          return composition;
        } catch (error) {
          _loading.remove(key)?.ignore();
          if (kDebugMode) {
            debugPrint('yako_celebrations: could not load Lottie $key: $error');
          }
          return null;
        }
      });

  @visibleForTesting
  static void put(String key, LottieComposition composition) {
    _loaded[key] = composition;
    _loading[key] = Future<LottieComposition?>.value(composition);
  }

  @visibleForTesting
  static void clear() {
    _loaded.clear();
    _loading.clear();
  }
}

/// An animation that is [fn] of [parent]'s value, with no listeners of its
/// own to dispose.
class FnAnimation extends Animation<double>
    with AnimationWithParentMixin<double> {
  FnAnimation(this.parent, this.fn);

  @override
  final Animation<double> parent;

  final double Function(double value) fn;

  @override
  double get value => fn(parent.value);
}

/// Where [effect] sits on a [size] screen.
Rect lottieRectFor(LottieEffect effect, Size size) {
  final w = size.width;
  final h = size.height;
  final s = effect.scale;
  return switch (effect.anchor) {
    LottieAnchor.fullScreen => Offset.zero & size,
    LottieAnchor.topBand => Rect.fromLTWH(0, 0, w, h * s),
    LottieAnchor.bottomEdge => Rect.fromLTWH(0, h - w * s, w, w * s),
    LottieAnchor.topLeft => Rect.fromLTWH(-w * 0.08, h * 0.04, w * s, w * s),
    LottieAnchor.topRight =>
      Rect.fromLTWH(w - w * s + w * 0.08, h * 0.04, w * s, w * s),
    LottieAnchor.center => Rect.fromCenter(
        center: Offset(w / 2, h * 0.45),
        width: w * s,
        height: w * s,
      ),
  };
}

BoxFit _fitFor(LottieEffect effect) =>
    effect.fit ??
    (effect.anchor == LottieAnchor.fullScreen ||
            effect.anchor == LottieAnchor.topBand
        ? BoxFit.cover
        : BoxFit.contain);

/// Plays one [LottieEffect], every frame taken from the master clock.
class LottieLayer extends StatefulWidget {
  const LottieLayer({
    super.key,
    required this.effect,
    required this.progress,
    required this.totalSeconds,
  });

  final LottieEffect effect;
  final Animation<double> progress;
  final double totalSeconds;

  @override
  State<LottieLayer> createState() => _LottieLayerState();
}

class _LottieLayerState extends State<LottieLayer> {
  LottieComposition? _composition;
  late FnAnimation _frame;
  late FnAnimation _opacity;
  late FnAnimation _turns;
  ui.Shader? _fade;
  Size _fadeSize = Size.zero;

  LottieEffect get _effect => widget.effect;

  @override
  void initState() {
    super.initState();
    _bind();
    _load();
  }

  @override
  void didUpdateWidget(LottieLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.effect.assetKey != _effect.assetKey) _load();
    if (oldWidget.progress != widget.progress ||
        oldWidget.effect != widget.effect ||
        oldWidget.totalSeconds != widget.totalSeconds) {
      _bind();
    }
  }

  /// Takes the file from the cache, or loads it and draws once it is ready.
  void _load() {
    final key = _effect.assetKey;
    _composition = CelebrationLottieCache.get(key);
    if (_composition != null) return;
    unawaited(CelebrationLottieCache.load(key).then((composition) {
      if (mounted && composition != null && _effect.assetKey == key) {
        setState(() => _composition = composition);
      }
    }));
  }

  void _bind() {
    final total = widget.totalSeconds;
    final start = _effect.start * total;
    final end = _effect.end * total;
    double seconds(double v) => v * total;
    double local(double t) => (t - start) * _effect.speed;
    double fileSeconds() => math.max(0.01, _composition?.seconds ?? 1);

    _frame = FnAnimation(widget.progress, (v) {
      final l = local(seconds(v));
      if (l <= 0) return 0;
      final p = l / fileSeconds();
      return _effect.loop ? p % 1.0 : clamp01(p);
    });
    _opacity = FnAnimation(widget.progress, (v) {
      final t = seconds(v);
      if (t < start || t > end) return 0;
      if (!_effect.loop && local(t) > fileSeconds()) return 0;
      final fadeIn = clamp01((t - start) / 0.12);
      final fadeOut = clamp01((end - t) / 0.35);
      return _effect.opacity * math.min(fadeIn, fadeOut);
    });
    _turns = FnAnimation(
      widget.progress,
      (v) => (seconds(v) - start) / total * _effect.spinTurns,
    );
  }

  /// The bottom fade, made once per box size.
  ui.Shader _fadeShader(Rect bounds) {
    if (_fade == null || bounds.size != _fadeSize) {
      _fadeSize = bounds.size;
      _fade = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xFFFFFFFF),
          Color(0xFFFFFFFF),
          Color(0x00FFFFFF)
        ],
        stops: <double>[0, 0.65, 1],
      ).createShader(bounds);
    }
    return _fade!;
  }

  @override
  Widget build(BuildContext context) {
    final composition = _composition;
    if (composition == null) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, constraints) {
      final rect = lottieRectFor(_effect, constraints.biggest);
      Widget child = Lottie(
        composition: composition,
        controller: _frame,
        fit: _fitFor(_effect),
        alignment: Alignment.topCenter,
        width: rect.width,
        height: rect.height,
      );
      final tint = _effect.tint;
      if (tint != null) {
        child = ColorFiltered(
          colorFilter: ColorFilter.mode(tint, BlendMode.modulate),
          child: child,
        );
      }
      if (_effect.spinTurns != 0) {
        child = RotationTransition(turns: _turns, child: child);
      }
      if (_effect.fadeBottom) {
        child = ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: _fadeShader,
          child: child,
        );
      }
      child = FadeTransition(opacity: _opacity, child: child);
      return Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fromRect(rect: rect, child: RepaintBoundary(child: child)),
        ],
      );
    });
  }
}
