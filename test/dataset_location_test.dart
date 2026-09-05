import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:text_labelling_flutter/services/dataset_location.dart';

void main() {
  test('detects picker temp and cache copies', () {
    expect(
      isEphemeralPickerPath(
        '/var/mobile/Containers/Data/Application/ABCD/tmp/sample.jsonl',
      ),
      isTrue,
    );
    expect(
      isEphemeralPickerPath('/var/folders/xx/yyyy/T/sample.jsonl'),
      isTrue,
    );
    expect(
      isEphemeralPickerPath(
        '/data/user/0/com.luonic.text_labelling_flutter/cache/file_picker/1/sample.jsonl',
      ),
      isTrue,
    );
    expect(isEphemeralPickerPath('/Users/me/Downloads/sample.jsonl'), isFalse);
  });

  test('finds jsonl in a dataset folder or its images parent', () async {
    final root = await Directory.systemTemp.createTemp('dataset-location-');
    addTearDown(() => root.delete(recursive: true));

    final jsonl = File(p.join(root.path, 'sample.jsonl'));
    await jsonl.writeAsString('{"images":[],"title":"t","description":""}\n');
    final images = Directory(p.join(root.path, 'images'));
    await images.create();
    await File(p.join(images.path, 'a.jpg')).writeAsString('x');

    expect(await findJsonlInDirectory(root.path), jsonl.path);
    expect(
      await findJsonlInDirectory(images.path, preferredName: 'sample.jsonl'),
      jsonl.path,
    );
    expect(await canUseLabellingDataset(jsonl.path), isTrue);
  });

  test('rejects ephemeral paths even when the file exists', () async {
    final root = await Directory.systemTemp.createTemp('ephemeral-jsonl-');
    addTearDown(() => root.delete(recursive: true));
    final tmp = Directory(p.join(root.path, 'tmp'));
    await tmp.create();
    final file = File(p.join(tmp.path, 'sample.jsonl'));
    await file.writeAsString('{}\n');

    expect(isEphemeralPickerPath(file.path), isTrue);
    expect(await canUseLabellingDataset(file.path), isFalse);
  });
}
