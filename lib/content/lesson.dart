/// The seven tenses every batch of lessons covers.
enum Tense {
  presentSimple('Presente simple'),
  presentContinuous('Presente continuo'),
  pastSimple('Pasado simple'),
  pastContinuous('Pasado continuo'),
  presentPerfect('Presente perfecto'),
  futureWill('Futuro con will'),
  futureGoingTo('Futuro con going to');

  const Tense(this.label);

  final String label;
}

enum LessonTopic {
  work('Trabajo'),
  life('Vida');

  const LessonTopic(this.label);

  final String label;
}

/// A phrasal verb or useful expression marked in the text with `[[...]]`.
class Phrase {
  const Phrase({
    required this.text,
    required this.meaning,
    required this.example,
  });

  factory Phrase.fromJson(Map<String, Object?> json) => Phrase(
    text: json['text']! as String,
    meaning: json['meaning']! as String,
    example: json['example']! as String,
  );

  final String text;
  final String meaning;
  final String example;
}

/// A question worth practicing, with its meaning in Spanish.
class UsefulQuestion {
  const UsefulQuestion({required this.en, required this.es});

  factory UsefulQuestion.fromJson(Map<String, Object?> json) =>
      UsefulQuestion(en: json['en']! as String, es: json['es']! as String);

  final String en;
  final String es;
}

/// A piece of a paragraph: plain text or a highlighted phrase.
sealed class Segment {
  const Segment(this.text);

  final String text;
}

class TextSegment extends Segment {
  const TextSegment(super.text);
}

class PhraseSegment extends Segment {
  const PhraseSegment(super.text, this.phrase);

  final Phrase phrase;
}

class Lesson {
  Lesson({
    required this.id,
    required this.title,
    required this.topic,
    required this.tag,
    required this.level,
    required this.tense,
    required this.tenseTip,
    required this.paragraphs,
    required this.phrases,
    required this.questions,
    required this.speak,
  });

  factory Lesson.fromJson(Map<String, Object?> json) {
    final tenseName = json['tense'] as String?;
    final tense = Tense.values.asNameMap()[tenseName];
    if (tense == null) {
      throw FormatException('Tiempo desconocido: $tenseName', json['id']);
    }
    return Lesson(
      id: json['id']! as String,
      title: json['title']! as String,
      topic: LessonTopic.values.byName(json['topic']! as String),
      tag: json['tag']! as String,
      level: json['level']! as String,
      tense: tense,
      tenseTip: json['tenseTip']! as String,
      paragraphs: (json['paragraphs']! as List).cast<String>(),
      phrases: [
        for (final p in (json['phrases']! as List).cast<Map>())
          Phrase.fromJson(p.cast<String, Object?>()),
      ],
      questions: [
        for (final q in (json['questions']! as List).cast<Map>())
          UsefulQuestion.fromJson(q.cast<String, Object?>()),
      ],
      speak: json['speak']! as String,
    );
  }

  final String id;
  final String title;
  final LessonTopic topic;
  final String tag;
  final String level;
  final Tense tense;
  final String tenseTip;
  final List<String> paragraphs;
  final List<Phrase> phrases;
  final List<UsefulQuestion> questions;
  final String speak;

  static final _mark = RegExp(r'\[\[(.+?)\]\]');

  /// Paragraphs split into plain text and highlighted phrases. A mark with no
  /// matching phrase becomes plain text, so a content typo never breaks reading.
  late final List<List<Segment>> segments = [
    for (final paragraph in paragraphs) _split(paragraph),
  ];

  /// Marks that don't match any phrase; the content tests keep this empty.
  late final List<String> unresolvedMarks = [
    for (final paragraph in paragraphs)
      for (final match in _mark.allMatches(paragraph))
        if (_phraseFor(match[1]!) == null) match[1]!,
  ];

  late final int wordCount = paragraphs
      .map((p) => p.replaceAllMapped(_mark, (m) => m[1]!))
      .expand((p) => p.split(RegExp(r'\s+')))
      .where((w) => w.isNotEmpty)
      .length;

  /// About 130 words per minute: a relaxed A2–B1 reading pace.
  int get minutes => (wordCount / 130).ceil();

  Phrase? _phraseFor(String text) {
    final key = text.toLowerCase();
    return phrases.where((p) => p.text.toLowerCase() == key).firstOrNull;
  }

  List<Segment> _split(String paragraph) {
    final parts = <Segment>[];
    var plain = StringBuffer();
    var last = 0;
    for (final match in _mark.allMatches(paragraph)) {
      plain.write(paragraph.substring(last, match.start));
      final phrase = _phraseFor(match[1]!);
      if (phrase == null) {
        plain.write(match[1]);
      } else {
        if (plain.isNotEmpty) parts.add(TextSegment(plain.toString()));
        plain = StringBuffer();
        parts.add(PhraseSegment(match[1]!, phrase));
      }
      last = match.end;
    }
    plain.write(paragraph.substring(last));
    if (plain.isNotEmpty) parts.add(TextSegment(plain.toString()));
    return parts;
  }
}
