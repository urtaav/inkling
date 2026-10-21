import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../progress/progress_store.dart';

/// Phrases saved while reading, to review them.
class PhrasesScreen extends ConsumerWidget {
  const PhrasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(paletteProvider);
    final phrases = ref.watch(progressProvider).value?.phrases ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Mis frases')),
      body: phrases.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Toca una frase subrayada mientras lees y guárdala para '
                  'repasarla aquí.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.muted),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
              itemCount: phrases.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                // Lo más reciente arriba.
                final phrase = phrases[phrases.length - 1 - i];
                return ListTile(
                  title: Text(
                    phrase.text,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: palette.ink,
                    ),
                  ),
                  subtitle: Text(
                    '${phrase.meaning}\n${phrase.example}',
                    style: TextStyle(color: palette.muted, height: 1.4),
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: 'Quitar',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => ref
                        .read(progressProvider.notifier)
                        .apply((p) => p.removePhrase(phrase.text)),
                  ),
                );
              },
            ),
    );
  }
}
