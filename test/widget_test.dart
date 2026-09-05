import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_labelling_flutter/app.dart';
import 'package:text_labelling_flutter/services/flags_repository.dart';
import 'package:text_labelling_flutter/services/jsonl_repository.dart';
import 'package:text_labelling_flutter/session/label_session.dart';

void main() {
  testWidgets('shows empty state before a file is opened', (tester) async {
    final session = LabelSession(
      flagsRepository: MemoryFlagsRepository(const [
        'nudes_trade',
        'prostitution',
        'underwear_trade',
      ]),
      jsonlRepository: MemoryJsonlRepository(),
      pickPath: () async => null,
      requestPermissions: () async {},
    );
    await session.loadFlagCatalog();
    await tester.pumpWidget(TextLabellingApp(session: session));

    expect(find.text('Open JSONL'), findsOneWidget);
    expect(find.text('Open a JSONL file to start labelling'), findsOneWidget);
  });

  testWidgets('renders a record and selects a flag', (tester) async {
    final jsonl = MemoryJsonlRepository({
      'records.jsonl':
          '{"images":[],"title":"Listing title","description":"Listing body"}\n'
          '{"images":[],"title":"Second title","description":"Second body"}\n',
    });
    final session = LabelSession(
      flagsRepository: MemoryFlagsRepository(const [
        'nudes_trade',
        'prostitution',
        'underwear_trade',
      ]),
      jsonlRepository: jsonl,
      pickPath: () async => 'records.jsonl',
      requestPermissions: () async {},
    );
    await session.loadFlagCatalog();
    await tester.pumpWidget(TextLabellingApp(session: session));

    await tester.tap(find.byKey(const Key('open-jsonl-button')));
    await tester.pumpAndSettle();

    expect(find.text('Listing title'), findsOneWidget);
    expect(find.text('Listing body'), findsOneWidget);
    expect(find.text('nudes_trade'), findsOneWidget);

    await tester.tap(find.byKey(const Key('flag-nudes_trade')));
    await tester.pump();
    expect(session.currentRecord!.selectedFlags, {'nudes_trade'});

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('flag-nudes_trade')),
    );
    expect(button.style?.backgroundColor?.resolve({}), Colors.redAccent);
  });

  testWidgets('saves flags when swiping to the next page', (tester) async {
    final jsonl = MemoryJsonlRepository({
      'records.jsonl':
          '{"images":[],"title":"First listing","description":"A"}\n'
          '{"images":[],"title":"Second listing","description":"B"}\n',
    });
    final session = LabelSession(
      flagsRepository: MemoryFlagsRepository(const [
        'nudes_trade',
        'prostitution',
        'underwear_trade',
      ]),
      jsonlRepository: jsonl,
      pickPath: () async => 'records.jsonl',
      requestPermissions: () async {},
    );
    await session.loadFlagCatalog();
    await tester.pumpWidget(TextLabellingApp(session: session));
    await tester.tap(find.byKey(const Key('open-jsonl-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('flag-prostitution')));
    await tester.pump();

    await tester.fling(find.byType(PageView), const Offset(-600, 0), 1200);
    await tester.pumpAndSettle();

    expect(find.text('Second listing'), findsOneWidget);
    expect(jsonl.files['records.jsonl'], contains('"prostitution"'));
  });
}
