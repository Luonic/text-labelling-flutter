import 'dart:convert';

const defaultFlagNames = <String>[
  'nudes_trade',
  'prostitution',
  'underwear_trade',
];

List<String> parseFlagCatalog(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is List) {
    return _uniqueStrings(decoded);
  }
  if (decoded is Map && decoded['flags'] is List) {
    return _uniqueStrings(decoded['flags'] as List);
  }
  throw const FormatException(
    'flags.json must be a JSON array of strings or an object with a flags array',
  );
}

String encodeFlagCatalog(List<String> flags) {
  return const JsonEncoder.withIndent('  ').convert(flags);
}

List<String> _uniqueStrings(List<dynamic> values) {
  final seen = <String>{};
  final flags = <String>[];
  for (final value in values) {
    final flag = value.toString();
    if (flag.isEmpty || !seen.add(flag)) {
      continue;
    }
    flags.add(flag);
  }
  if (flags.isEmpty) {
    throw const FormatException('flags.json does not contain any flag names');
  }
  return flags;
}
