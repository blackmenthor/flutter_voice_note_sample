import 'dart:async';

import 'package:another_audio_recorder/another_audio_recorder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_voice_note_sample/models/voice_note_message.dart';
import 'package:path_provider/path_provider.dart';

typedef OnRecordingUpdated = void Function(Duration);

class AudioRecordingController {

  final logKey = '[AudioRecordingController]';

  OnRecordingUpdated? _onRecordingUpdated;

  AnotherAudioRecorder? record;
  Timer? _timer;
  Duration _duration = Duration.zero;

  Duration get duration => _duration;
  bool get isRecording => record != null;

  Future<bool> get hasPermission async {
    try {
      bool hasPermission = await AnotherAudioRecorder.hasPermissions;
      if (!hasPermission) {
        throw Exception();
      }

      return true;
    } catch (ex) {
      debugPrint('$logKey hasPermission failed $ex');

      rethrow;
    }
  }

  void setOnRecordingUpdateListener(OnRecordingUpdated listener) {
    _onRecordingUpdated = listener;
  }

  Future<String> startRecord() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final recordingPath = '${directory.path}/recording_${fileName}_.wav';

      record = AnotherAudioRecorder(recordingPath, audioFormat: AudioFormat.WAV);
      await record!.initialized;

      await record!.start();

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _duration = _duration.inSeconds == 0
            ? const Duration(seconds: 1)
            : Duration(seconds: _duration.inSeconds + 1);
        _onRecordingUpdated?.call(duration);
      });

      return recordingPath;
    } catch (ex) {
      debugPrint('$logKey startRecord failed $ex');

      rethrow;
    }
  }

  Future<VoiceNoteMessage?> stopRecord({
      bool cancel = false,
  }) async {
    try {
      final result = await record!.stop();
      _timer?.cancel();
      _duration = Duration.zero;
      record = null;
      if (cancel) return null;

      final path = result?.path ?? '';
      var fileName = path.split('/').last;
      fileName = fileName.replaceAll('recording_', '');
      fileName = fileName.replaceAll('_.wav', '');
      final dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(fileName));
      final duration = result?.duration ?? Duration.zero;

      return VoiceNoteMessage(
          path: path,
          dateTime: dateTime,
          duration: duration,
      );
    } catch (ex) {
      debugPrint('$logKey stopRecord failed $ex');

      rethrow;
    }
  }

}