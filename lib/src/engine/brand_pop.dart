// Internal: not exported from the package.
// ignore_for_file: public_member_api_docs

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../brand.dart';
import '../effects.dart';
import '../painting/kit.dart';

/// Where every pop is at a given second. Shared by the halo painter and the
/// icon layer so both always agree.
class BrandPopModel {
  BrandPopModel(BrandPopEffect effect, double total, int seed)
      : count = math.max(0, effect.count),
        minSize = effect.minSize,
        maxSize = effect.maxSize,
        startS = effect.start * total,
        endS = effect.end * total {
    final rng = SeededRandom(seed);
    final area = areaBounds(effect.area);
    final span = endS - startS;
    _x = Float64List(count);
    _y = Float64List(count);
    _delay = Float64List(count);
    _life = Float64List(count);
    _size = Float64List(count);
    _rot = Float64List(count);
    _phase = Float64List(count);
    final lifeScale = (span / 3).clamp(0.7, 1.4);
    final giant = count >= 4 ? (count * 0.6).floor() : -1;
    for (var i = 0; i < count; i++) {
      _x[i] = rng.range(area[0] + 0.04, area[2] - 0.04);
      _y[i] = rng.range(area[1] + 0.04, area[3] - 0.04);
      _life[i] = math.min(rng.range(0.9, 1.5) * lifeScale, span);
      final slots = math.max(0.0, span - _life[i]);
      final step = count > 1 ? slots / count : 0.0;
      _delay[i] = (i * step + rng.range(-0.4, 0.4) * step).clamp(0.0, slots);
      final u = i == giant ? 1.0 : math.pow(rng.next(), 2.6).toDouble();
      _size[i] = minSize + (maxSize - minSize) * u;
      _rot[i] = rng.range(-0.35, 0.35);
      _phase[i] = rng.range(0, math.pi * 2);
    }
    // Paint the biggest first so small pops land on top of them.
    order = List<int>.generate(count, (i) => i)
      ..sort((a, b) => _size[b].compareTo(_size[a]));
  }

  final int count;
  final double minSize;
  final double maxSize;
  final double startS;
  final double endS;
  late final List<int> order;
  late final Float64List _x, _y, _delay, _life, _size, _rot, _phase;

  // Output of [evaluate].
  double cx = 0, cy = 0, diameter = 0, rotation = 0, opacity = 0;

  static const double _popIn = 0.32;
  static const double _popOut = 0.28;

  /// Works out pop [i] at [now]; returns false if it is not visible.
  bool evaluate(int i, double now, Size size) {
    final t = now - startS - _delay[i];
    final life = _life[i];
    if (t < 0 || t > life) return false;
    final s = size.shortestSide;
    var scale = t < _popIn
        ? easeOutBack(t / _popIn, 2.4)
        : 1 + 0.03 * math.sin(t * 5 + _phase[i]);
    opacity = 1;
    final outStart = life - _popOut;
    if (t > outStart) {
      final v = (t - outStart) / _popOut;
      scale *= 1 + 0.25 * v;
      opacity = 1 - math.pow(v, 1.5).toDouble();
    }
    if (scale <= 0.01 || opacity <= 0.01) return false;
    diameter = _size[i] * s * scale;
    cx = _x[i] * size.width;
    cy = _y[i] * size.height - s * 0.03 * t;
    rotation = _rot[i] + 0.08 * math.sin(t * 3 + _phase[i]);
    return true;
  }
}

/// The brand pop storm: glowing halos plus the icon, many times over.
class BrandPopLayer extends StatelessWidget {
  const BrandPopLayer({
    super.key,
    required this.model,
    required this.progress,
    required this.totalSeconds,
    required this.brand,
    required this.glowColor,
    required this.glow,
  });

  final BrandPopModel model;
  final Animation<double> progress;
  final double totalSeconds;
  final CelebrationBrand? brand;
  final Color glowColor;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final mark = brandMark(brand, glowColor);
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (glow)
          RepaintBoundary(
            child: CustomPaint(
              painter: _HaloPainter(
                  model, progress, totalSeconds, brand?.color ?? glowColor),
            ),
          ),
        RepaintBoundary(
          child: Flow(
            delegate: _PopFlowDelegate(model, progress, totalSeconds),
            children: <Widget>[
              for (var i = 0; i < model.count; i++)
                RepaintBoundary(child: mark),
            ],
          ),
        ),
      ],
    );
  }
}

