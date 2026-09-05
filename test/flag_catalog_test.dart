import 'package:flutter_test/flutter_test.dart';
import 'package:text_labelling_flutter/models/flag_catalog.dart';

void main() {
  test('parses a JSON array of flag names', () {
    expect(parseFlagCatalog('["nudes_trade", "prostitution"]'), [
      'nudes_trade',
      'prostitution',
    ]);
  });

  test('parses an object with a flags array', () {
    expect(parseFlagCatalog('{"flags":["underwear_trade","nudes_trade"]}'), [
      'underwear_trade',
      'nudes_trade',
    ]);
  });

  test('drops duplicates and empty names', () {
    expect(parseFlagCatalog('["a","","a","b"]'), ['a', 'b']);
  });

  test('round-trips catalog encoding', () {
    const flags = ['nudes_trade', 'prostitution', 'underwear_trade'];
    expect(parseFlagCatalog(encodeFlagCatalog(flags)), flags);
  });
}
