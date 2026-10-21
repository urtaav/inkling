import 'package:flutter/material.dart';

import '../progress/progress.dart';

/// Colors of one reading style. Warm and low-contrast on purpose, like an
/// e-reader: no pure white and no pure black.
class ReadingPalette {
  const ReadingPalette._({
    required this.name,
    required this.background,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.line,
    required this.accent,
    required this.isDark,
  });

  static const paper = ReadingPalette._(
    name: 'Papel',
    background: Color(0xFFF4F1EA),
    surface: Color(0xFFEAE5DA),
    ink: Color(0xFF2B2A28),
    muted: Color(0xFF7A746A),
    line: Color(0xFF8A8374),
    accent: Color(0xFF2F6B4F),
    isDark: false,
  );

  static const sepia = ReadingPalette._(
    name: 'Sepia',
    background: Color(0xFFEFE3CC),
    surface: Color(0xFFE4D5B9),
    ink: Color(0xFF45382A),
    muted: Color(0xFF85725A),
    line: Color(0xFF9C8466),
    accent: Color(0xFF7A4E2A),
    isDark: false,
  );

  static const night = ReadingPalette._(
    name: 'Noche',
    background: Color(0xFF1B1A18),
    surface: Color(0xFF262421),
    ink: Color(0xFFCFC8BB),
    muted: Color(0xFF8C857A),
    line: Color(0xFF7D766A),
    accent: Color(0xFF9DBF9E),
    isDark: true,
  );

  final String name;
  final Color background;

  /// Cards and sheets, a step away from the background.
  final Color surface;
  final Color ink;
  final Color muted;

  /// Dotted underline under phrases.
  final Color line;
  final Color accent;
  final bool isDark;
}

/// Auto: paper by day (7–18 h), sepia in the evening (18–21 h), night after.
ReadingPalette paletteFor(ThemeChoice choice, DateTime now) => switch (choice) {
  ThemeChoice.paper => ReadingPalette.paper,
  ThemeChoice.sepia => ReadingPalette.sepia,
  ThemeChoice.night => ReadingPalette.night,
  ThemeChoice.auto when now.hour >= 7 && now.hour < 18 => ReadingPalette.paper,
  ThemeChoice.auto when now.hour >= 18 && now.hour < 21 => ReadingPalette.sepia,
  ThemeChoice.auto => ReadingPalette.night,
};

/// The whole app wears the reading style: calm screens everywhere, not only
/// while reading.
ThemeData buildTheme(ReadingPalette p) {
  final scheme = ColorScheme(
    brightness: p.isDark ? Brightness.dark : Brightness.light,
    primary: p.accent,
    onPrimary: p.background,
    secondary: p.accent,
    onSecondary: p.background,
    error: const Color(0xFFB4533A),
    onError: Colors.white,
    surface: p.background,
    onSurface: p.ink,
    surfaceContainerHighest: p.surface,
    surfaceContainer: p.surface,
    surfaceContainerLow: p.surface,
    outline: p.muted,
    outlineVariant: p.line.withValues(alpha: 0.4),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.background,
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    // Sin animaciones de página: el cambio de pantalla es inmediato, como un
    // e-reader, y no cansa la vista.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
    ),
    dividerTheme: DividerThemeData(color: p.line.withValues(alpha: 0.3)),
  );
}

/// Text style for the lesson body.
TextStyle readingStyle(ReadingPalette p, double size) => TextStyle(
  fontFamily: 'Literata',
  fontSize: size,
  height: 1.65,
  color: p.ink,
);