/// The brand's icon or image, or a neutral star when there is none.
Widget brandMark(CelebrationBrand? brand, Color color) {
  final icon = brand?.icon;
  if (icon != null) return FittedBox(child: icon);
  final image = brand?.image;
  if (image != null) {
    return Image(
      image: image,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );
  }
  return CustomPaint(painter: StarMarkPainter(color));
}

/// A glossy five-pointed star, the stand-in brand mark.
class StarMarkPainter extends CustomPainter {
  StarMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2 * 0.92;
    final center = size.center(Offset.zero);
    final light = Color.lerp(color, const Color(0xFFFFFFFF), 0.65)!;
    final dark = Color.lerp(color, const Color(0xFF000000), 0.35)!;
    // Drawn in unit space: the star has radius 1 around the origin.
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[light, color, dark],
      ).createShader(const Rect.fromLTRB(-1, -1, 1, 1));
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.07
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xE6FFFFFF);
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..scale(r)
      ..drawPath(Shapes.star5, fill)
      ..drawPath(Shapes.star5, edge)
      ..translate(-0.18, -0.3)
      ..scale(0.28)
      ..drawPath(Shapes.star4, Paint()..color = const Color(0xB3FFFFFF))
      ..restore();
  }

  @override
  bool shouldRepaint(StarMarkPainter oldDelegate) => oldDelegate.color != color;
}

class _HaloPainter extends CustomPainter {
  _HaloPainter(this.model, this.progress, this.totalSeconds, Color color)
      : _ramp = AlphaRamp(color),
        super(repaint: progress);

  final BrandPopModel model;
  final Animation<double> progress;
  final double totalSeconds;
  final AlphaRamp _ramp;
  final GlowBrush _glow = GlowBrush();

  @override
  void paint(Canvas canvas, Size size) {
    final now = progress.value * totalSeconds;
    if (now < model.startS || now > model.endS) return;
    for (final i in model.order) {
      if (!model.evaluate(i, now, size)) continue;
      final r = model.diameter * 0.5;
      canvas.drawCircle(Offset(model.cx, model.cy), r * 0.8,
          _glow.forRadius(r * 1.2, _ramp.at(0.6 * model.opacity)));
    }
  }

  @override
  bool shouldRepaint(_HaloPainter oldDelegate) =>
      oldDelegate.model != model || oldDelegate.progress != progress;
}

class _PopFlowDelegate extends FlowDelegate {
  _PopFlowDelegate(this.model, this.progress, this.totalSeconds)
      : _matrices =
            List<Matrix4>.generate(model.count, (_) => Matrix4.identity()),
        super(repaint: progress);

  final BrandPopModel model;
  final Animation<double> progress;
  final double totalSeconds;
  final List<Matrix4> _matrices;

  double _base(Size size) => math.max(24, model.maxSize * size.shortestSide);

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    final base = _base(constraints.biggest);
    return BoxConstraints.tight(Size.square(base));
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    final now = progress.value * totalSeconds;
    if (now < model.startS || now > model.endS) return;
    final size = context.size;
    final base = _base(size);
    for (final i in model.order) {
      if (i >= context.childCount || !model.evaluate(i, now, size)) continue;
      final k = model.diameter / base;
      final cos = math.cos(model.rotation) * k;
      final sin = math.sin(model.rotation) * k;
      final half = base / 2;
      final tx = model.cx - cos * half + sin * half;
      final ty = model.cy - sin * half - cos * half;
      final m = _matrices[i]
        ..setValues(cos, sin, 0, 0, -sin, cos, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1);
      context.paintChild(i, transform: m, opacity: model.opacity);
    }
  }

  @override
  bool shouldRepaint(_PopFlowDelegate oldDelegate) =>
      oldDelegate.model != model || oldDelegate.progress != progress;
}
