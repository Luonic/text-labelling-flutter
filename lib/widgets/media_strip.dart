import 'dart:io';

import 'package:flutter/material.dart';

import '../models/media_kind.dart';

class MediaStrip extends StatelessWidget {
  const MediaStrip({super.key, required this.names, required this.imagesDir});

  final List<String> names;
  final String imagesDir;

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(child: Text('No images')),
      );
    }

    return SizedBox(
      height: 148,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: names.length,
        separatorBuilder: (context, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final name = names[index];
          return MediaThumbnail(
            name: name,
            filePath: resolveMediaPath(imagesDir, name),
          );
        },
      ),
    );
  }
}

class MediaThumbnail extends StatelessWidget {
  const MediaThumbnail({super.key, required this.name, required this.filePath});

  final String name;
  final String filePath;

  @override
  Widget build(BuildContext context) {
    final kind = mediaKindForName(name);
    final file = File(filePath);
    final exists = file.existsSync();

    Widget child;
    if (kind == MediaKind.image && exists) {
      child = Image.file(
        file,
        fit: BoxFit.cover,
        width: 140,
        height: 140,
        errorBuilder: (context, error, stackTrace) =>
            _Placeholder(name: name, kind: kind),
      );
    } else {
      child = _Placeholder(name: name, kind: kind, missing: !exists);
    }

    return GestureDetector(
      onTap: exists && kind == MediaKind.image
          ? () => _openPreview(context, file)
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(width: 140, height: 140, child: child),
      ),
    );
  }

  Future<void> _openPreview(BuildContext context, File file) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              InteractiveViewer(child: Image.file(file, fit: BoxFit.contain)),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.name,
    required this.kind,
    this.missing = false,
  });

  final String name;
  final MediaKind kind;
  final bool missing;

  @override
  Widget build(BuildContext context) {
    final icon = switch (kind) {
      MediaKind.video => Icons.videocam,
      MediaKind.image => Icons.broken_image,
      MediaKind.unknown => Icons.insert_drive_file,
    };
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36),
            const SizedBox(height: 8),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (missing)
              Text(
                kind == MediaKind.video ? 'video' : 'missing',
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
      ),
    );
  }
}
