import 'package:flutter_test/flutter_test.dart';
import 'package:inkling/content/lesson.dart';
import 'package:inkling/progress/picker.dart';
import 'package:inkling/progress/progress.dart';

import 'lesson_test.dart' show lessonJson;

Lesson lesson(String id) => Lesson.fromJson({...lessonJson(), 'id': id});

void main() {
  final library = [lesson('a'), lesson('b'), lesson('c')];
  final monday = DateTime(2026, 10, 19, 9);

  group('today lesson', () {
    test('is the first unread lesson in library order', () {
      final p = const Progress().markRead('a', seconds: 180, at: monday);
      expect(todayLesson(library, p).id, 'b');
    });

    test('when everything is read, it is the one read longest ago', () {
      final p = const Progress()
          .markRead('a', seconds: 1, at: monday)
          .markRead(
            'b',
            seconds: 1,
            at: monday.subtract(const Duration(days: 3)),
          )
          .markRead(
            'c',
            seconds: 1,
            at: monday.subtract(const Duration(days: 1)),
          );
      expect(todayLesson(library, p).id, 'b');
    });
  });

  group('reading records', () {
    test('keep the last and the best time and every date', () {
      final p = const Progress()
          .markRead('a', seconds: 200, at: monday)
          .markRead('a', seconds: 150, at: monday.add(const Duration(days: 1)))
          .markRead('a', seconds: 170, at: monday.add(const Duration(days: 2)));
      final record = p.reads['a']!;
      expect(record.lastSeconds, 170);
      expect(record.bestSeconds, 150);
      expect(record.readAt, hasLength(3));
    });

    test('favorites toggle on and off', () {
      final p = const Progress().toggleFavorite('a');
      expect(p.favorites, {'a'});
      expect(p.toggleFavorite('a').favorites, isEmpty);
    });

    test('saved phrases are not duplicated and can be removed', () {
      const phrase = Phrase(
        text: 'look into',
        meaning: 'investigar',
        example: 'e',
      );
      final p = const Progress().savePhrase(phrase).savePhrase(phrase);
      expect(p.phrases, hasLength(1));
      expect(p.removePhrase('look into').phrases, isEmpty);
    });

    test('progress survives a JSON round trip', () {
      const phrase = Phrase(
        text: 'look into',
        meaning: 'investigar',
        example: 'e',
      );
      final p = const Progress()
          .markRead('a', seconds: 200, at: monday)
          .toggleFavorite('b')
          .savePhrase(phrase)
          .startChallenge(monday)
          .withSettings(
            const ReadingSettings(theme: ThemeChoice.night, fontSize: 20),
          );
      final back = Progress.fromJson(p.toJson());
      expect(back.reads['a']!.bestSeconds, 200);
      expect(back.favorites, {'b'});
      expect(back.phrases.single.meaning, 'investigar');
      expect(back.challengeStart, DateTime(2026, 10, 19));
      expect(back.settings.theme, ThemeChoice.night);
      expect(back.settings.fontSize, 20);
    });
  });

  group('streak', () {
    Progress readOn(List<int> daysAgo) => daysAgo.fold(
      const Progress(),
      (p, d) =>
          p.markRead('a', seconds: 1, at: monday.subtract(Duration(days: d))),
    );

    test('counts consecutive days ending today', () {
      expect(streak(readOn([0, 1, 2]), monday), 3);
    });

    test('is still alive if the last read was yesterday', () {
      expect(streak(readOn([1, 2]), monday), 2);
    });

    test('is broken after a missed day', () {
      expect(streak(readOn([2, 3]), monday), 0);
    });

    test('reading twice in a day counts once', () {
      expect(streak(readOn([0, 0, 1]), monday), 2);
    });
  });

  group('30-day challenge', () {
    test('not started until the user starts it', () {
      expect(challenge(const Progress(), monday).started, isFalse);
    });

    test('knows the current day and which days were done', () {
      final p = const Progress()
          .startChallenge(monday.subtract(const Duration(days: 4)))
          .markRead(
            'a',
            seconds: 1,
            at: monday.subtract(const Duration(days: 4)),
          )
          .markRead(
            'b',
            seconds: 1,
            at: monday.subtract(const Duration(days: 2)),
          )
          .markRead('c', seconds: 1, at: monday);
      final state = challenge(p, monday);
      expect(state.day, 5);
      expect(state.doneDays, {1, 3, 5});
      expect(state.finished, isFalse);
    });

    test('reads before the challenge do not count', () {
      final p = const Progress()
          .markRead(
            'a',
            seconds: 1,
            at: monday.subtract(const Duration(days: 1)),
          )
          .startChallenge(monday);
      expect(challenge(p, monday).doneDays, isEmpty);
    });

    test('is finished after day 30', () {
      final p = const Progress().startChallenge(
        monday.subtract(const Duration(days: 30)),
      );
      final state = challenge(p, monday);
      expect(state.finished, isTrue);
      expect(state.day, 30);
    });

    test('restarting clears the start date', () {
      final p = const Progress().startChallenge(monday).resetChallenge();
      expect(p.challengeStart, isNull);
    });
  });

  test('words per minute from words and seconds', () {
    expect(wordsPerMinute(300, 150), 120);
    expect(wordsPerMinute(300, 0), 0);
  });
}
