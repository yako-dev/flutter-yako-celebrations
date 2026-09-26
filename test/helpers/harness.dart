import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yako_celebrations/yako_celebrations.dart';

/// A plain app with a button-less home screen, returning its context.
Future<BuildContext> pumpHost(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  bool reducedMotion = false,
  Widget? child,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late BuildContext captured;
  await tester.pumpWidget(MaterialApp(
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
      child: app!,
    ),
    home: Builder(builder: (context) {
      captured = context;
      return child ?? const Scaffold(body: Center(child: Text('home')));
    }),
  ));
  return captured;
}

/// Pumps frames of [step] until [done] or [limit] passes. Returns the time
/// it took.
Future<Duration> pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  Duration step = const Duration(milliseconds: 50),
  Duration limit = const Duration(seconds: 15),
}) async {
  var elapsed = Duration.zero;
  while (!done() && elapsed < limit) {
    await tester.pump(step);
    elapsed += step;
  }
  return elapsed;
}

/// Records every haptic call made through the platform channel.
List<String> recordHaptics(WidgetTester tester) {
  final calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method.startsWith('HapticFeedback')) {
        calls.add('${call.method}:${call.arguments}');
      }
      return null;
    },
  );
  addTearDown(() => tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null));
  return calls;
}

/// Resets the app-wide settings between tests.
void resetCelebrations() {
  YakoCelebration.cancelAll();
  YakoCelebration.configure(preloadSounds: false);
}
