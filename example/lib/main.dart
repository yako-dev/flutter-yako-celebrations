import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:yako_celebrations/yako_celebrations.dart';

import 'capture.dart';
import 'gallery_page.dart';
import 'logo.dart';
import 'playground_page.dart';

/// The example app's brand. Yours goes here: your name and your icon.
const CelebrationBrand exampleBrand = CelebrationBrand(
  name: 'Yako',
  icon: YakoLogo(),
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

  void _setSlowMotion(bool value) {
    setState(() => _slowMotion = value);
    timeDilation = value ? 5 : 1;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'yako_celebrations',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF7C4DFF),
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0C1D),
      ),
      // Shakes the whole app in time with the celebrations.
      builder: (context, child) => CelebrationShaker(child: child!),
      home: CaptureMode(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: const Text('yako_celebrations'),
            actions: <Widget>[
              const Text('Slow-mo'),
              Switch(value: _slowMotion, onChanged: _setSlowMotion),
              const SizedBox(width: 8),
            ],
          ),
          body: IndexedStack(
            index: _tab,
            children: const <Widget>[GalleryPage(), PlaygroundPage()],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: const <Widget>[
              NavigationDestination(
                icon: Icon(Icons.celebration_outlined),
                selectedIcon: Icon(Icons.celebration),
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
    );
  }
}
