import 'package:flutter/material.dart';
import 'package:flutter_voice_note_sample/utils/constants.dart';
import 'package:flutter_voice_note_sample/voice_note_page/page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Constants.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(
          title: Constants.appName,
      ),
    );
  }
}