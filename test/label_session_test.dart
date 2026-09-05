import 'package:flutter_test/flutter_test.dart';
import 'package:text_labelling_flutter/services/flags_repository.dart';
import 'package:text_labelling_flutter/services/jsonl_repository.dart';
import 'package:text_labelling_flutter/session/label_session.dart';

void main() {
  LabelSession buildSession(MemoryJsonlRepository jsonl) {
    return LabelSession(
      flagsRepository: MemoryFlagsRepository(const [
        'nudes_trade',
        'prostitution',
        'underwear_trade',
      ]),
      jsonlRepository: jsonl,
      pickPath: () async => 'session.jsonl',
      requestPermissions: () async {},
    );
  }

  test(
    'loads jsonl, toggles flags, and rewrites the file on page change',
    () async {
      final jsonl = MemoryJsonlRepository({
        'session.jsonl':
            '{"images":["a.png"],"title":"One","description":"First"}\n'
            '{"images":["b.png"],"title":"Two","description":"Second"}\n',
      });
      final session = buildSession(jsonl);
      await session.loadFlagCatalog();
      await session.pickAndOpen();

      expect(session.records, hasLength(2));
      expect(session.progressLabel, '1 / 2');
      expect(session.imagesDir, 'images');

      session.toggleFlag('nudes_trade');
      expect(session.currentRecord!.selectedFlags, {'nudes_trade'});
      expect(session.dirty, isTrue);

      await session.onPageChanged(1);
      expect(session.currentIndex, 1);
      expect(session.dirty, isFalse);
      expect(jsonl.files['session.jsonl'], contains('"nudes_trade"'));
      expect(jsonl.files['session.jsonl'], contains('"title":"Two"'));
    },
  );

  test('keeps unknown selected flags visible', () async {
    final jsonl = MemoryJsonlRepository({
      'session.jsonl': '{"images":[],"title":"One","description":"","flags":["custom_flag"]}\n',
    });
    final session = buildSession(jsonl);
    await session.loadFlagCatalog();
    await session.openPath('session.jsonl');
    expect(session.visibleFlags, contains('custom_flag'));
  });
}
