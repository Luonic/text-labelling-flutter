import 'dart:io';

import 'package:android_file_picker/android_file_picker.dart';
import 'package:file_picker/file_picker.dart';

import 'android_content_path.dart';
import 'dataset_location.dart';

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
  if (Platform.isIOS || Platform.isMacOS) {
    return _pickOnDarwin();
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

Future<String?> _pickOnDarwin() async {
  // iOS file picks are copied into tmp, which cannot see ./images or rewrite
  // the original JSONL. Ask for the dataset folder instead.
  if (Platform.isIOS) {
    return _pickDatasetDirectory(
      title: 'Select the folder that contains the JSONL and images/',
    );
  }
  return _pickOnMacOS();
}

Future<String?> _pickOnMacOS() async {
  final file = await FilePicker.pickFile(
    dialogTitle: 'Select JSONL file',
    type: FileType.custom,
    allowedExtensions: const ['jsonl', 'json'],
  );
  if (file == null) {
    return null;
  }
  _ensureJsonlName(file.name);

  final path = file.path;
  if (path != null && path.isNotEmpty && await canUseLabellingDataset(path)) {
    return path;
  }

  return _pickDatasetDirectory(
    title: 'Select the folder that contains the JSONL and images/',
    preferredName: file.name,
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

  return _pickDatasetDirectory(
    title: 'Select the folder that contains the JSONL and images/',
    preferredName: file.name,
    androidUriMapper: filesystemPathFromContentUri,
  );
}

Future<String?> _pickDatasetDirectory({
  required String title,
  String? preferredName,
  String? Function(Uri uri)? androidUriMapper,
}) async {
  var directory = await FilePicker.getDirectoryPath(dialogTitle: title);
  if (directory == null || directory.isEmpty) {
    if (preferredName == null) {
      return null;
    }
    throw StateError(
      'Could not use the picked file. Select the folder that contains '
      '$preferredName and the images directory.',
    );
  }
  if (directory.startsWith('content:') && androidUriMapper != null) {
    directory = androidUriMapper(Uri.parse(directory)) ?? directory;
  }

  final found = await findJsonlInDirectory(
    directory,
    preferredName: preferredName,
  );
  if (found != null) {
    return found;
  }
  throw StateError(
    preferredName == null
        ? 'No JSONL file was found in $directory.'
        : 'No JSONL file named $preferredName was found in $directory.',
  );
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
    if (isFilePickerCachePath(candidate) || isEphemeralPickerPath(candidate)) {
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
  if (!isJsonlFileName(name)) {
    throw StateError('Please pick a .jsonl (or .json) file. Selected: $name');
  }
}
