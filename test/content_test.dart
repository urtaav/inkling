import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkling/content/lesson.dart';
import 'package:inkling/content/library.dart';

/// Checks the real lessons shipped in assets/, so a content typo fails here
/// instead of on the phone.
void main() {
  final files = (jsonDecode(File(lessonsIndex).readAsStringSync()) as List)
      .cast<String>();
  final lessons = [
    for (final file in files)
      ...parseBatch(File('assets/lessons/$file').readAsStringSync()),
  ];

  test('there are lessons and ids are unique', () {
    expect(lessons, isNotEmpty);
    final ids = lessons.map((l) => l.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('every lesson takes about three minutes (280–420 words)', () {
    // Todas las que fallan a la vez, para corregirlas en una pasada.
    final outOfRange = [
      for (final lesson in lessons)
        if (lesson.wordCount < 280 || lesson.wordCount > 420)
          '${lesson.id}: ${lesson.wordCount}',
    ];
    expect(outOfRange, isEmpty);
  });

  test('every marked phrase has its meaning', () {
    for (final lesson in lessons) {
      expect(lesson.unresolvedMarks, isEmpty, reason: lesson.id);
    }
  });

  test('every phrase in the glossary is marked in the text', () {
    for (final lesson in lessons) {
      final marked = {
        for (final part in lesson.segments.expand((s) => s))
          if (part is PhraseSegment) part.phrase.text,
      };
      for (final phrase in lesson.phrases) {
        expect(
          marked,
          contains(phrase.text),
          reason: '${lesson.id}: ${phrase.text}',
        );
      }
    }
  });

  test('every lesson has phrases, questions and a speaking prompt', () {
    for (final lesson in lessons) {
      expect(lesson.phrases.length, greaterThanOrEqualTo(3), reason: lesson.id);
      expect(
        lesson.questions.length,
        greaterThanOrEqualTo(3),
        reason: lesson.id,
      );
      expect(lesson.speak.trim(), isNotEmpty, reason: lesson.id);
      expect(lesson.tenseTip.trim(), isNotEmpty, reason: lesson.id);
      expect(['A2', 'B1'], contains(lesson.level), reason: lesson.id);
    }
  });

  test('the library covers the seven tenses', () {
    expect(lessons.map((l) => l.tense).toSet(), Tense.values.toSet());
  });

  test('most lessons are about software work', () {
    final work = lessons.where((l) => l.topic == LessonTopic.work).length;
    expect(work / lessons.length, greaterThanOrEqualTo(0.6));
  });
}
