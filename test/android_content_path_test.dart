import 'package:flutter_test/flutter_test.dart';
import 'package:text_labelling_flutter/services/android_content_path.dart';

void main() {
  test('maps primary storage document URIs to /storage/emulated/0', () {
    final uri = Uri.parse(
      'content://com.android.externalstorage.documents/document/primary%3ADownload%2Fsample.jsonl',
    );
    expect(
      filesystemPathFromContentUri(uri),
      '/storage/emulated/0/Download/sample.jsonl',
    );
  });

  test('maps tree URIs for a dataset folder', () {
    final uri = Uri.parse(
      'content://com.android.externalstorage.documents/tree/primary%3ALabelData',
    );
    expect(filesystemPathFromContentUri(uri), '/storage/emulated/0/LabelData');
  });

  test('maps tree/document URIs to the document path', () {
    final uri = Uri.parse(
      'content://com.android.externalstorage.documents/tree/primary%3ADownload/document/primary%3ADownload%2Fsample.jsonl',
    );
    expect(
      filesystemPathFromContentUri(uri),
      '/storage/emulated/0/Download/sample.jsonl',
    );
  });

  test('maps secondary volume document URIs', () {
    final uri = Uri.parse(
      'content://com.android.externalstorage.documents/document/1234-5678%3APictures%2Fa.jpg',
    );
    expect(
      filesystemPathFromContentUri(uri),
      '/storage/1234-5678/Pictures/a.jpg',
    );
  });

  test('maps downloads provider raw paths', () {
    final uri = Uri.parse(
      'content://com.android.providers.downloads.documents/document/raw%3A%2Fstorage%2Femulated%2F0%2FDownload%2Fsample.jsonl',
    );
    expect(
      filesystemPathFromContentUri(uri),
      '/storage/emulated/0/Download/sample.jsonl',
    );
  });

  test('detects file_picker cache copies', () {
    expect(
      isFilePickerCachePath(
        '/data/user/0/com.luonic.text_labelling_flutter/cache/file_picker/1/sample.jsonl',
      ),
      isTrue,
    );
    expect(
      isFilePickerCachePath('/storage/emulated/0/Download/sample.jsonl'),
      isFalse,
    );
  });
}
