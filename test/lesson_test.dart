import 'package:flutter_test/flutter_test.dart';
import 'package:inkling/content/lesson.dart';

Map<String, Object?> lessonJson({
  List<String> paragraphs = const ['I want to [[look into]] it before lunch.'],
  String tense = 'pastSimple',
}) => {
  'id': 'w001',
  'title': 'The bug',
  'topic': 'work',
  'tag': 'Debugging',
  'level': 'B1',
  'tense': tense,
  'tenseTip': 'Algo que pasó y terminó.',
  'paragraphs': paragraphs,
  'phrases': [
    {
      'text': 'look into',
      'meaning': 'investigar',
      'example': "I'll look into the logs.",
    },
  ],
  'questions': [
    {'en': 'Could you help me?', 'es': '¿Me ayudas?'},
  ],
  'speak': 'Talk about a bug.',
};

void main() {
  test('a marked phrase splits the paragraph into text and phrase', () {
    final lesson = Lesson.fromJson(lessonJson());
    final parts = lesson.segments.single;

    expect(parts, hasLength(3));
    expect((parts[0] as TextSegment).text, 'I want to ');
    expect((parts[1] as PhraseSegment).text, 'look into');
    expect((parts[1] as PhraseSegment).phrase.meaning, 'investigar');
    expect((parts[2] as TextSegment).text, ' it before lunch.');
  });

  test('a mark resolves its phrase regardless of case', () {
    final lesson = Lesson.fromJson(
      lessonJson(paragraphs: ['[[Look into]] the logs first.']),
    );
    final phrase = lesson.segments.single.first as PhraseSegment;

    expect(phrase.text, 'Look into');
    expect(phrase.phrase.text, 'look into');
    expect(lesson.unresolvedMarks, isEmpty);
  });

  test('a mark without a phrase stays as plain text and is reported', () {
    final lesson = Lesson.fromJson(
      lessonJson(paragraphs: ['Please [[roll back]] the deploy.']),
    );

    expect(lesson.segments.single.whereType<PhraseSegment>(), isEmpty);
    expect(
      lesson.segments.single.map((s) => s.text).join(),
      'Please roll back the deploy.',
    );
    expect(lesson.unresolvedMarks, ['roll back']);
  });

  test('word count ignores the marks', () {
    final lesson = Lesson.fromJson(lessonJson());
    expect(lesson.wordCount, 8);
  });

  test('reading minutes round up at about 130 words per minute', () {
    final words = List.filled(300, 'word').join(' ');
    expect(Lesson.fromJson(lessonJson(paragraphs: [words])).minutes, 3);
  });

  test('tense and topic are parsed', () {
    final lesson = Lesson.fromJson(lessonJson(tense: 'futureGoingTo'));
    expect(lesson.tense, Tense.futureGoingTo);
    expect(lesson.topic, LessonTopic.work);
    expect(lesson.tense.label, 'Futuro con going to');
  });

  test('an unknown tense is a format error', () {
    expect(
      () => Lesson.fromJson(lessonJson(tense: 'pluperfect')),
      throwsFormatException,
    );
  });
}
