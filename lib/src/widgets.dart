import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'brand.dart';
import 'engine/live.dart';
import 'engine/run.dart';
import 'engine/scene.dart';
import 'engine/shake.dart';
import 'sound.dart';
import 'tier.dart';

/// Starts celebrations inside a [CelebrationOverlay].
///
/// ```dart
/// final controller = CelebrationController();
/// ...
/// CelebrationOverlay(controller: controller, child: MyScreen())
/// ...
/// controller.celebrate(tier: CelebrationTier.epic, subtitle: '+500 XP');
/// ```
class CelebrationController extends ChangeNotifier {
  final List<CelebrationRun> _runs = <CelebrationRun>[];
  final ShakeNotifier _shake = ShakeNotifier();
  final math.Random _random = math.Random();
  bool _attached = false;

  /// The shake of this controller's celebrations.
  /// [CelebrationOverlay] applies it to its child.
  ValueListenable<Offset> get shake => _shake;

  /// Whether a celebration is on the screen.
  bool get isCelebrating => _runs.isNotEmpty;

  /// Starts a celebration in the attached [CelebrationOverlay].
  ///
  /// Takes the same arguments as `YakoCelebration.show`.
  CelebrationHandle celebrate({
    CelebrationTier tier = CelebrationTier.great,
    String? title,
    String? subtitle,
    CelebrationBrand? brand,
    CelebrationSound? sound,
    VoidCallback? onComplete,
    bool exclusive = true,
    int? seed,
  }) {
    assert(_attached,
        'CelebrationController.celebrate() needs a CelebrationOverlay using it.');
    if (exclusive) cancelAll();
    final run = CelebrationRun(
      tier: tier,
      brand: brand ?? CelebrationGlobals.brand,
      title: title,
      subtitle: subtitle,
      soundOverride: sound,
      onComplete: onComplete,
      seed: seed ?? tier.config.seed ?? _random.nextInt(1 << 30),
      shake: _shake,
    );
    run.detach = () {
      _runs.remove(run);
      notifyListeners();
    };
    _runs.add(run);
    notifyListeners();
    return CelebrationHandle(run);
  }

  /// Stops every celebration of this controller.
  void cancelAll() {
    for (final run in List<CelebrationRun>.of(_runs)) {
      run.cancel();
    }
  }

  @override
  void dispose() {
    cancelAll();
    _shake.dispose();
    super.dispose();
  }
}

/// Shows a [CelebrationController]'s celebrations over [child], and shakes
/// [child] with them.
///
/// Use it instead of `YakoCelebration.show` when the celebration should stay
/// inside one part of the screen, or when your content should shake too.
class CelebrationOverlay extends StatefulWidget {
  /// Creates an overlay for [controller] over [child].
  const CelebrationOverlay({
    super.key,
    required this.controller,
    required this.child,
    this.shakeChild = true,
  });

  /// Starts the celebrations.
  final CelebrationController controller;

  /// Your content, drawn under the celebration.
  final Widget child;

  /// Whether [child] shakes along with [ShakeEffect]s.
  final bool shakeChild;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> {
  @override
  void initState() {
    super.initState();
    _attach(widget.controller);
  }

  @override
  void didUpdateWidget(CelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller
        .._attached = false
        ..removeListener(_changed);
      _attach(widget.controller);
    }
  }

  void _attach(CelebrationController controller) {
    controller
      .._attached = true
      ..addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller
      .._attached = false
      ..removeListener(_changed)
      ..cancelAll();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        if (widget.shakeChild)
          CelebrationShaker(listenable: controller._shake, child: widget.child)
        else
          widget.child,
        for (final run in controller._runs)
          Positioned.fill(
            child: LiveCelebration(key: ObjectKey(run), run: run),
          ),
      ],
    );
  }
}

/// Shakes [child] in time with celebrations.
///
/// By default it follows celebrations shown with `YakoCelebration.show`, so
/// wrapping your whole app shakes everything:
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => CelebrationShaker(child: child!),
/// )
/// ```
///
/// Only the paint position moves; layout never changes.
class CelebrationShaker extends StatelessWidget {
  /// Shakes [child] with [listenable], or with `YakoCelebration.shake`.
  const CelebrationShaker({super.key, required this.child, this.listenable});

