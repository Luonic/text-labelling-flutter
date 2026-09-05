import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/flag_catalog.dart';

abstract class FlagsRepository {
  Future<List<String>> load();

  Future<void> save(List<String> flags);
}

class MemoryFlagsRepository implements FlagsRepository {
  MemoryFlagsRepository(List<String> flags) : flags = List<String>.from(flags);

  List<String> flags;

  @override
  Future<List<String>> load() async => List<String>.from(flags);

  @override
  Future<void> save(List<String> flags) async {
    this.flags = List<String>.from(flags);
  }
}

class AssetDocumentFlagsRepository implements FlagsRepository {
  AssetDocumentFlagsRepository({
    this.assetPath = 'assets/flags.json',
    this.fileName = 'flags.json',
    AssetBundle? bundle,
    Future<Directory> Function()? documentsDirectory,
  }) : bundle = bundle ?? rootBundle,
       documentsDirectory =
           documentsDirectory ?? getApplicationDocumentsDirectory;

  final String assetPath;
  final String fileName;
  final AssetBundle bundle;
  final Future<Directory> Function() documentsDirectory;

  Future<File> get _file async {
    final directory = await documentsDirectory();
    return File(p.join(directory.path, fileName));
  }

  @override
  Future<List<String>> load() async {
    final file = await _file;
    if (await file.exists()) {
      return parseFlagCatalog(await file.readAsString());
    }
    try {
      final raw = await bundle.loadString(assetPath);
      await file.writeAsString(raw, flush: true);
      return parseFlagCatalog(raw);
    } catch (_) {
      await save(defaultFlagNames);
      return List<String>.from(defaultFlagNames);
    }
  }

  @override
  Future<void> save(List<String> flags) async {
    final file = await _file;
    await file.parent.create(recursive: true);
    await file.writeAsString(encodeFlagCatalog(flags), flush: true);
  }
}
