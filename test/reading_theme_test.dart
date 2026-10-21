import 'package:flutter_test/flutter_test.dart';
import 'package:inkling/app/reading_theme.dart';
import 'package:inkling/progress/progress.dart';

void main() {
  DateTime at(int hour, [int minute = 0]) =>
      DateTime(2026, 10, 21, hour, minute);

  test('automatic style follows the time of day', () {
    expect(paletteFor(ThemeChoice.auto, at(6, 59)), ReadingPalette.night);
    expect(paletteFor(ThemeChoice.auto, at(7)), ReadingPalette.paper);
    expect(paletteFor(ThemeChoice.auto, at(17, 59)), ReadingPalette.paper);
    expect(paletteFor(ThemeChoice.auto, at(18)), ReadingPalette.sepia);
    expect(paletteFor(ThemeChoice.auto, at(20, 59)), ReadingPalette.sepia);
    expect(paletteFor(ThemeChoice.auto, at(21)), ReadingPalette.night);
  });

  test('a chosen style ignores the time', () {
    expect(paletteFor(ThemeChoice.paper, at(23)), ReadingPalette.paper);
    expect(paletteFor(ThemeChoice.night, at(12)), ReadingPalette.night);
  });

  test('the three styles use the agreed colors', () {
    expect(ReadingPalette.paper.background.toARGB32(), 0xFFF4F1EA);
    expect(ReadingPalette.sepia.background.toARGB32(), 0xFFEFE3CC);
    expect(ReadingPalette.night.background.toARGB32(), 0xFF1B1A18);
    expect(ReadingPalette.night.isDark, isTrue);
    expect(ReadingPalette.paper.isDark, isFalse);
  });
}
