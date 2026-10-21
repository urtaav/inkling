import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../content/lesson.dart';
import '../progress/progress.dart';
import '../progress/progress_store.dart';
import 'common.dart';
import 'reader_screen.dart';

enum _Filter {
  all('Todos'),
  work('Trabajo'),
  life('Vida'),
  favorites('Favoritos'),
  read('Leídos'),
  unread('Sin leer');

  const _Filter(this.label);

  final String label;

  bool keeps(Lesson lesson, Progress p) => switch (this) {
    _Filter.all => true,
    _Filter.work => lesson.topic == LessonTopic.work,
    _Filter.life => lesson.topic == LessonTopic.life,
    _Filter.favorites => p.isFavorite(lesson.id),
    _Filter.read => p.isRead(lesson.id),
    _Filter.unread => !p.isRead(lesson.id),
  };
}

/// Every lesson, to reread favorites or pick a topic.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(paletteProvider);
    final library = ref.watch(libraryProvider).value ?? const [];
    final progress = ref.watch(progressProvider).value ?? const Progress();
    final shown = library.where((l) => _filter.keeps(l, progress)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Biblioteca')),
      body: Column(
        children: [
          // Todos los filtros a la vista, sin deslizar.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final f in _Filter.values)
                  ChoiceChip(
                    label: Text(f.label),
                    selected: _filter == f,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
              ],
            ),
          ),
          Expanded(
            child: shown.isEmpty
                ? Center(
                    child: Text(
                      'Nada por aquí todavía.',
                      style: TextStyle(color: palette.muted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final lesson = shown[i];
                      final read = progress.isRead(lesson.id);
                      return ListTile(
                        title: Text(
                          lesson.title,
                          style: TextStyle(
                            fontFamily: 'Literata',
                            fontSize: 17,
                            color: read ? palette.muted : palette.ink,
                          ),
                        ),
                        subtitle: Text(
                          '${lessonMeta(lesson)}\n${lesson.tense.label}',
                          style: TextStyle(color: palette.muted, fontSize: 13),
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (progress.isFavorite(lesson.id))
                              Icon(
                                Icons.favorite_rounded,
                                size: 18,
                                color: palette.accent,
                              ),
                            if (read)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 20,
                                  color: palette.muted,
                                ),
                              ),
                          ],
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ReaderScreen(lessonId: lesson.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
