import 'dart:io';

import 'package:android_file_picker/android_file_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import 'android_content_path.dart';

const _jsonlExtensions = {'.jsonl', '.json'};

const _androidPickerOptions = FilePickerAndroidOptions(
  safOptions: AndroidSAFOptions(
    grant: AndroidSAFGrant.lifetime,
    accessMode: AndroidSAFAccessMode.readWrite,
    persistGrant: true,
  ),
);

/// Picks a JSONL file and returns a filesystem path that can be read, written,
/// and used to locate the sibling `images` directory.
Future<String?> pickJsonlPath() async {
  if (Platform.isAndroid) {
    return _pickOnAndroid();
  }
  return _pickWithExtensionFilter();
}

Future<String?> _pickWithExtensionFilter() async {
  final file = await FilePicker.pickFile(
    dialogTitle: 'Select JSONL file',
    type: FileType.custom,
    allowedExtensions: const ['jsonl', 'json'],
  );
  if (file == null) {
    return null;
  }
  final path = file.path;
  if (path != null && path.isNotEmpty) {
    return path;
  }
  throw StateError(
    'Could not resolve a filesystem path for ${file.name}. '
    'Pick the JSONL file from device storage so images in ./images can be loaded '
    'and flags can be written back.',
  );
}

Future<String?> _pickOnAndroid() async {
  // `.jsonl` has no MIME type in Android's map, so a custom-extension picker
  // would hide those files and only show `.json`. Allow any file, then check.
  final file = await FilePicker.pickFile(
    dialogTitle: 'Select JSONL file',
    type: FileType.any,
    androidOptions: _androidPickerOptions,
  );
  if (file == null) {
    return null;
  }
  _ensureJsonlName(file.name);

  final resolved = await resolveWritableJsonlPath(file);
  if (resolved != null) {
    return resolved;
  }

  var directory = await FilePicker.getDirectoryPath(
    dialogTitle: 'Select the folder that contains the JSONL and images/',
  );
  if (directory == null || directory.isEmpty) {
    throw StateError(
      'Could not use the picked file. Select the folder that contains '
      '${file.name} and the images directory.',
    );
  }
  if (directory.startsWith('content:')) {
    directory = filesystemPathFromContentUri(Uri.parse(directory)) ?? directory;
  }

  final inFolder = File(p.join(directory, file.name));
  if (await inFolder.exists()) {
    return inFolder.path;
  }
  final fallback = await _firstJsonlIn(directory);
  if (fallback != null) {
    return fallback;
  }
  throw StateError('No JSONL file named ${file.name} was found in $directory.');
}

Future<String?> resolveWritableJsonlPath(PlatformFile file) async {
  final candidates = <String>{};

  void add(String? path) {
    if (path != null && path.isNotEmpty) {
      candidates.add(path);
    }
  }

  add(file.path);
  if (file.uri.scheme == 'file') {
    add(file.uri.toFilePath());
  }
  add(filesystemPathFromContentUri(file.uri));
  if (file is AndroidPlatformFile) {
    add(filesystemPathFromContentUri(file.safHandle?.uri ?? file.uri));
  }

  for (final candidate in candidates) {
    if (isFilePickerCachePath(candidate)) {
      continue;
    }
    if (await File(candidate).exists()) {
      return candidate;
    }
  }

  for (final candidate in candidates) {
    if (await File(candidate).exists()) {
      return candidate;
    }
  }
  return null;
}

void _ensureJsonlName(String name) {
  final extension = p.extension(name).toLowerCase();
  if (!_jsonlExtensions.contains(extension)) {
    throw StateError('Please pick a .jsonl (or .json) file. Selected: $name');
  }
}

Future<String?> _firstJsonlIn(String directory) async {
  final dir = Directory(directory);
  if (!await dir.exists()) {
    return null;
  }
  final files = await dir
      .list()
      .where((entity) => entity is File)
      .cast<File>()
      .toList();
  for (final file in files) {
    if (_jsonlExtensions.contains(p.extension(file.path).toLowerCase())) {
      return file.path;
    }
  }
  return null;
}
