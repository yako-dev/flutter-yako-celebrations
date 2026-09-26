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
    timeDilation = _slowMotion ? 5 : 1;
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
                  title: _tab == 0 ? 'Celebrations' : 'Playground',
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
    required this.title,
    required this.slowMotion,
    required this.muted,
    required this.onSlowMotion,
    required this.onMute,
  });

  final String title;
  final bool slowMotion;
  final bool muted;
  final VoidCallback onSlowMotion;
  final VoidCallback onMute;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
      child: Row(
        children: <Widget>[
          Image.asset('assets/yako_logo.png', width: 30, height: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
          ),
          _ToggleButton(
            icon: Icons.slow_motion_video,
            tooltip: 'Slow motion',
            on: slowMotion,
            onPressed: onSlowMotion,
          ),
          _ToggleButton(
            icon: muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            tooltip: muted ? 'Sound off' : 'Sound on',
            on: !muted,
            onPressed: onMute,
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.icon,
    required this.tooltip,
    required this.on,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool on;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      color: on ? AppColors.accent : AppColors.faint,
      style: IconButton.styleFrom(
        backgroundColor:
            on ? AppColors.accent.withValues(alpha: 0.14) : Colors.transparent,
      ),
    );
  }
}
