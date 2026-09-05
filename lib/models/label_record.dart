class LabelRecord {
  LabelRecord({
    required this.images,
    required this.title,
    required this.description,
    Set<String>? selectedFlags,
    Map<String, dynamic>? extras,
  }) : selectedFlags = selectedFlags ?? <String>{},
       extras = extras ?? const <String, dynamic>{};

  final List<String> images;
  final String title;
  final String description;
  final Set<String> selectedFlags;
  final Map<String, dynamic> extras;

  static const _ownedKeys = {'images', 'title', 'description', 'flags'};

  factory LabelRecord.fromJson(Map<String, dynamic> json) {
    final extras = Map<String, dynamic>.from(json)
      ..removeWhere((key, _) => _ownedKeys.contains(key));
    return LabelRecord(
      images: _stringList(json['images']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      selectedFlags: _flagSet(json['flags']),
      extras: extras,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'images': images,
      'title': title,
      'description': description,
      'flags': (selectedFlags.toList()..sort()),
      ...extras,
    };
  }

  LabelRecord copyWith({Set<String>? selectedFlags}) {
    return LabelRecord(
      images: images,
      title: title,
      description: description,
      selectedFlags: selectedFlags ?? this.selectedFlags,
      extras: extras,
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    if (value is String && value.isNotEmpty) {
      return [value];
    }
    return const [];
  }

  static Set<String> _flagSet(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toSet();
    }
    if (value is String && value.isNotEmpty) {
      return {value};
    }
    if (value is Map) {
      return value.entries
          .where(
            (entry) =>
                entry.value == true ||
                entry.value == 1 ||
                entry.value == 'true',
          )
          .map((entry) => entry.key.toString())
          .where((item) => item.isNotEmpty)
          .toSet();
    }
    return <String>{};
  }
}
