import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../models/flag_catalog.dart';
import '../models/label_record.dart';
import '../services/flags_repository.dart';
import '../services/jsonl_picker.dart';
import '../services/jsonl_repository.dart';
import '../services/storage_permissions.dart';

typedef PathPicker = Future<String?> Function();
typedef PermissionRequest = Future<void> Function();

class LabelSession extends ChangeNotifier {
  LabelSession({
    FlagsRepository? flagsRepository,
    JsonlRepository? jsonlRepository,
    PathPicker? pickPath,
    PermissionRequest? requestPermissions,
  }) : flagsRepository = flagsRepository ?? AssetDocumentFlagsRepository(),
       jsonlRepository = jsonlRepository ?? const FileJsonlRepository(),
       pickPath = pickPath ?? pickJsonlPath,
       requestPermissions =
           requestPermissions ?? LabelSession._defaultRequestPermissions;

  final FlagsRepository flagsRepository;
  final JsonlRepository jsonlRepository;
  final PathPicker pickPath;
  final PermissionRequest requestPermissions;

  static Future<void> _defaultRequestPermissions() async {
    await requestStoragePermissions();
  }

  List<String> availableFlags = List<String>.from(defaultFlagNames);
  List<LabelRecord> records = [];
  int currentIndex = 0;
  String? jsonlPath;
  String? imagesDir;
  String? errorMessage;
  bool busy = false;
  bool dirty = false;

  Future<void> _writeChain = Future<void>.value();

  LabelRecord? get currentRecord {
    if (records.isEmpty || currentIndex < 0 || currentIndex >= records.length) {
      return null;
    }
    return records[currentIndex];
  }

  String get progressLabel {
    if (records.isEmpty) {
      return 'No file';
    }
    return '${currentIndex + 1} / ${records.length}';
  }

  String get fileLabel {
    final path = jsonlPath;
    if (path == null) {
      return 'Text Labelling';
    }
    return p.basename(path);
  }

  List<String> flagsFor(int index) {
    final flags = [...availableFlags];
    if (index >= 0 && index < records.length) {
      for (final flag in records[index].selectedFlags) {
        if (!flags.contains(flag)) {
          flags.add(flag);
        }
      }
    }
    return flags;
  }

  List<String> get visibleFlags => flagsFor(currentIndex);

  String? takeError() {
    final error = errorMessage;
    errorMessage = null;
    return error;
  }

  Future<void> loadFlagCatalog() async {
    try {
      final loaded = await flagsRepository.load();
      availableFlags = loaded.isEmpty
          ? List<String>.from(defaultFlagNames)
          : loaded;
      errorMessage = null;
    } catch (error) {
      availableFlags = List<String>.from(defaultFlagNames);
      errorMessage = 'Could not load flags.json, using defaults. $error';
    }
    notifyListeners();
  }

  Future<void> pickAndOpen() async {
    if (busy) {
      return;
    }
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await requestPermissions();
      final path = await pickPath();
      if (path == null || path.isEmpty) {
        return;
      }
      await openPath(path);
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> openPath(String path) async {
    if (jsonlPath != null && dirty) {
      await save();
    }
    final loaded = await jsonlRepository.read(path);
    records = loaded;
    jsonlPath = path;
    imagesDir = p.join(p.dirname(path), 'images');
    currentIndex = 0;
    dirty = false;
    errorMessage = null;
    final imageFolder = imagesDir;
    if ((Platform.isAndroid || Platform.isIOS || Platform.isMacOS) &&
        imageFolder != null &&
        !Directory(imageFolder).existsSync()) {
      errorMessage =
          'Opened ${p.basename(path)}, but no images folder was found at $imageFolder.';
    }
    notifyListeners();
  }

  void toggleFlag(String flag, {int? index}) {
    final target = index ?? currentIndex;
    if (target < 0 || target >= records.length) {
      return;
    }
    final record = records[target];
    final next = Set<String>.from(record.selectedFlags);
    if (!next.add(flag)) {
      next.remove(flag);
    }
    records[target] = record.copyWith(selectedFlags: next);
    dirty = true;
    notifyListeners();
  }

  Future<void> onPageChanged(int index) async {
    if (index == currentIndex || index < 0 || index >= records.length) {
      return;
    }
    await save();
    currentIndex = index;
    notifyListeners();
  }

  Future<void> save() {
    _writeChain = _writeChain.then((_) => _saveNow());
    return _writeChain;
  }

  Future<void> _saveNow() async {
    final path = jsonlPath;
    if (path == null) {
      return;
    }
    try {
      await jsonlRepository.write(path, records);
      dirty = false;
      errorMessage = null;
    } catch (error) {
      errorMessage = 'Could not save JSONL: $error';
    }
    notifyListeners();
  }
}
