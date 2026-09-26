// Internal: not exported from the package.
// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../config.dart';
import '../haptics.dart';
import 'run.dart';
import 'scene.dart';

/// Plays one [CelebrationRun]: owns the master clock, starts the sound, fires
/// haptics on time, and reports when it is done.
class LiveCelebration extends StatefulWidget {
  const LiveCelebration({super.key, required this.run});

  final CelebrationRun run;

  @override
  State<LiveCelebration> createState() => _LiveCelebrationState();
}

class _LiveCelebrationState extends State<LiveCelebration>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  late CelebrationConfig _config;
  List<HapticPulse> _pulses = const <HapticPulse>[];
  int _nextPulse = 0;

  CelebrationRun get _run => widget.run;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) _start();
  }

  void _start() {
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final base =
        reduced ? _run.tier.config.toReducedMotion() : _run.tier.config;
    _config = withTitleEffect(base, _run.title.value);
    _pulses = List<HapticPulse>.of(_config.haptics.pulses)
      ..sort((a, b) => a.at.compareTo(b.at));
    final controller = AnimationController(
      vsync: this,
      duration: _config.duration,
      // We pick the calm version ourselves; never let the framework squash
      // the clock on top of that.
      animationBehavior: AnimationBehavior.preserve,
    )
      ..addListener(_tick)
      ..addStatusListener(_status);
    _controller = controller;
    _run.halt = controller.stop;
    _run.startSound(_config);
    _tick();
    controller.forward();
  }

  void _tick() {
    final controller = _controller;
    if (controller == null) return;
    final value = controller.value;
    while (
        _nextPulse < _pulses.length && _pulses[_nextPulse].at <= value + 1e-9) {
      _fire(_pulses[_nextPulse].kind);
      _nextPulse++;
    }
  }

  void _fire(CelebrationHapticKind kind) {
    if (!CelebrationGlobals.haptics) return;
    final Future<void> Function() call = switch (kind) {
      CelebrationHapticKind.selection => HapticFeedback.selectionClick,
      CelebrationHapticKind.light => HapticFeedback.lightImpact,
      CelebrationHapticKind.medium => HapticFeedback.mediumImpact,
      CelebrationHapticKind.heavy => HapticFeedback.heavyImpact,
      CelebrationHapticKind.vibrate => HapticFeedback.vibrate,
    };
    try {
      unawaited(call().catchError((Object _) {}));
    } catch (_) {
      // Haptics are a bonus; a platform without them must not break anything.
    }
  }

  void _status(AnimationStatus status) {
    if (status == AnimationStatus.completed) _run.finish();
  }

  @override
  void dispose() {
    _controller?.dispose();
    // Taken off the screen by someone else (e.g. the host went away).
    _run.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const SizedBox.shrink();
    return CelebrationScene(
      config: _config,
      progress: controller,
      title: _run.title,
      subtitle: _run.subtitle,
      brand: _run.brand,
      seed: _run.seed,
      shake: _run.shake,
    );
  }
}
