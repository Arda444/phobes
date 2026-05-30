// Merges per-locale translation maps into app_{locale}.arb files.
// Usage: dart run tool/merge_all_locales.dart path/to/pack.json
// Pack format: { "de": { "key": "value", ... }, "es": { ... } }
// JSON format: { "de": { "key": "value", ... }, "es": { ... }, ... }
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart run tool/merge_all_locales.dart <pack.json>');
    exit(1);
  }
  final pack =
      jsonDecode(File(args[0]).readAsStringSync()) as Map<String, dynamic>;

  for (final entry in pack.entries) {
    final locale = entry.key;
    if (locale == 'meta' || locale == 'en' || locale == 'tr') continue;
    final map = entry.value as Map<String, dynamic>;
    final path = 'lib/l10n/app_$locale.arb';
    if (!File(path).existsSync()) {
      print('Skip missing $path');
      continue;
    }
    final data = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    var updated = 0;
    for (final e in map.entries) {
      if (e.key.startsWith('@')) continue;
      data[e.key] = e.value;
      updated++;
    }
    File(path).writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(data)}\n');
    print('$path: updated $updated keys');
  }
}
