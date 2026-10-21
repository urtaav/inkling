import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers.dart';
import 'app/reading_theme.dart';
import 'ui/home_screen.dart';

export 'ui/home_screen.dart';

void main() => runApp(const ProviderScope(child: InklingApp()));

class InklingApp extends ConsumerStatefulWidget {
  const InklingApp({super.key});

  @override
  ConsumerState<InklingApp> createState() => _InklingAppState();
}

class _InklingAppState extends ConsumerState<InklingApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // El modo automático depende de la hora: al volver se recalcula.
    if (state == AppLifecycleState.resumed) ref.invalidate(paletteProvider);
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(paletteProvider);
    return MaterialApp(
      title: 'inkling',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(palette),
      home: const HomeScreen(),
    );
  }
}
