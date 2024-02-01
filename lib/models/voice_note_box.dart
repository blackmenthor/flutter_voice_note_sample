import 'package:flutter/material.dart';
import 'package:flutter_voice_note_sample/controllers/audio_recording_controller.dart';
import 'package:flutter_voice_note_sample/utils/extensions.dart';
import 'package:flutter_voice_note_sample/voice_note_page/page.dart';

class VoiceNoteBox extends StatefulWidget {
  const VoiceNoteBox({
    Key? key,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.recordingController,
  }) : super(key: key);

  final VoidCallback onStartRecording;
  final void Function(bool) onStopRecording;
  final AudioRecordingController recordingController;

  @override
  State<VoiceNoteBox> createState() => _VoiceNoteBoxState();
}

class _VoiceNoteBoxState extends State<VoiceNoteBox> {

  VoiceNoteState _state = VoiceNoteState.idle;

  bool get isPressed => _initialTapdown != null;

  /// first touch (tap down) on the record indicator. Saved the offset
  /// (e.g. X and Y axis)
  Offset? _initialTapdown;

  /// a Flag whether the recording is locked or not (e.g. recording is dragged
  /// to the lock icon)
  bool recordingLocked = false;

  /// deltaX (difference between first mic icon position vs the dragged position)
  /// on X axis
  double deltaX = 0;

  /// deltaY (difference between first mic icon position vs the dragged position)
  /// on Y axis
  double deltaY = 0;

  /// The threshold on how many pixels needed to be dragged on Y axis
  /// in order to lock the recording.
  final lockThreshold = 90.0;

  /// The threshold on how many pixels needed to be dragged on X axis
  /// in order to cancel the recording.
  final cancelThreshold = 120.0;

  void onPointerMove(PointerMoveEvent event) {
    final currentDx = event.position.dx;
    final _deltaX = _initialTapdown!.dx - currentDx;
    const xThreshold = 5;

    final currentDy = event.position.dy;
    final _deltaY = _initialTapdown!.dy - currentDy;

    // move the indicator vertically (up), if there's not enough
    // movement on X axis
    if (deltaY > 0 || (_deltaX.abs() < xThreshold
        && _deltaY > 0)) {
      // if movement is >= lockThreshold, stop the movement and
      // lock the recording
      if (_deltaY >= lockThreshold) {
        setState(() {
          _initialTapdown = null;
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
      // if movement on X axis >= cancelThreshold, stop the movement
      // and cancel the recording.
      if (_deltaX >= cancelThreshold) {
        widget.onStopRecording(true);
        setState(() {
          deltaX = 0;
          deltaY = 0;
          _initialTapdown = null;
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
              _initialTapdown = event.position;
              _state = VoiceNoteState.recording;
            });
            widget.onStartRecording();
          },
          onPointerMove: (event) {
            if (recordingLocked) return;
            if (_initialTapdown != null) {
              onPointerMove(event);
            }
          },
          onPointerUp: (e) {
            if (recordingLocked) {
              return;
            }
            if (_state == VoiceNoteState.recording) {
              widget.onStopRecording(false);
            }
            setState(() {
              deltaX = 0;
              _initialTapdown = null;
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
          if (_state == VoiceNoteState.recording) {
            widget.onStopRecording(false);
          }
          setState(() {
            _state = VoiceNoteState.idle;
            _initialTapdown = null;
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
    return Container(
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
            if (widget.recordingController.isRecording) ...[
              Text(
                '${widget.recordingController.duration.inSeconds} sec',
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
    );
  }
}
