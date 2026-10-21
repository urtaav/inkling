import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/lesson.dart';
import '../progress/progress.dart';
import '../progress/progress_store.dart';
import 'reading_theme.dart';

/// Current reading settings; defaults while progress is loading.
final settingsProvider = Provider<ReadingSettings>(
  (ref) =>
      ref.watch(progressProvider).value?.settings ?? const ReadingSettings(),
);

/// Style to paint with now. In automatic mode it is decided when the screen
/// builds; the app re-evaluates it when it comes back to the front.
final paletteProvider = Provider<ReadingPalette>(
  (ref) =>
      paletteFor(ref.watch(settingsProvider).theme, ref.watch(clockProvider)()),
);

final lessonProvider = FutureProvider.family<Lesson, String>((ref, id) async {
  final library = await ref.watch(libraryProvider.future);
  return library.firstWhere((l) => l.id == id);
});
