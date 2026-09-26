import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yako_celebrations/yako_celebrations.dart';

import 'main.dart';
import 'theme.dart';

enum _Effect {
  title('Title slam'),
  rays('Light rays'),
  sparkles('Sparkles'),
  confetti('Confetti'),
  streamers('Streamers'),
  coins('Coins'),
  flames('Flames'),
  fireworks('Fireworks'),
  brandPop('Brand pop'),
  fireWall('Fire wall'),
  edgeGlow('Edge glow'),
  flash('Flash'),
  shake('Shake');

  const _Effect(this.label);
  final String label;
}

enum _Palette {
  own('Their own'),
  accent('Accent'),
  gold('Gold'),
  fire('Fire'),
  party('Party'),
  rainbow('Rainbow');

  const _Palette(this.label);
  final String label;

  CelebrationPalette? get palette => switch (this) {
        _Palette.own => null,
        _Palette.accent => CelebrationPalette.accent,
        _Palette.gold => CelebrationPalette.gold,
        _Palette.fire => CelebrationPalette.fire,
        _Palette.party => CelebrationPalette.party,
        _Palette.rainbow => CelebrationPalette.rainbow,
      };
}

enum _Sound { builtIn, none, custom }

const List<Color> _accents = <Color>[
  Color(0xFFFFB300),
  Color(0xFFFF4081),
  Color(0xFF7C4DFF),
  Color(0xFF00E5FF),
  Color(0xFF00E676),
];

/// Build your own celebration: pick effects, length, colours, brand and
/// sound, scrub through it, then play it.
class PlaygroundPage extends StatefulWidget {
  /// Creates the playground.
  const PlaygroundPage({super.key});

  @override
  State<PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<PlaygroundPage> {
  final Set<_Effect> _effects = <_Effect>{
    _Effect.title,
    _Effect.rays,
    _Effect.confetti,
    _Effect.coins,
    _Effect.brandPop,
    _Effect.flash,
  };
  double _seconds = 4;
  double _amount = 1;
  double _dim = 0.35;
  _Palette _palette = _Palette.own;
  Color _accent = _accents.first;
  bool _brand = true;
  _Sound _sound = _Sound.builtIn;
  double _scrub = 0.3;
  final TextEditingController _title =
      TextEditingController(text: 'You did it!');
  final TextEditingController _subtitle = TextEditingController(text: '+1,000');

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    super.dispose();
  }

  CelebrationConfig? _cached;

