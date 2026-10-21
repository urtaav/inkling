import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/reading_theme.dart';
import '../content/lesson.dart';
import '../progress/progress_store.dart';
import 'common.dart';
import 'speak_screen.dart';

/// E-reader view of a lesson with a quiet reading timer.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with WidgetsBindingObserver {
  final _watch = Stopwatch()..start();
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Solo cuenta el tiempo con la app al frente.
    if (state == AppLifecycleState.resumed) {
      _watch.start();
    } else {
      _watch.stop();
    }
  }

  Future<void> _finish(Lesson lesson) async {
    _watch.stop();
    final seconds = _watch.elapsed.inSeconds;
    final now = ref.read(clockProvider)();
    await ref
        .read(progressProvider.notifier)
        .apply((p) => p.markRead(lesson.id, seconds: seconds, at: now));
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => SpeakScreen(lessonId: lesson.id, readSeconds: seconds),
      ),
    );
  }

  void _showPhrase(Phrase phrase, ReadingPalette palette) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surface,
      showDragHandle: true,
      builder: (_) => _PhraseSheet(phrase: phrase, palette: palette),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(paletteProvider);
    final settings = ref.watch(settingsProvider);
    final lesson = ref.watch(lessonProvider(widget.lessonId));
    final favorite =
        ref.watch(progressProvider).value?.isFavorite(widget.lessonId) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lesson.value?.tag ?? '',
          style: TextStyle(fontSize: 14, color: palette.muted),
        ),
        actions: [
          Center(
            child: Text(
              '⏱ ${formatSeconds(_watch.elapsed.inSeconds)}',
              style: TextStyle(
                color: palette.muted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Favorito',
            onPressed: () => ref
                .read(progressProvider.notifier)
                .apply((p) => p.toggleFavorite(widget.lessonId)),
            icon: Icon(
              favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: favorite ? palette.accent : palette.muted,
            ),
          ),
        ],
      ),
      body: switch (lesson) {
        AsyncData(value: final lesson) => Center(
          child: ConstrainedBox(
            // ~65 caracteres por línea: más cómodo para leer.
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              children: [
                Text(
                  lesson.title,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: settings.fontSize + 6,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lessonMeta(lesson),
                  style: TextStyle(color: palette.muted, fontSize: 13),
                ),
                const SizedBox(height: 24),
                for (final paragraph in lesson.segments)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: _Paragraph(
                      parts: paragraph,
                      style: readingStyle(palette, settings.fontSize),
                      palette: palette,
                      onPhrase: (p) => _showPhrase(p, palette),
                    ),
                  ),
                const SizedBox(height: 8),
                Panel(
                  palette: palette,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionLabel(
                        'Enfoque: ${lesson.tense.label}',
                        palette: palette,
                      ),
                      Text(
                        lesson.tenseTip,
                        style: TextStyle(color: palette.ink, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SectionLabel('Preguntas útiles', palette: palette),
                for (final q in lesson.questions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.en,
                          style: readingStyle(palette, settings.fontSize - 1),
                        ),
                        Text(
                          q.es,
                          style: TextStyle(color: palette.muted, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _finish(lesson),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('Terminé'),
                ),
              ],
            ),
          ),
        ),
        AsyncError() => const Center(child: Text('No se encontró el texto.')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// A paragraph where phrases are dotted-underlined and tappable.
class _Paragraph extends StatelessWidget {
  const _Paragraph({
    required this.parts,
    required this.style,
    required this.palette,
    required this.onPhrase,
  });

  final List<Segment> parts;
  final TextStyle style;
  final ReadingPalette palette;
  final ValueChanged<Phrase> onPhrase;

  @override
  Widget build(BuildContext context) {
    final phraseStyle = style.copyWith(
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.dotted,
      decorationColor: palette.line,
      decorationThickness: 1.6,
    );
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          for (final part in parts)
            switch (part) {
              TextSegment() => TextSpan(text: part.text),
              PhraseSegment(:final phrase) => WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: GestureDetector(
                  onTap: () => onPhrase(phrase),
                  child: Text(part.text, style: phraseStyle),
                ),
              ),
            },
        ],
      ),
    );
  }
}

class _PhraseSheet extends ConsumerWidget {
  const _PhraseSheet({required this.phrase, required this.palette});

  final Phrase phrase;
  final ReadingPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved =
        ref.watch(progressProvider).value?.hasPhrase(phrase.text) ?? false;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            phrase.text,
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            phrase.meaning,
            style: TextStyle(fontSize: 16, color: palette.ink),
          ),
          const SizedBox(height: 12),
          Text(
            phrase.example,
            style: TextStyle(
              fontFamily: 'Literata',
              fontStyle: FontStyle.italic,
              fontSize: 16,
              color: palette.muted,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: saved
                ? null
                : () => ref
                      .read(progressProvider.notifier)
                      .apply((p) => p.savePhrase(phrase)),
            icon: Icon(
              saved ? Icons.check_rounded : Icons.bookmark_add_outlined,
            ),
            label: Text(saved ? 'Guardada en Mis frases' : 'Guardar frase'),
          ),
        ],
      ),
    );
  }
}
