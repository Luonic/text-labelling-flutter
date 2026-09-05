import 'dart:io';

import '../models/label_record.dart';
import 'jsonl_codec.dart';

abstract class JsonlRepository {
  Future<List<LabelRecord>> read(String path);

  Future<void> write(String path, List<LabelRecord> records);
}

class FileJsonlRepository implements JsonlRepository {
  const FileJsonlRepository();

  @override
  Future<List<LabelRecord>> read(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw FileSystemException('JSONL file not found', path);
    }
    return parseJsonl(await file.readAsString());
  }

  @override
  Future<void> write(String path, List<LabelRecord> records) async {
    final file = File(path);
    await file.writeAsString(serializeJsonl(records), flush: true);
  }
}

class MemoryJsonlRepository implements JsonlRepository {
  MemoryJsonlRepository([Map<String, String>? files]) : files = files ?? {};

  final Map<String, String> files;

  @override
  Future<List<LabelRecord>> read(String path) async {
    final contents = files[path];
    if (contents == null) {
      throw FileSystemException('JSONL file not found', path);
    }
    return parseJsonl(contents);
  }

  @override
  Future<void> write(String path, List<LabelRecord> records) async {
    files[path] = serializeJsonl(records);
  }
}
