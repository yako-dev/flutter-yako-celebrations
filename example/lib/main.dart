import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:yako_celebrations/yako_celebrations.dart';

import 'capture.dart';
import 'gallery_page.dart';
import 'playground_page.dart';
import 'theme.dart';

/// The example app's brand. Yours goes here: your name and your icon (a PNG
/// from your assets, or any widget, such as an SVG).
const CelebrationBrand exampleBrand = CelebrationBrand(
  name: 'Yako',
  image: AssetImage('assets/yako_logo.png'),
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Once, app-wide: your brand, and load the built-in sounds now so the first
  // celebration starts instantly.
  YakoCelebration.configure(brand: exampleBrand);
  // Parse the Lottie files now, so the first Lottie tier starts at once.
  unawaited(YakoCelebration.preload(CelebrationTier.lottieValues));
  runApp(const ExampleApp());
}

/// Gallery + playground for yako_celebrations.
class ExampleApp extends StatefulWidget {
  /// Creates the example app.
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  int _tab = 0;
  bool _slowMotion = false;

  void _toggleSlowMotion() {
    setState(() => _slowMotion = !_slowMotion);
    // 0.25× speed: every celebration runs four times slower.
    timeDilation = _slowMotion ? 4 : 1;
  }

  void _toggleMute() =>
      setState(() => YakoCelebration.muted = !YakoCelebration.muted);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'yako_celebrations',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // Shakes the whole app in time with the celebrations.
      builder: (context, child) => CelebrationShaker(child: child!),
      home: CaptureMode(
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                _Header(
                  slowMotion: _slowMotion,
                  muted: YakoCelebration.muted,
                  onSlowMotion: _toggleSlowMotion,
                  onMute: _toggleMute,
                ),
                Expanded(
                  child: IndexedStack(
                    index: _tab,
                    children: const <Widget>[GalleryPage(), PlaygroundPage()],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: const <Widget>[
                NavigationDestination(
                  icon: Icon(Icons.auto_awesome_outlined),
                  selectedIcon: Icon(Icons.auto_awesome),
                  label: 'Gallery',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune),
                  label: 'Playground',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.slowMotion,
    required this.muted,
    required this.onSlowMotion,
    required this.onMute,
  });

  final bool slowMotion;
  final bool muted;
  final VoidCallback onSlowMotion;
  final VoidCallback onMute;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Row(
        children: <Widget>[
          Image.asset('assets/yako_logo.png', width: 32, height: 32),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Yako Celebrations',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Package example',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ],
            ),
          ),
          _SpeedButton(on: slowMotion, onPressed: onSlowMotion),
          const SizedBox(width: 4),
          IconButton(
            tooltip: muted ? 'Sound off' : 'Sound on',
            onPressed: onMute,
            icon: Icon(
              muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            ),
            color: muted ? AppColors.faint : AppColors.accent,
            style: IconButton.styleFrom(
              backgroundColor: muted
                  ? Colors.transparent
                  : AppColors.accent.withValues(alpha: 0.14),
            ),
          ),
        ],
      ),
    );
  }
}

/// Plays every celebration at a quarter of its speed while on.
class _SpeedButton extends StatelessWidget {
  const _SpeedButton({required this.on, required this.onPressed});

  final bool on;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: on,
      label: 'Quarter speed',
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: on ? AppColors.accent : AppColors.faint,
              width: 1.5,
            ),
          ),
          child: Text(
            '0.25×',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: on ? Colors.white : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