  /// The content to shake.
  final Widget child;

  /// Where the shake offset comes from. Defaults to `YakoCelebration.shake`;
  /// pass `CelebrationController.shake` for a controller's celebrations.
  final ValueListenable<Offset>? listenable;

  @override
  Widget build(BuildContext context) {
    final source = listenable ?? CelebrationGlobals.shake;
    return _Shake(
      notifier: source is ShakeNotifier ? source : null,
      listenable: source,
      child: RepaintBoundary(child: child),
    );
  }
}

class _Shake extends SingleChildRenderObjectWidget {
  const _Shake({required this.notifier, required this.listenable, super.child});

  final ShakeNotifier? notifier;
  final ValueListenable<Offset> listenable;

  @override
  RenderShake createRenderObject(BuildContext context) =>
      RenderShake(notifier ?? _Relay(listenable));

  @override
  void updateRenderObject(BuildContext context, RenderShake renderObject) {
    final current = renderObject.shake;
    if (notifier != null) {
      renderObject.shake = notifier!;
    } else if (current is! _Relay || current.source != listenable) {
      renderObject.shake = _Relay(listenable);
    }
  }
}

/// Adapts any `ValueListenable<Offset>` to a [ShakeNotifier].
class _Relay extends ShakeNotifier {
  _Relay(this.source);

  final ValueListenable<Offset> source;

  @override
  double get dx => source.value.dx;

  @override
  double get dy => source.value.dy;

  @override
  void addListener(VoidCallback listener) => source.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => source.removeListener(listener);
}

/// Draws a celebration frozen at [progress], with no sound or haptics.
///
/// Drive [progress] with your own animation or a slider to scrub through a
/// celebration, build a preview in a settings screen, or take screenshots.
///
/// ```dart
/// CelebrationPreview(
///   tier: CelebrationTier.legendary,
///   progress: AlwaysStoppedAnimation(0.3),
/// )
/// ```
class CelebrationPreview extends StatefulWidget {
  /// Draws [tier] at [progress] (0 to 1).
  const CelebrationPreview({
    super.key,
    this.tier = CelebrationTier.great,
    required this.progress,
    this.title,
    this.subtitle,
    this.brand,
    this.seed = 1,
    this.reducedMotion = false,
  });

  /// What to draw.
  final CelebrationTier tier;

  /// How far along, from 0 to 1.
  final Animation<double> progress;

  /// Overrides the tier's title. `''` hides it.
  final String? title;

  /// Overrides the tier's subtitle.
  final String? subtitle;

  /// Overrides the app-wide brand.
  final CelebrationBrand? brand;

  /// Fixes the random layout.
  final int seed;

  /// Whether to draw the calm, reduced-motion version.
  final bool reducedMotion;

  @override
  State<CelebrationPreview> createState() => _CelebrationPreviewState();
}

class _CelebrationPreviewState extends State<CelebrationPreview> {
  late final ValueNotifier<String?> _title =
      ValueNotifier<String?>(widget.title ?? widget.tier.config.title);
  late final ValueNotifier<String?> _subtitle =
      ValueNotifier<String?>(widget.subtitle ?? widget.tier.config.subtitle);
  final ShakeNotifier _shake = ShakeNotifier();

  @override
  void didUpdateWidget(CelebrationPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _title.value = widget.title ?? widget.tier.config.title;
    _subtitle.value = widget.subtitle ?? widget.tier.config.subtitle;
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.reducedMotion
        ? widget.tier.config.toReducedMotion()
        : widget.tier.config;
    return CelebrationScene(
      config: withTitleEffect(config, _title.value),
      progress: widget.progress,
      title: _title,
      subtitle: _subtitle,
      brand: widget.brand ?? CelebrationGlobals.brand,
      seed: widget.seed,
      shake: _shake,
    );
  }
}
