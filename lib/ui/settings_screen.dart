import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/reading_theme.dart';
import '../progress/progress.dart';
import '../progress/progress_store.dart';
import 'common.dart';

const _themeLabels = {
  ThemeChoice.auto: 'Automático',
  ThemeChoice.paper: 'Papel',
  ThemeChoice.sepia: 'Sepia',
  ThemeChoice.night: 'Noche',
};

/// Reading style, text size and the challenge.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(paletteProvider);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(progressProvider.notifier);
    final challengeOn =
        ref.watch(progressProvider).value?.challengeStart != null;

    void save(ReadingSettings s) => notifier.apply((p) => p.withSettings(s));

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          SectionLabel('Estilo de lectura', palette: palette),
          RadioGroup<ThemeChoice>(
            groupValue: settings.theme,
            onChanged: (c) => save(settings.copyWith(theme: c)),
            child: Column(
              children: [
                for (final choice in ThemeChoice.values)
                  RadioListTile<ThemeChoice>(
                    contentPadding: EdgeInsets.zero,
                    value: choice,
                    title: Text(_themeLabels[choice]!),
                    subtitle: choice == ThemeChoice.auto
                        ? const Text(
                            'Papel de día, sepia en la tarde, noche después de las 9',
                          )
                        : null,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionLabel(
            'Tamaño de letra · ${settings.fontSize.round()}',
            palette: palette,
          ),
          Slider(
            value: settings.fontSize,
            min: 16,
            max: 24,
            divisions: 8,
            onChanged: (v) => save(settings.copyWith(fontSize: v)),
          ),
          Panel(
            palette: palette,
            child: Text(
              'I decided to look into it before the daily meeting.',
              style: readingStyle(palette, settings.fontSize),
            ),
          ),
          if (challengeOn) ...[
            const SizedBox(height: 28),
            SectionLabel('Reto de 30 días', palette: palette),
            OutlinedButton(
              onPressed: () => notifier.apply((p) => p.resetChallenge()),
              child: const Text('Reiniciar reto'),
            ),
          ],
        ],
      ),
    );
  }
}
