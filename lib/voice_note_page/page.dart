import 'package:flutter/material.dart';
import 'package:flutter_voice_note_sample/controllers/audio_player_controller.dart';
import 'package:flutter_voice_note_sample/controllers/audio_recording_controller.dart';
import 'package:flutter_voice_note_sample/models/voice_note_box.dart';
import 'package:flutter_voice_note_sample/models/voice_note_list.dart';
import 'package:flutter_voice_note_sample/models/voice_note_message.dart';

enum VoiceNoteState {
  idle,
  recording,
  sending,
  sent;
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  AudioRecordingController recordingController = AudioRecordingController();
  AudioPlayerController playerController = AudioPlayerController();

  List<VoiceNoteMessage> recordings = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      init();
    });
  }

  void init() async {
    initAudioRecorder();
    initAudioPlayer();
  }

  void initAudioRecorder() async {
    try {
      final hasPermission = await recordingController.hasPermission;
      if (!hasPermission) {
        throw Exception();
      }

      recordingController.setOnRecordingUpdateListener((_) {
        setState(() {});
      });
    } catch (ex) {
      debugPrint(ex.toString());
    }
    setState(() {});
  }

  void initAudioPlayer() {
    playerController.onPlayerStopped.listen((event) {
      setState(() {});
    });
  }

  void _startRecording() async {
    try {
      if (recordingController.isRecording) return;

      await recordingController.startRecord();
      setState(() {});
    } catch (ex) {
      debugPrint(ex.toString());
      _stopRecording();
    }
  }

  void _stopRecording([bool cancel = false]) async {
    try {
      final result = await recordingController.stopRecord(cancel: cancel,);
      if (result != null) {
        _sendRecording(result);
      }
    } catch (ex) {
      debugPrint(ex.toString());
    }
  }

  void _sendRecording(VoiceNoteMessage voiceNoteMessage) async {
    setState(() {
      recordings.add(voiceNoteMessage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 16.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: VoiceNoteList(
                player: playerController,
                recordings: recordings,
                onSetState: () {
                  setState(() {});
                },
              ),
            ),
            VoiceNoteBox(
              onStartRecording: () => _startRecording(),
              onStopRecording: (val) => _stopRecording(val),
              recordingController: recordingController,
            ),
          ],
        ),
      ),
    );
  }
}
