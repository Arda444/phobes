// Syncs missing keys from app_en.arb into other locale ARB files (English fallback).
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

void main() {
  const enPath = 'lib/l10n/app_en.arb';
  final en = jsonDecode(File(enPath).readAsStringSync()) as Map<String, dynamic>;
  final enKeys = en.keys.where((k) => !k.startsWith('@')).toList();

  for (final locale in [
    'ar',
    'de',
    'es',
    'fr',
    'hi',
    'it',
    'ja',
    'pt',
    'ru',
    'zh',
  ]) {
    final path = 'lib/l10n/app_$locale.arb';
    final file = File(path);
    if (!file.existsSync()) continue;
    final loc = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    var added = 0;
    for (final key in enKeys) {
      if (!loc.containsKey(key)) {
        loc[key] = en[key];
        added++;
      }
    }
    if (added > 0) {
      const encoder = JsonEncoder.withIndent('  ');
      final body = encoder.convert(loc);
      file.writeAsStringSync('$body\n');
      print('$path: +$added keys');
    }
  }
}
