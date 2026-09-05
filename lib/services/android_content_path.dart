/// Resolves an Android Storage Access Framework URI to a local filesystem path.
///
/// Returns null when the URI cannot be mapped (for example a cloud provider).
String? filesystemPathFromContentUri(Uri uri) {
  if (uri.scheme == 'file') {
    return uri.toFilePath();
  }
  if (uri.scheme != 'content') {
    return null;
  }

  switch (uri.authority) {
    case 'com.android.externalstorage.documents':
      return _fromExternalStorageDocument(uri);
    case 'com.android.providers.downloads.documents':
      return _fromDownloadsDocument(uri);
    default:
      return null;
  }
}

bool isFilePickerCachePath(String path) {
  return path.contains('/cache/file_picker/') ||
      path.contains('/code_cache/file_picker/');
}

String? _fromExternalStorageDocument(Uri uri) {
  final decoded = Uri.decodeFull(uri.path);
  String? docId;
  if (decoded.contains('/document/')) {
    docId = decoded.split('/document/').last;
  } else if (decoded.contains('/tree/')) {
    docId = decoded.split('/tree/').last;
  }
  if (docId == null || docId.isEmpty) {
    return null;
  }
  final colon = docId.indexOf(':');
  if (colon < 0) {
    return null;
  }
  final volume = docId.substring(0, colon);
  final relative = docId.substring(colon + 1);
  if (relative.isEmpty) {
    return volume.toLowerCase() == 'primary'
        ? '/storage/emulated/0'
        : '/storage/$volume';
  }
  if (volume.toLowerCase() == 'primary') {
    return '/storage/emulated/0/$relative';
  }
  return '/storage/$volume/$relative';
}

String? _fromDownloadsDocument(Uri uri) {
  final decoded = Uri.decodeFull(uri.path);
  const marker = '/document/';
  final markerIndex = decoded.indexOf(marker);
  if (markerIndex < 0) {
    return null;
  }
  final docId = decoded.substring(markerIndex + marker.length);
  if (docId.startsWith('raw:')) {
    return docId.substring(4);
  }
  return null;
}
