import 'package:flutter/material.dart';

/// Colours of the example app.
abstract final class AppColors {
  /// The page behind everything; also the stage for recordings.
  static const Color background = Color(0xFF08090E);

  /// Cards.
  static const Color surface = Color(0xFF12141B);

  /// Raised parts inside cards.
  static const Color surfaceHigh = Color(0xFF1B1E27);

  /// Hairline borders.
  static const Color line = Color(0x14FFFFFF);

  /// Yako blue.
  static const Color accent = Color(0xFF00A7EE);

  /// Secondary text.
  static const Color muted = Color(0x99FFFFFF);

  /// Hints.
  static const Color faint = Color(0x61FFFFFF);
}

/// The example app's dark theme.
ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.accent,
    onPrimary: Colors.white,
    surface: AppColors.surface,
    surfaceContainerHighest: AppColors.surfaceHigh,
    outlineVariant: AppColors.line,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    textTheme: base.textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.background,
      indicatorColor: AppColors.accent.withValues(alpha: 0.18),
      surfaceTintColor: Colors.transparent,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.faint,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.faint,
        ),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surfaceHigh,
      selectedColor: AppColors.accent.withValues(alpha: 0.22),
      side: const BorderSide(color: AppColors.line),
      shape: const StadiumBorder(),
      showCheckmark: false,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
    sliderTheme: base.sliderTheme.copyWith(
      trackHeight: 4,
      inactiveTrackColor: AppColors.surfaceHigh,
      overlayShape: SliderComponentShape.noOverlay,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceHigh,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      labelStyle: const TextStyle(color: AppColors.muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
  );
}

/// A rounded card with a hairline border.
class AppCard extends StatelessWidget {
  /// Wraps [child].
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  /// The content.
  final Widget child;

  /// Space inside the card.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// A small upper-case label above a group of controls.
class SectionLabel extends StatelessWidget {
  /// Shows [text].
  const SectionLabel(this.text, {super.key});

  /// The label.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.faint,
        ),
      ),
    );
  }
}
