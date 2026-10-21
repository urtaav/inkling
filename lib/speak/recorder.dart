import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// One recording of the user speaking about a lesson.
class Recording {
  const Recording({required this.path, required this.createdAt});

  final String path;
  final DateTime createdAt;
}

/// Records and plays the user's voice. Files stay in the app's private
/// folder: nothing leaves the phone.
abstract interface class VoiceRecorder {
  /// Asks for the microphone if needed; false when the user said no.
  Future<bool> requestPermission();
  Future<void> start(String lessonId);

  /// Stops and returns the new recording, or null if nothing was recording.
  Future<Recording?> stop();
  Future<List<Recording>> recordings(String lessonId);

  /// Completes when the playback ends or is stopped.
  Future<void> play(Recording recording);
  Future<void> stopPlaying();
  Future<void> delete(Recording recording);
}

class DeviceVoiceRecorder implements VoiceRecorder {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  Future<Directory> _folder() async {
    final dir = Directory(
      '${(await getApplicationDocumentsDirectory()).path}/recordings',
    );
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  @override
  Future<bool> requestPermission() => _recorder.hasPermission();

  @override
  Future<void> start(String lessonId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final path = '${(await _folder()).path}/${lessonId}_$now.m4a';
    await _recorder.start(const RecordConfig(), path: path);
  }

  @override
  Future<Recording?> stop() async {
    final path = await _recorder.stop();
    return path == null
        ? null
        : Recording(path: path, createdAt: DateTime.now());
  }

  @override
  Future<List<Recording>> recordings(String lessonId) async {
    final files = (await _folder())
        .listSync()
        .whereType<File>()
        .where((f) => f.uri.pathSegments.last.startsWith('${lessonId}_'))
        .map((f) => Recording(path: f.path, createdAt: f.lastModifiedSync()))
        .toList();
    return files..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> play(Recording recording) async {
    await _player.setFilePath(recording.path);
    await _player.play();
  }

  @override
  Future<void> stopPlaying() => _player.stop();

  @override
  Future<void> delete(Recording recording) async {
    final file = File(recording.path);
    if (file.existsSync()) await file.delete();
  }
}

/// Overridden in tests with a fake.
final voiceRecorderProvider = Provider<VoiceRecorder>(
  (_) => DeviceVoiceRecorder(),
);
