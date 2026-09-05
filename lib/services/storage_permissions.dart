import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Requests the Android storage access this app needs to read `./images`
/// and rewrite the original JSONL file.
///
/// Returns true when all-files access is granted (Android 11+) or when the
/// legacy storage permission is granted on older versions.
Future<bool> requestStoragePermissions() async {
  if (!Platform.isAndroid) {
    return true;
  }

  await Permission.storage.request();
  await Permission.photos.request();
  await Permission.videos.request();

  var manage = await Permission.manageExternalStorage.status;
  if (manage.isGranted) {
    return true;
  }
  manage = await Permission.manageExternalStorage.request();
  if (manage.isGranted) {
    return true;
  }

  // Older devices only have READ/WRITE_EXTERNAL_STORAGE.
  final storage = await Permission.storage.status;
  return storage.isGranted;
}

Future<bool> hasAllFilesAccess() async {
  if (!Platform.isAndroid) {
    return true;
  }
  if (await Permission.manageExternalStorage.isGranted) {
    return true;
  }
  return Permission.storage.isGranted;
}