  /// The config for the current settings, rebuilt only when they change.
  CelebrationConfig get _config => _cached ??= _build();

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _cached = null;
  }

  CelebrationConfig _build() {
    int n(int base) => math.max(1, (base * _amount).round());
    final palette = _palette.palette;
    bool on(_Effect e) => _effects.contains(e);
    return CelebrationConfig(
      duration: Duration(milliseconds: (_seconds * 1000).round()),
      color: _accent,
      palette: palette ?? CelebrationPalette.accent,
      backgroundDim: _dim,
      showBrandBadge: _brand,
      title: on(_Effect.title) ? _title.text : '',
      subtitle: _subtitle.text,
      seed: 7,
      effects: <CelebrationEffect>[
        if (on(_Effect.title)) const TitleSlamEffect(start: 0.02),
        if (on(_Effect.rays)) LightRaysEffect(palette: palette, start: 0.04),
        if (on(_Effect.sparkles))
          SparklesEffect(count: n(30), palette: palette, start: 0.05),
        if (on(_Effect.confetti))
          ConfettiEffect(
              count: n(120),
              palette: palette ?? CelebrationPalette.party,
              start: 0.03),
        if (on(_Effect.streamers))
          StreamersEffect(
              count: n(12),
              palette: palette ?? CelebrationPalette.party,
              start: 0.04),
        if (on(_Effect.coins))
          CoinsEffect(
              count: n(50),
              palette: palette ?? CelebrationPalette.gold,
              start: 0.06,
              end: 0.95),
        if (on(_Effect.flames))
          FlamesEffect(
              count: n(60),
              palette: palette ?? CelebrationPalette.fire,
              start: 0.04,
              end: 0.8),
        if (on(_Effect.fireworks))
          FireworksEffect(shells: n(4), palette: palette, start: 0.1),
        if (on(_Effect.brandPop))
          BrandPopEffect(count: n(12), maxSize: 0.5, start: 0.08, end: 0.92),
        if (on(_Effect.fireWall))
          FireWallEffect(palette: palette ?? CelebrationPalette.fire),
        if (on(_Effect.edgeGlow)) EdgeGlowEffect(palette: palette),
        if (on(_Effect.flash))
          const FlashEffect(strength: 0.6, start: 0.04, end: 0.14),
        if (on(_Effect.shake))
          const ShakeEffect(strength: 12, start: 0.04, end: 0.2),
      ],
      sound: switch (_sound) {
        _Sound.builtIn => CelebrationSound.builtIn(_closestTier),
        _Sound.none => const CelebrationSound.none(),
        _Sound.custom => const CelebrationSound.asset('assets/level_up.mp3'),
      },
      haptics: const CelebrationHaptics(<HapticPulse>[
        HapticPulse(0.04, CelebrationHapticKind.heavy),
        HapticPulse(0.08, CelebrationHapticKind.light),
      ]),
    );
  }

  /// The ready-made tier whose built-in sound is closest in length.
  CelebrationTier get _closestTier => CelebrationTier.values.reduce((a, b) =>
      (a.config.seconds - _seconds).abs() <= (b.config.seconds - _seconds).abs()
          ? a
          : b);

  void _celebrate() {
    YakoCelebration.show(
      context,
      tier: CelebrationTier.custom(_config, name: 'playground'),
      brand: _brand ? exampleBrand : const CelebrationBrand(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: <Widget>[
        AppCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: <Widget>[
              _Preview(
                config: _config,
                progress: _scrub,
                brand: _brand ? exampleBrand : const CelebrationBrand(),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  const SizedBox(width: 4),
                  const Icon(Icons.timelapse_rounded,
                      size: 18, color: AppColors.faint),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Slider(
                      value: _scrub,
                      // Scrubbing keeps the same config, so the layout
                      // stays put.
                      onChanged: (v) {
                        final keep = _cached;
                        setState(() => _scrub = v);
                        _cached = keep;
                      },
                    ),
                  ),
                  SizedBox(
                    width: 52,
                    child: Text(
                      '${(_scrub * _seconds).toStringAsFixed(1)} s',
                      textAlign: TextAlign.end,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _celebrate,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Celebrate'),
              ),
            ],
          ),
        ),
        const SectionLabel('Effects'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final effect in _Effect.values)
              FilterChip(
                label: Text(effect.label),
                selected: _effects.contains(effect),
                onSelected: (on) => setState(
                    () => on ? _effects.add(effect) : _effects.remove(effect)),
              ),
          ],
        ),
        const SectionLabel('Timing'),
        AppCard(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            children: <Widget>[
              _SliderRow(
                label: 'Length',
                value: _seconds,
                min: 1,
                max: 10,
                display: '${_seconds.toStringAsFixed(1)} s',
                onChanged: (v) => setState(() => _seconds = v),
              ),
              _SliderRow(
                label: 'Amount',
                value: _amount,
                min: 0.25,
                max: 2.5,
                display: '×${_amount.toStringAsFixed(2)}',
                onChanged: (v) => setState(() => _amount = v),
              ),
              _SliderRow(
                label: 'Dim',
                value: _dim,
                min: 0,
                max: 0.8,
                display: '${(_dim * 100).round()} %',
                onChanged: (v) => setState(() => _dim = v),
              ),
            ],
          ),
        ),
        const SectionLabel('Colours'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final p in _Palette.values)
                    ChoiceChip(
                      label: Text(p.label),
                      selected: _palette == p,
                      onSelected: (_) => setState(() => _palette = p),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  for (final color in _accents)
                    GestureDetector(
                      onTap: () => setState(() => _accent = color),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 34,
                        height: 34,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _accent == color
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SectionLabel('Text'),
        AppCard(
          child: Column(
            children: <Widget>[
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _subtitle,
                decoration: const InputDecoration(labelText: 'Subtitle'),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        const SectionLabel('Brand and sound'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Image.asset('assets/yako_logo.png', width: 28, height: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Your icon and name',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Switch(
                    value: _brand,
                    onChanged: (v) => setState(() => _brand = v),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SegmentedButton<_Sound>(
                showSelectedIcon: false,
                segments: const <ButtonSegment<_Sound>>[
                  ButtonSegment<_Sound>(
                      value: _Sound.builtIn, label: Text('Built-in')),
                  ButtonSegment<_Sound>(
                      value: _Sound.none, label: Text('No sound')),
                  ButtonSegment<_Sound>(
                      value: _Sound.custom, label: Text('Your own')),
                ],
                selected: <_Sound>{_sound},
                onSelectionChanged: (s) => setState(() => _sound = s.single),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: <Widget>[
        SizedBox(
          width: 64,
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        Expanded(
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
        SizedBox(
          width: 56,
          child: Text(
            display,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: row,
    );
  }
}

/// A small phone-shaped window showing the config at one moment.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.config,
    required this.progress,
    required this.brand,
  });

  final CelebrationConfig config;
  final double progress;
  final CelebrationBrand brand;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 340,
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: LayoutBuilder(
              builder: (context, box) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: box.biggest,
                  padding: EdgeInsets.zero,
                ),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[Color(0xFF141824), AppColors.background],
                    ),
                  ),
                  child: CelebrationPreview(
                    tier: CelebrationTier.custom(config, name: 'preview'),
                    progress: AlwaysStoppedAnimation<double>(progress),
                    brand: brand,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
