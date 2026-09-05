import 'package:flutter/material.dart';

import '../models/label_record.dart';
import 'media_strip.dart';

class RecordCard extends StatelessWidget {
  const RecordCard({super.key, required this.record, required this.imagesDir});

  final LabelRecord record;
  final String imagesDir;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MediaStrip(names: record.images, imagesDir: imagesDir),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  record.title.isEmpty ? '(no title)' : record.title,
                  style: textTheme.titleLarge,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  record.description.isEmpty
                      ? '(no description)'
                      : record.description,
                  style: textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
