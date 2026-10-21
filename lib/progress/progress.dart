import '../content/lesson.dart';

enum ThemeChoice { auto, paper, sepia, night }

class ReadingSettings {
  const ReadingSettings({this.theme = ThemeChoice.auto, this.fontSize = 18});

  factory ReadingSettings.fromJson(Map<String, Object?> json) =>
      ReadingSettings(
        theme:
            ThemeChoice.values.asNameMap()[json['theme']] ?? ThemeChoice.auto,
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 18,
      );

  final ThemeChoice theme;
  final double fontSize;

  ReadingSettings copyWith({ThemeChoice? theme, double? fontSize}) =>
      ReadingSettings(
        theme: theme ?? this.theme,
        fontSize: fontSize ?? this.fontSize,
      );

  Map<String, Object?> toJson() => {'theme': theme.name, 'fontSize': fontSize};
}

/// Every time a lesson was finished, plus its last and best reading time.
class ReadRecord {
  const ReadRecord({
    required this.readAt,
    required this.lastSeconds,
    required this.bestSeconds,
  });

  factory ReadRecord.fromJson(Map<String, Object?> json) => ReadRecord(
    readAt: [
      for (final ms in (json['readAt']! as List).cast<int>())
        DateTime.fromMillisecondsSinceEpoch(ms),
    ],
    lastSeconds: json['last']! as int,
    bestSeconds: json['best']! as int,
  );

  final List<DateTime> readAt;
  final int lastSeconds;
  final int bestSeconds;

  DateTime get lastRead => readAt.last;

  Map<String, Object?> toJson() => {
    'readAt': [for (final d in readAt) d.millisecondsSinceEpoch],
    'last': lastSeconds,
    'best': bestSeconds,
  };
}

/// Everything the user did, as an immutable value: each action returns a new
/// copy, which keeps the rules easy to test and the store a simple save.
class Progress {
  const Progress({
    this.reads = const {},
    this.favorites = const {},
    this.phrases = const [],
    this.challengeStart,
    this.settings = const ReadingSettings(),
  });

  factory Progress.fromJson(Map<String, Object?> json) => Progress(
    reads: {
      for (final e in (json['reads'] as Map? ?? {}).entries)
        e.key as String: ReadRecord.fromJson(
          (e.value as Map).cast<String, Object?>(),
        ),
    },
    favorites: {...(json['favorites'] as List? ?? const []).cast<String>()},
    phrases: [
      for (final p in (json['phrases'] as List? ?? const []).cast<Map>())
        Phrase.fromJson(p.cast<String, Object?>()),
    ],
    challengeStart: json['challengeStart'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(json['challengeStart']! as int),
    settings: ReadingSettings.fromJson(
      (json['settings'] as Map? ?? {}).cast<String, Object?>(),
    ),
  );

  final Map<String, ReadRecord> reads;
  final Set<String> favorites;
  final List<Phrase> phrases;

  /// Midnight of the first day of the 30-day challenge, or null.
  final DateTime? challengeStart;
  final ReadingSettings settings;

  bool isRead(String lessonId) => reads.containsKey(lessonId);
  bool isFavorite(String lessonId) => favorites.contains(lessonId);
  bool hasPhrase(String text) => phrases.any((p) => p.text == text);

  Progress _copy({
    Map<String, ReadRecord>? reads,
    Set<String>? favorites,
    List<Phrase>? phrases,
    DateTime? Function()? challengeStart,
    ReadingSettings? settings,
  }) => Progress(
    reads: reads ?? this.reads,
    favorites: favorites ?? this.favorites,
    phrases: phrases ?? this.phrases,
    challengeStart: challengeStart == null
        ? this.challengeStart
        : challengeStart(),
    settings: settings ?? this.settings,
  );

  Progress markRead(
    String lessonId, {
    required int seconds,
    required DateTime at,
  }) {
    final old = reads[lessonId];
    final record = ReadRecord(
      readAt: [...?old?.readAt, at],
      lastSeconds: seconds,
      bestSeconds: old == null || seconds < old.bestSeconds
          ? seconds
          : old.bestSeconds,
    );
    return _copy(reads: {...reads, lessonId: record});
  }

  Progress toggleFavorite(String lessonId) => _copy(
    favorites: isFavorite(lessonId)
        ? ({...favorites}..remove(lessonId))
        : {...favorites, lessonId},
  );

  Progress savePhrase(Phrase phrase) =>
      hasPhrase(phrase.text) ? this : _copy(phrases: [...phrases, phrase]);

  Progress removePhrase(String text) =>
      _copy(phrases: [...phrases.where((p) => p.text != text)]);

  Progress startChallenge(DateTime today) =>
      _copy(challengeStart: () => DateTime(today.year, today.month, today.day));

  Progress resetChallenge() => _copy(challengeStart: () => null);

  Progress withSettings(ReadingSettings settings) => _copy(settings: settings);

  Map<String, Object?> toJson() => {
    'reads': {for (final e in reads.entries) e.key: e.value.toJson()},
    'favorites': [...favorites],
    'phrases': [
      for (final p in phrases)
        {'text': p.text, 'meaning': p.meaning, 'example': p.example},
    ],
    'challengeStart': challengeStart?.millisecondsSinceEpoch,
    'settings': settings.toJson(),
  };
}
