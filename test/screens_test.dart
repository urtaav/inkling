import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkling/content/lesson.dart';
import 'package:inkling/main.dart';
import 'package:inkling/progress/progress.dart';
import 'package:inkling/progress/progress_store.dart';
import 'package:inkling/speak/recorder.dart';
import 'package:inkling/ui/library_screen.dart';
import 'package:inkling/ui/phrases_screen.dart';
import 'package:inkling/ui/reader_screen.dart';
import 'package:inkling/ui/settings_screen.dart';
import 'package:inkling/ui/speak_screen.dart';

import 'lesson_test.dart' show lessonJson;
import 'progress_store_test.dart' show MemoryStore;

Lesson lesson(String id, String title) =>
    Lesson.fromJson({...lessonJson(), 'id': id, 'title': title});

final lessons = [
  lesson('a', 'Lesson A'),
  lesson('b', 'Lesson B'),
  lesson('c', 'Lesson C'),
];

class FakeRecorder implements VoiceRecorder {
  FakeRecorder({this.allowed = true});

  final bool allowed;
  bool recording = false;
  final saved = <Recording>[];

  @override
  Future<bool> requestPermission() async => allowed;

  @override
  Future<void> start(String lessonId) async => recording = true;

  @override
  Future<Recording?> stop() async {
    recording = false;
    final r = Recording(
      path: 'r${saved.length}.m4a',
      createdAt: DateTime(2026, 10, 21, 9, saved.length),
    );
    saved.insert(0, r);
    return r;
  }

  @override
  Future<List<Recording>> recordings(String lessonId) async => [...saved];

  @override
  Future<void> play(Recording recording) async {}

  @override
  Future<void> stopPlaying() async {}

  @override
  Future<void> delete(Recording recording) async => saved.remove(recording);
}

class Harness {
  final store = MemoryStore();
  final recorder = FakeRecorder();
  late ProviderContainer container;

  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    FakeRecorder? recorder,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    container = ProviderContainer(
      overrides: [
        keyValueStoreProvider.overrideWithValue(store),
        libraryProvider.overrideWith((_) async => lessons),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 21, 10)),
        voiceRecorderProvider.overrideWithValue(recorder ?? this.recorder),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: home),
      ),
    );
    await settle(tester);
  }

  /// The reader's clock ticks every second, so pumpAndSettle would never end.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Progress get progress => container.read(progressProvider).requireValue;
}

void main() {
  testWidgets('home shows today\'s lesson and starts the challenge', (
    tester,
  ) async {
    final h = Harness();
    await h.pump(tester, const HomeScreen());

    expect(find.text('Lesson A'), findsOneWidget);
    expect(find.text('Leer'), findsOneWidget);

    await tester.tap(find.text('Empezar reto de 30 días'));
    await h.settle(tester);
    expect(find.text('Día 1 de 30'), findsOneWidget);
  });

  testWidgets('tapping a phrase shows its meaning and saves it', (
    tester,
  ) async {
    final h = Harness();
    await h.pump(tester, const ReaderScreen(lessonId: 'a'));

    await tester.tap(find.text('look into'));
    await h.settle(tester);
    expect(find.text('investigar'), findsOneWidget);

    await tester.tap(find.text('Guardar frase'));
    await h.settle(tester);
    expect(h.progress.hasPhrase('look into'), isTrue);
  });

  testWidgets('the heart marks the lesson as favorite', (tester) async {
    final h = Harness();
    await h.pump(tester, const ReaderScreen(lessonId: 'a'));

    await tester.tap(find.byTooltip('Favorito'));
    await h.settle(tester);
    expect(h.progress.isFavorite('a'), isTrue);
  });

  testWidgets('finishing a lesson saves it and moves on to speaking', (
    tester,
  ) async {
    final h = Harness();
    await h.pump(tester, const ReaderScreen(lessonId: 'a'));

    await tester.scrollUntilVisible(find.text('Terminé'), 300);
    await tester.tap(find.text('Terminé'));
    await h.settle(tester);

    expect(h.progress.isRead('a'), isTrue);
    expect(find.text('Talk about a bug.'), findsOneWidget);
  });

  testWidgets('the library filters favorites and unread', (tester) async {
    final h = Harness();
    h.store.values['progress'] =
        '{"favorites":["b"],"reads":{"a":{"readAt":[1],"last":60,"best":60}}}';
    await h.pump(tester, const LibraryScreen());

    expect(find.text('Lesson A'), findsOneWidget);
    expect(find.text('Lesson C'), findsOneWidget);

    await tester.tap(find.text('Favoritos'));
    await h.settle(tester);
    expect(find.text('Lesson B'), findsOneWidget);
    expect(find.text('Lesson A'), findsNothing);

    await tester.tap(find.text('Sin leer'));
    await h.settle(tester);
    expect(find.text('Lesson A'), findsNothing);
    expect(find.text('Lesson C'), findsOneWidget);
  });

  testWidgets('speaking: record, stop and list the recording', (tester) async {
    final h = Harness();
    await h.pump(tester, const SpeakScreen(lessonId: 'a'));

    await tester.tap(find.byTooltip('Grabar'));
    await h.settle(tester);
    expect(h.recorder.recording, isTrue);

    await tester.tap(find.byTooltip('Detener'));
    await h.settle(tester);
    expect(h.recorder.recording, isFalse);
    expect(find.byTooltip('Escuchar'), findsOneWidget);
  });

  testWidgets('without the microphone it explains why it cannot record', (
    tester,
  ) async {
    final h = Harness();
    await h.pump(
      tester,
      const SpeakScreen(lessonId: 'a'),
      recorder: FakeRecorder(allowed: false),
    );

    await tester.tap(find.byTooltip('Grabar'));
    await h.settle(tester);
    expect(find.textContaining('micrófono'), findsOneWidget);
  });

  testWidgets('saved phrases are listed and can be removed', (tester) async {
    final h = Harness();
    h.store.values['progress'] = '{"phrases":[{"text":"look into","meaning":"investigar","example":"I\'ll look into it."}]}';
    await h.pump(tester, const PhrasesScreen());

    expect(find.text('look into'), findsOneWidget);
    await tester.tap(find.byTooltip('Quitar'));
    await h.settle(tester);
    expect(h.progress.phrases, isEmpty);
  });

  testWidgets('settings change the reading style', (tester) async {
    final h = Harness();
    await h.pump(tester, const SettingsScreen());

    await tester.tap(find.text('Noche'));
    await h.settle(tester);
    expect(h.progress.settings.theme, ThemeChoice.night);
  });
}
