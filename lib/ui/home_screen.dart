import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/reading_theme.dart';
import '../content/lesson.dart';
import '../progress/picker.dart';
import '../progress/progress_store.dart';
import 'common.dart';
import 'library_screen.dart';
import 'phrases_screen.dart';
import 'reader_screen.dart';
import 'settings_screen.dart';

/// Today's lesson, the 30-day challenge and the streak.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(paletteProvider);
    final library = ref.watch(libraryProvider);
    final progress = ref.watch(progressProvider);
    final today = ref.watch(clockProvider)();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'inkling',
          style: TextStyle(fontFamily: 'Literata', fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'Ajustes',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _open(context, const SettingsScreen()),
          ),
        ],
      ),
      body: switch ((library, progress)) {
        (AsyncData(value: final lessons), AsyncData(value: final p)) =>
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _Streak(days: streak(p, today), palette: palette),
              const SizedBox(height: 20),
              _TodayCard(
                lesson: todayLesson(lessons, p),
                read: p.isRead(todayLesson(lessons, p).id),
                palette: palette,
              ),
              const SizedBox(height: 16),
              _ChallengeCard(state: challenge(p, today), palette: palette),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _open(context, const LibraryScreen()),
                      icon: const Icon(Icons.menu_book_rounded),
                      label: const Text('Biblioteca'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _open(context, const PhrasesScreen()),
                      icon: const Icon(Icons.bookmark_outline_rounded),
                      label: const Text('Mis frases'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${p.reads.length} de ${lessons.length} textos leídos',
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.muted, fontSize: 13),
              ),
            ],
          ),
        (AsyncError(), _) || (_, AsyncError()) => const Center(
          child: Text('No se pudieron cargar los textos.'),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

void _open(BuildContext context, Widget screen) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

class _Streak extends StatelessWidget {
  const _Streak({required this.days, required this.palette});

  final int days;
  final ReadingPalette palette;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        Icons.local_fire_department_rounded,
        color: days > 0 ? palette.accent : palette.muted,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          days == 0
              ? 'Lee hoy para empezar tu racha'
              : days == 1
              ? '1 día seguido'
              : '$days días seguidos',
          style: TextStyle(color: palette.ink, fontSize: 15),
        ),
      ),
    ],
  );
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.lesson,
    required this.read,
    required this.palette,
  });

  final Lesson lesson;
  final bool read;
  final ReadingPalette palette;

  @override
  Widget build(BuildContext context) => Panel(
    palette: palette,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel('Texto de hoy', palette: palette),
        Text(
          lesson.title,
          style: TextStyle(
            fontFamily: 'Literata',
            fontSize: 22,
            height: 1.3,
            fontWeight: FontWeight.w600,
            color: palette.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(lessonMeta(lesson), style: TextStyle(color: palette.muted)),
        const SizedBox(height: 4),
        Text(
          'Enfoque: ${lesson.tense.label}',
          style: TextStyle(color: palette.muted),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => _open(context, ReaderScreen(lessonId: lesson.id)),
          icon: const Icon(Icons.chrome_reader_mode_outlined),
          label: Text(read ? 'Leer otra vez' : 'Leer'),
        ),
      ],
    ),
  );
}

class _ChallengeCard extends ConsumerWidget {
  const _ChallengeCard({required this.state, required this.palette});

  final ChallengeState state;
  final ReadingPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(progressProvider.notifier);
    final today = ref.read(clockProvider)();
    void start() => notifier.apply((p) => p.startChallenge(today));

    if (!state.started) {
      return Panel(
        palette: palette,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel('Reto', palette: palette),
            Text(
              'Lee un texto distinto cada día durante 30 días.',
              style: TextStyle(color: palette.ink, fontSize: 15),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: start,
              child: const Text('Empezar reto de 30 días'),
            ),
          ],
        ),
      );
    }

    return Panel(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel('Reto de 30 días', palette: palette),
          Text(
            state.finished ? '¡Reto terminado!' : 'Día ${state.day} de 30',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var day = 1; day <= 30; day++)
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: state.doneDays.contains(day)
                        ? palette.accent
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: day == state.day && !state.finished
                          ? palette.ink
                          : palette.line.withValues(alpha: 0.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${state.doneDays.length} de 30 días cumplidos',
            style: TextStyle(color: palette.muted),
          ),
          if (state.finished) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: start,
              child: const Text('Empezar otro reto'),
            ),
          ],
        ],
      ),
    );
  }
}
