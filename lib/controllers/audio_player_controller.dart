import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioPlayerController {
  AudioPlayerController() {
    onPlayerStopped.listen((event) {
      _currentlyPlaying = '';
    });
  }

  final logKey = '[AudioPlayerController]';

  late final AudioPlayer player = AudioPlayer();

  String _currentlyPlaying = '';

  String get currentlyPlaying => _currentlyPlaying;

  Stream<PlayerState> get onPlayerStopped =>
      player.onPlayerStateChanged.where((event) =>
          event == PlayerState.stopped || event == PlayerState.completed);

  Future<void> play(String path) async {
    try {
      await player.play(
        DeviceFileSource(
          path,
        ),
      );
      _currentlyPlaying = path;
    } catch (ex) {
      debugPrint('$logKey play failed: $ex');

      rethrow;
    }
  }

  Future<void> stop() async {
    try {
      await player.stop();
      _currentlyPlaying = '';
    } catch (ex) {
      debugPrint('$logKey play failed: $ex');

      rethrow;
    }
  }
}
