import 'dart:async';

import 'package:another_audio_recorder/another_audio_recorder.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_voice_note_sample/extensions.dart';
import 'package:path_provider/path_provider.dart';

enum VoiceNoteState {
  idle,
  recording,
  sending,
  sent;
}

class VoiceNoteMessage {
  VoiceNoteMessage({
      required this.path,
      required this.dateTime,
      required this.duration,
  });

  final String path;
  final DateTime dateTime;
  final Duration duration;
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
  AnotherAudioRecorder? record;

  Timer? _recordingTimer;
  Duration? _recordingDuration;
  VoiceNoteState _state = VoiceNoteState.idle;
  late String _recordingPath;
  dynamic _recordError;

  late final AudioPlayer player;
  List<VoiceNoteMessage> recordings = [];
  String currentlyPlaying = '';

  /// TODO: DOCS
  Offset? _initialTapdown;
  /// TODO: DOCS
  bool isPressed = false;
  /// TODO: DOCS
  bool recordingLocked = false;
  /// TODO: DOCS
  double deltaX = 0;
  /// TODO: DOCS
  double deltaY = 0;
  /// TODO: DOCS
  final lockThreshold = 90.0;
  /// TODO: DOCS
  final cancelThreshold = 120.0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      initAudioRecorder();
      initAudioPlayer();
    });
  }

  void initAudioPlayer() {
    player = AudioPlayer();

    player.onPlayerStateChanged.listen((event) {
      if (event == PlayerState.stopped || event == PlayerState.completed) {
        currentlyPlaying = '';
        setState(() {});
      }
    });
  }

  void initAudioRecorder() async {
    try {
      bool hasPermission = await AnotherAudioRecorder.hasPermissions;
      if (!hasPermission) {
        throw Exception();
      }
    } catch (ex) {
      _recordError = ex;
    }
    setState(() {});
  }

  void _startRecordingTimer() {
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration = _recordingDuration == null
            ? const Duration(seconds: 1)
            : Duration(seconds: _recordingDuration!.inSeconds + 1);
      });
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();

    _recordingDuration = null;
    setState(() {});
  }

  void _startRecording() async {
    try {
      print('start recording!');
      if (record != null) return;
      final directory = await getApplicationDocumentsDirectory();
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      _recordingPath = '${directory.path}/recording_${fileName}_.wav';

      record = AnotherAudioRecorder(_recordingPath, audioFormat: AudioFormat.WAV);
      await record!.initialized;

      await record!.start();
      _startRecordingTimer();
      setState(() {});
    } catch (ex) {
      print(ex.toString());
      _stopRecording();
    }
  }

  void _stopRecording([bool cancel = false]) async {
    try {
      if (_state != VoiceNoteState.recording) return;
      final result = await record!.stop();
      _stopRecordingTimer();
      setState(() {
        record = null;
      });
      if (cancel) return;

      final path = result?.path ?? '';
      final duration = result?.duration ?? Duration.zero;
      _sendRecording(path, duration);
    } catch (ex) {
      print(ex.toString());
    }
  }

  void _sendRecording(String path, Duration duration) async {
    var fileName = path.split('/').last;
    fileName = fileName.replaceAll('recording_', '');
    fileName = fileName.replaceAll('_.wav', '');
    final dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(fileName));

    setState(() {
      recordings.add(
        VoiceNoteMessage(
            path: path,
            dateTime: dateTime,
            duration: duration,
        ),
      );
    });
  }

  Widget _recordSection({
    required BuildContext context,
    required Widget child,
  }) {
    return Stack(
      children: [
        if (isPressed) ...[
          Transform.translate(
            offset: const Offset(4, -96),
            child: Icon(
              Icons.lock,
              size: 32,
              color: recordingLocked ? context.theme.colorScheme.primary : null,
            ),
          ),
        ],
        Listener(
          onPointerDown: (event) {
            setState(() {
              isPressed = true;
              _initialTapdown = event.position;
              _state = VoiceNoteState.recording;
            });
            _startRecording();
          },
          onPointerMove: (event) {
            if (recordingLocked) return;
            if (_initialTapdown != null) {
              final currentDx = event.position.dx;
              final _deltaX = _initialTapdown!.dx - currentDx;
              const xThreshold = 5;

              final currentDy = event.position.dy;
              final _deltaY = _initialTapdown!.dy - currentDy;

              // TODO: add description of what we check here
              if (deltaY > 0 || (_deltaX.abs() < xThreshold
                  && _deltaY > 0)) {
                if (_deltaY >= lockThreshold) {
                  setState(() {
                    isPressed = false;
                    recordingLocked = true;
                    deltaX = 0;
                    deltaY = 0;
                  });
                } else {
                  setState(() {
                    deltaX = 0;
                    deltaY = _deltaY;
                  });
                }
              } else if (_deltaX > 0) {
                // TODO: add description of what we check here
                if (_deltaX >= cancelThreshold) {
                  _stopRecording(true);
                  setState(() {
                    deltaX = 0;
                    deltaY = 0;
                    isPressed = false;
                    _state = VoiceNoteState.idle;
                  });
                  return;
                }
                setState(() {
                  deltaX = _deltaX;
                  deltaY = 0;
                });
              }
            }
          },
          onPointerUp: (e) {
            if (recordingLocked) {
              return;
            }
            _stopRecording();
            setState(() {
              deltaX = 0;
              isPressed = false;
              _state = VoiceNoteState.idle;
            });
          },
          behavior: HitTestBehavior.translucent,
          child: child,
        ),
      ],
    );
  }

  Widget _startRecordIconWidget(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: context.theme.colorScheme.primary,
          width: 2.0,
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Icon(
          Icons.mic,
          size: 18,
          color: context.theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _recordingIconWidget(BuildContext context) {
    return Transform.translate(
      offset: Offset(deltaX * -1, deltaY * -1),
      child: InkWell(
        onTap: () {
          _stopRecording();
          setState(() {
            _state = VoiceNoteState.idle;
            isPressed = false;
            recordingLocked = false;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: context.theme.colorScheme.primary,
              width: 2.0,
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.stop,
            color: context.theme.colorScheme.error,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _iconWidget(BuildContext context) {
    switch (_state) {
      case VoiceNoteState.idle:
        return _startRecordIconWidget(context);
      case VoiceNoteState.recording:
        return _recordingIconWidget(context);
      default:
        return _startRecordIconWidget(context);
    }
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
              child: ListView.builder(
                  itemCount: recordings.length,
                  itemBuilder: (context, idx) {
                    final item = recordings[idx];
                    final isPlaying = currentlyPlaying.isNotEmpty 
                        && item.path == currentlyPlaying;

                    return ListTile(
                      onTap: () {
                        if (isPlaying) {
                          // stop
                          player.stop();
                          setState(() {
                            currentlyPlaying = '';
                          });
                        } else {
                          // play
                          player.play(DeviceFileSource(item.path));
                          setState(() {
                            currentlyPlaying = item.path;
                          });
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
                        item.duration.inSeconds.toString(),
                      ),
                    );
                  },
              ),
            ),
            Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black26,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_state == VoiceNoteState.recording) ...[
                    const Icon(
                      Icons.mic,
                      size: 24,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8,),
                    if (_recordingDuration != null) ...[
                      Text(
                        // TODO: CHANGE WITH ACTUAL DURATION
                        _recordingDuration!.inSeconds.toString(),
                      ),
                    ],
                  ],
                  if (isPressed) ...[
                    const SizedBox(width: 8,),
                    const Text(
                      'Slide left to cancel',
                    ),
                  ],
                  if (_state == VoiceNoteState.recording) ...[
                    const Spacer(),
                  ],
                  _recordSection(
                    context: context,
                    child: _iconWidget(context),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
