import 'dart:convert';

import '../models/label_record.dart';

class JsonlParseException implements Exception {
  JsonlParseException(this.lineNumber, this.message);

  final int lineNumber;
  final String message;

  @override
  String toString() => 'JSONL error on line $lineNumber: $message';
}

List<LabelRecord> parseJsonl(String contents) {
  final records = <LabelRecord>[];
  final lines = const LineSplitter().convert(contents);
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) {
      continue;
    }
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map) {
        throw FormatException(
          'expected a JSON object, got ${decoded.runtimeType}',
        );
      }
      records.add(LabelRecord.fromJson(Map<String, dynamic>.from(decoded)));
    } on FormatException catch (error) {
      throw JsonlParseException(i + 1, error.message);
    } catch (error) {
      throw JsonlParseException(i + 1, error.toString());
    }
  }
  return records;
}

String serializeJsonl(List<LabelRecord> records) {
  if (records.isEmpty) {
    return '';
  }
  final buffer = StringBuffer();
  for (final record in records) {
    buffer.writeln(jsonEncode(record.toJson()));
  }
  return buffer.toString();
}
