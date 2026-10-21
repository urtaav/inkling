import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkling/progress/progress_store.dart';

class MemoryStore implements KeyValueStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

void main() {
  test('progress is saved and read back by a new session', () async {
    final store = MemoryStore();
    final first = ProviderContainer(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    await first.read(progressProvider.future);
    await first
        .read(progressProvider.notifier)
        .apply((p) => p.toggleFavorite('w001'));
    first.dispose();

    final second = ProviderContainer(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    final progress = await second.read(progressProvider.future);
    expect(progress.favorites, {'w001'});
    second.dispose();
  });

  test('broken saved data starts fresh instead of crashing', () async {
    final store = MemoryStore()..values['progress'] = '{not json';
    final container = ProviderContainer(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    final progress = await container.read(progressProvider.future);
    expect(progress.reads, isEmpty);
    container.dispose();
  });
}
