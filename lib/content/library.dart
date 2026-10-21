import 'dart:convert';

import 'package:flutter/services.dart';

import 'lesson.dart';

const lessonsIndex = 'assets/lessons/index.json';

/// Lessons from one batch file (a JSON list).
List<Lesson> parseBatch(String json) => [
  for (final item in (jsonDecode(json) as List).cast<Map>())
    Lesson.fromJson(item.cast<String, Object?>()),
];

/// Every lesson shipped with the app, in library order. Adding content is
/// adding a batch file and listing it in `index.json`.
Future<List<Lesson>> loadLibrary(AssetBundle bundle) async {
  final files = (jsonDecode(await bundle.loadString(lessonsIndex)) as List)
      .cast<String>();
  return [
    for (final file in files)
      ...parseBatch(await bundle.loadString('assets/lessons/$file')),
  ];
}
