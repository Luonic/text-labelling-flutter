import 'package:flutter_test/flutter_test.dart';
import 'package:text_labelling_flutter/models/label_record.dart';
import 'package:text_labelling_flutter/services/jsonl_codec.dart';

void main() {
  test('parses jsonl records and preserves extra fields', () {
    const contents = '''
{"images":["a.jpg","b.mp4"],"title":"One","description":"First","flags":["nudes_trade"],"id":42}
{"images":[],"title":"Two","description":"Second"}
''';
    final records = parseJsonl(contents);
    expect(records, hasLength(2));
    expect(records[0].images, ['a.jpg', 'b.mp4']);
    expect(records[0].title, 'One');
    expect(records[0].selectedFlags, {'nudes_trade'});
    expect(records[0].extras['id'], 42);
    expect(records[1].selectedFlags, isEmpty);
  });

  test('serializes selected flags and extra fields', () {
    final record = LabelRecord(
      images: const ['x.png'],
      title: 'Title',
      description: 'Body',
      selectedFlags: {'prostitution', 'nudes_trade'},
      extras: const {'source': 'export'},
    );
    final encoded = serializeJsonl([record]);
    final roundTrip = parseJsonl(encoded).single;
    expect(roundTrip.images, ['x.png']);
    expect(roundTrip.selectedFlags, {'nudes_trade', 'prostitution'});
    expect(roundTrip.extras['source'], 'export');
  });

  test('reports invalid json with a 1-based line number', () {
    expect(
      () => parseJsonl('{"title":"ok"}\n{bad}\n'),
      throwsA(
        isA<JsonlParseException>().having(
          (error) => error.lineNumber,
          'lineNumber',
          2,
        ),
      ),
    );
  });

  test('skips blank lines', () {
    final records = parseJsonl(
      '\n{"title":"A","description":"B","images":[]}\n\n',
    );
    expect(records, hasLength(1));
    expect(records.single.title, 'A');
  });
}
