import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/reading_theme.dart';
import '../content/lesson.dart';
import '../progress/picker.dart';
import '../speak/recorder.dart';
import 'common.dart';

/// After reading: a question to talk about for 1–2 minutes, recording your
/// voice to listen back.
class SpeakScreen extends ConsumerStatefulWidget {
  const SpeakScreen({super.key, required this.lessonId, this.readSeconds});

  final String lessonId;

  /// How long the reading took, when coming from the reader.
  final int? readSeconds;

  @override
  ConsumerState<SpeakScreen> createState() => _SpeakScreenState();
}

class _SpeakScreenState extends ConsumerState<SpeakScreen> {
  static const _limit = 120;

  List<Recording> _recordings = [];
  bool _recording = false;
  bool _denied = false;
  int _left = _limit;
  Timer? _countdown;

  VoiceRecorder get _recorder => ref.read(voiceRecorderProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _countdown?.cancel();
    if (_recording) _recorder.stop();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await _recorder.recordings(widget.lessonId);
    if (mounted) setState(() => _recordings = list);
  }

  Future<void> _toggle() async {
    if (_recording) return _stop();
    if (!await _recorder.requestPermission()) {
      setState(() => _denied = true);
      return;
    }
    await _recorder.start(widget.lessonId);
    setState(() {
      _denied = false;
      _recording = true;
      _left = _limit;
    });
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _left--);
      // Dos minutos bastan: se detiene sola para no llenar el teléfono.
      if (_left <= 0) _stop();
    });
  }

  Future<void> _stop() async {
    _countdown?.cancel();
    await _recorder.stop();
    if (!mounted) return;
    setState(() => _recording = false);
    await _load();
  }

  Future<void> _delete(Recording r) async {
    await _recorder.delete(r);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(paletteProvider);
    final lesson = ref.watch(lessonProvider(widget.lessonId));

    return Scaffold(
      appBar: AppBar(title: const Text('Hablar')),
      body: switch (lesson) {
        AsyncData(value: final lesson) => ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          children: [
            if (widget.readSeconds case final seconds?) ...[
              _ReadResult(seconds: seconds, lesson: lesson, palette: palette),
              const SizedBox(height: 20),
            ],
            SectionLabel('Habla 1–2 minutos', palette: palette),
            Text(lesson.speak, style: readingStyle(palette, 19)),
            const SizedBox(height: 20),
            SectionLabel('Intenta usar', palette: palette),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in lesson.phrases.take(4))
                  Chip(
                    label: Text(p.text),
                    backgroundColor: palette.surface,
                    side: BorderSide.none,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SectionLabel('Preguntas que puedes hacer', palette: palette),
            for (final q in lesson.questions)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  q.en,
                  style: TextStyle(color: palette.ink, fontSize: 15),
                ),
              ),
            const SizedBox(height: 28),
            Center(
              child: Column(
                children: [
                  IconButton.filled(
                    tooltip: _recording ? 'Detener' : 'Grabar',
                    iconSize: 36,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(76, 76),
                    ),
                    onPressed: _toggle,
                    icon: Icon(
                      _recording ? Icons.stop_rounded : Icons.mic_rounded,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _recording
                        ? 'Grabando · quedan ${formatSeconds(_left)}'
                        : 'Toca para grabarte',
                    style: TextStyle(color: palette.muted),
                  ),
                  if (_denied)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Para grabarte necesito permiso del micrófono. '
                        'Actívalo en los ajustes de Android.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: palette.ink),
                      ),
                    ),
                ],
              ),
            ),
            if (_recordings.isNotEmpty) ...[
              const SizedBox(height: 28),
              SectionLabel('Tus grabaciones', palette: palette),
              for (final (i, r) in _recordings.indexed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Grabación ${_recordings.length - i}'),
                  subtitle: Text(
                    '${r.createdAt.day}/${r.createdAt.month} · '
                    '${r.createdAt.hour}:${r.createdAt.minute.toString().padLeft(2, '0')}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Escuchar',
                        onPressed: () => _recorder.play(r),
                        icon: const Icon(Icons.play_arrow_rounded),
                      ),
                      IconButton(
                        tooltip: 'Borrar',
                        onPressed: () => _delete(r),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 28),
            OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Listo'),
            ),
          ],
        ),
        AsyncError() => const Center(child: Text('No se encontró el texto.')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _ReadResult extends StatelessWidget {
  const _ReadResult({
    required this.seconds,
    required this.lesson,
    required this.palette,
  });

  final int seconds;
  final Lesson lesson;
  final ReadingPalette palette;

  @override
  Widget build(BuildContext context) => Panel(
    palette: palette,
    child: Row(
      children: [
        Icon(Icons.check_circle_rounded, color: palette.accent),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Leíste en ${formatSeconds(seconds)} · '
            '${wordsPerMinute(lesson.wordCount, seconds)} palabras por minuto',
            style: TextStyle(color: palette.ink),
          ),
        ),
      ],
    ),
  );
}
