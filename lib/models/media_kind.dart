import 'package:path/path.dart' as p;

enum MediaKind { image, video, unknown }

const imageExtensions = {
  '.jpg',
  '.jpeg',
  '.png',
  '.gif',
  '.webp',
  '.bmp',
  '.heic',
  '.heif',
};

const videoExtensions = {'.mp4', '.mov', '.webm', '.mkv', '.avi', '.m4v'};

MediaKind mediaKindForName(String name) {
  final extension = p.extension(name).toLowerCase();
  if (imageExtensions.contains(extension)) {
    return MediaKind.image;
  }
  if (videoExtensions.contains(extension)) {
    return MediaKind.video;
  }
  return MediaKind.unknown;
}

String resolveMediaPath(String imagesDir, String name) {
  if (p.isAbsolute(name)) {
    return name;
  }
  return p.join(imagesDir, name);
}
