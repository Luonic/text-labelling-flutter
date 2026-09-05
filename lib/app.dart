import 'package:flutter/material.dart';

import 'screens/labelling_screen.dart';
import 'session/label_session.dart';

class TextLabellingApp extends StatelessWidget {
  const TextLabellingApp({super.key, required this.session});

  final LabelSession session;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Text Labelling',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: LabellingScreen(session: session),
    );
  }
}
