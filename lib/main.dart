import 'package:flutter/material.dart';

import 'app.dart';
import 'session/label_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = LabelSession();
  await session.loadFlagCatalog();
  runApp(TextLabellingApp(session: session));
}
