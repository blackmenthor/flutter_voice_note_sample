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