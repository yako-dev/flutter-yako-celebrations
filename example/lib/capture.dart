import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yako_celebrations/yako_celebrations.dart';

import 'gallery_page.dart';
import 'theme.dart';

// Screenshot helpers for the README, off unless a dart-define turns them on.
// Both hide the app and the status bar: celebrations play on an empty dark
// stage, so every effect is easy to see.
//
//   flutter run --dart-define=SHOTS=legendary@0.35,epic@0.4
//     shows each tier frozen at that moment for 3 s, printing "SHOT <n>"
//   flutter run --dart-define=DEMO=subtle,nice,great,epic,legendary
//     plays the tiers one after another, printing "DEMO_START <tier>"
const String _shots = String.fromEnvironment('SHOTS');
const String _demo = String.fromEnvironment('DEMO');
const int _delayMs =
    int.fromEnvironment('CAPTURE_DELAY_MS', defaultValue: 2500);

/// Wraps the app and, when asked by a dart-define, shows celebrations on an
/// empty dark stage for screenshots and recordings.
class CaptureMode extends StatefulWidget {
  /// Wraps [child].
  const CaptureMode({super.key, required this.child});

  /// The app.
  final Widget child;

  @override
  State<CaptureMode> createState() => _CaptureModeState();
}

class _CaptureModeState extends State<CaptureMode> {
  (CelebrationTier, double)? _frozen;
  Timer? _timer;

  static CelebrationTier _tier(String name) => <CelebrationTier>[
        ...CelebrationTier.values,
        ...CelebrationTier.lottieValues,
      ].firstWhere((t) => t.name == name.trim());

  static String? _subtitleOf(CelebrationTier tier) => <TierInfo>[
        ...tierInfos,
        ...lottieTierInfos
      ].firstWhere((i) => i.tier == tier).subtitle;

  static bool get _capturing => _shots.isNotEmpty || _demo.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_capturing) {
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive));
    }
    if (_shots.isNotEmpty) {
      _timer = Timer(const Duration(milliseconds: _delayMs), () => _shot(0));
    } else if (_demo.isNotEmpty) {
      _timer = Timer(const Duration(milliseconds: _delayMs), () => _play(0));
    }
  }

  void _shot(int index) {
    final shots = _shots.split(',');
    if (index >= shots.length) {
      setState(() => _frozen = null);
      debugPrint('SHOTS_DONE');
      return;
    }
    final parts = shots[index].split('@');
    setState(() => _frozen = (_tier(parts[0]), double.parse(parts[1])));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timer = Timer(const Duration(milliseconds: 600), () {
        debugPrint('SHOT $index ${shots[index]}');
        _timer =
            Timer(const Duration(milliseconds: 2400), () => _shot(index + 1));
      });
    });
  }

  void _play(int index) {
    final names = _demo.split(',');
    if (index >= names.length) {
      debugPrint('DEMO_DONE');
      return;
    }
    final tier = _tier(names[index]);
    debugPrint('DEMO_START ${tier.name}');
    YakoCelebration.show(
      context,
      tier: tier,
      subtitle: _subtitleOf(tier),
      seed: 5,
      onComplete: () {
        debugPrint('DEMO_END ${tier.name}');
        _timer =
            Timer(const Duration(milliseconds: 900), () => _play(index + 1));
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = _capturing
        ? const ColoredBox(
            color: AppColors.background, child: SizedBox.expand())
        : widget.child;
    final frozen = _frozen;
    if (frozen == null) return stage;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        stage,
        CelebrationPreview(
          tier: frozen.$1,
          progress: AlwaysStoppedAnimation<double>(frozen.$2),
          subtitle: _subtitleOf(frozen.$1),
          seed: 5,
        ),
      ],
    );
  }
}
