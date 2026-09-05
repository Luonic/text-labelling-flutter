import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

Future<void> requestStoragePermissions() async {
  if (!Platform.isAndroid) {
    return;
  }

  await Permission.storage.request();
  await Permission.photos.request();
  await Permission.videos.request();
  final manageStatus = await Permission.manageExternalStorage.status;
  if (!manageStatus.isGranted) {
    await Permission.manageExternalStorage.request();
  }
}
