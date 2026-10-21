import '../content/lesson.dart';
import 'progress.dart';

/// Calendar days between two local dates; UTC midnights avoid daylight-saving
/// days of 23 or 25 hours.
int _daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// The first unread lesson; once everything is read, the one read longest
/// ago. Lessons never run out, they just come back.
Lesson todayLesson(List<Lesson> library, Progress progress) {
  final unread = library.where((l) => !progress.isRead(l.id));
  if (unread.isNotEmpty) return unread.first;
  return library.reduce(
    (a, b) =>
        progress.reads[a.id]!.lastRead.isAfter(progress.reads[b.id]!.lastRead)
        ? b
        : a,
  );
}

/// Consecutive days with at least one finished lesson, ending today or
/// yesterday (today still has time).
int streak(Progress progress, DateTime today) {
  final days = {
    for (final record in progress.reads.values)
      for (final at in record.readAt) _daysBetween(at, today),
  };
  var start = days.contains(0) ? 0 : 1;
  var count = 0;
  while (days.contains(start + count)) {
    count++;
  }
  return count;
}

class ChallengeState {
  const ChallengeState({
    required this.started,
    this.day = 0,
    this.doneDays = const {},
    this.finished = false,
  });

  final bool started;

  /// 1–30: the day of the challenge today.
  final int day;

  /// Challenge days (1–30) with at least one finished lesson.
  final Set<int> doneDays;

  /// The 30 days are over.
  final bool finished;
}

ChallengeState challenge(Progress progress, DateTime today) {
  final start = progress.challengeStart;
  if (start == null) return const ChallengeState(started: false);
  final elapsed = _daysBetween(start, today);
  return ChallengeState(
    started: true,
    day: (elapsed + 1).clamp(1, 30),
    doneDays: {
      for (final record in progress.reads.values)
        for (final at in record.readAt)
          if (_daysBetween(start, at) case final d when d >= 0 && d < 30) d + 1,
    },
    finished: elapsed >= 30,
  );
}

int wordsPerMinute(int words, int seconds) =>
    seconds <= 0 ? 0 : (words * 60 / seconds).round();
