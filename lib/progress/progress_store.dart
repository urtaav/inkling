import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../content/lesson.dart';
import '../content/library.dart';
import 'progress.dart';

/// Small string storage; shared_preferences in the app, memory in tests.
abstract interface class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class PrefsStore implements KeyValueStore {
  final _prefs = SharedPreferencesAsync();

  @override
  Future<String?> read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);
}

final keyValueStoreProvider = Provider<KeyValueStore>((_) => PrefsStore());

/// Injectable "now", so tests can pick the day.
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

final libraryProvider = FutureProvider<List<Lesson>>(
  (_) => loadLibrary(rootBundle),
);

final progressProvider = AsyncNotifierProvider<ProgressNotifier, Progress>(
  ProgressNotifier.new,
);

class ProgressNotifier extends AsyncNotifier<Progress> {
  static const _key = 'progress';

  KeyValueStore get _store => ref.read(keyValueStoreProvider);

  @override
  Future<Progress> build() async {
    final raw = await _store.read(_key);
    if (raw == null) return const Progress();
    try {
      return Progress.fromJson(
        (jsonDecode(raw) as Map).cast<String, Object?>(),
      );
    } on Object {
      // Datos dañados: mejor empezar de cero que no poder abrir la app.
      return const Progress();
    }
  }

  /// Applies [change] and saves the result.
  Future<void> apply(Progress Function(Progress) change) async {
    final next = change(await future);
    state = AsyncData(next);
    await _store.write(_key, jsonEncode(next.toJson()));
  }
}
