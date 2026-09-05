import 'dart:io';

import 'package:path/path.dart' as p;

const jsonlExtensions = {'.jsonl', '.json'};

/// True when [path] is a picker cache/temp copy rather than the original file.
///
/// Writing flags back, or resolving a sibling `images` directory, only works
/// against the real dataset location.
bool isEphemeralPickerPath(String path) {
  final normalized = path.replaceAll('\\', '/');
  final lower = normalized.toLowerCase();
  if (lower.contains('/cache/file_picker/') ||
      lower.contains('/code_cache/file_picker/') ||
      lower.contains('/temporaryitems/')) {
    return true;
  }
  // iOS copies the picked file into NSTemporaryDirectory (.../tmp/<name>).
  // macOS system temp lives under /var/folders/.../T/.
  final parent = p.basename(p.dirname(normalized)).toLowerCase();
  if (parent == 'tmp') {
    return true;
  }
  return lower.contains('/var/folders/');
}

bool isJsonlFileName(String name) {
  return jsonlExtensions.contains(p.extension(name).toLowerCase());
}

/// Finds a JSONL file in [directory], or in the parent when the user picked
/// the `images` folder by mistake.
Future<String?> findJsonlInDirectory(
  String directory, {
  String? preferredName,
}) async {
  if (preferredName != null && preferredName.isNotEmpty) {
    final named = File(p.join(directory, preferredName));
    if (await named.exists()) {
      return named.path;
    }
  }

  final found = await _firstJsonlIn(directory);
  if (found != null) {
    return found;
  }

  if (p.basename(directory).toLowerCase() == 'images') {
    return findJsonlInDirectory(
      p.dirname(directory),
      preferredName: preferredName,
    );
  }
  return null;
}

/// Whether [jsonlPath] can be rewritten and its sibling `images` folder listed.
///
/// A missing `images` folder is allowed (records may have no media). An
/// unreadable folder is not, because that is the usual sandbox/SAF failure.
Future<bool> canUseLabellingDataset(String jsonlPath) async {
  if (isEphemeralPickerPath(jsonlPath)) {
    return false;
  }
  final file = File(jsonlPath);
  if (!await file.exists()) {
    return false;
  }
  try {
    final handle = await file.open(mode: FileMode.append);
    await handle.close();
  } on FileSystemException {
    return false;
  }

  final images = Directory(p.join(p.dirname(jsonlPath), 'images'));
  if (!await images.exists()) {
    return true;
  }
  try {
    await images.list().toList();
    return true;
  } on FileSystemException {
    return false;
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
    if (isJsonlFileName(file.path)) {
      return file.path;
    }
  }
  return null;
}
