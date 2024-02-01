import 'package:flutter/material.dart';
import 'package:flutter_voice_note_sample/controllers/audio_player_controller.dart';
import 'package:flutter_voice_note_sample/models/voice_note_message.dart';

class VoiceNoteList extends StatelessWidget {
  const VoiceNoteList({
    Key? key,
    required this.recordings,
    required this.player,
    required this.onSetState,
  }) : super(key: key);

  final List<VoiceNoteMessage> recordings;
  final AudioPlayerController player;
  final VoidCallback onSetState;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: recordings.length,
      itemBuilder: (context, idx) {
        final item = recordings[idx];
        final isPlaying = player.currentlyPlaying.isNotEmpty
            && item.path == player.currentlyPlaying;

        return ListTile(
          onTap: () async {
            if (isPlaying) {
              // stop
              await player.stop();
              onSetState();
            } else {
              // play
              await player.play(item.path);
              onSetState();
            }
          },
          leading: Icon(
            isPlaying
                ? Icons.stop
                : Icons.play_arrow,
          ),
          title: Text(
            item.dateTime.toIso8601String(),
          ),
          subtitle: Text(
            '${item.duration.inSeconds} sec',
          ),
        );
      },
    );
  }
}
