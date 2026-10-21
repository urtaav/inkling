import 'package:flutter/material.dart';

import '../app/reading_theme.dart';
import '../content/lesson.dart';

/// "Trabajo · Debugging · 3 min · B1"
String lessonMeta(Lesson lesson) =>
    '${lesson.topic.label} · ${lesson.tag} · ${lesson.minutes} min · ${lesson.level}';

String formatSeconds(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

/// Small uppercase label above a section.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, required this.palette});

  final String text;
  final ReadingPalette palette;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
        color: palette.muted,
      ),
    ),
  );
}

/// Quiet card in the surface color, no shadows.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.palette, required this.child});

  final ReadingPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: palette.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );
}
