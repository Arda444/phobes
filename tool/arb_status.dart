// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

void main() {
  final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
      as Map<String, dynamic>;
  final enKeys = en.keys.where((k) => !k.startsWith('@')).toList();
  print('en keys: ${enKeys.length}');
  for (final loc in [
    'tr',
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
    final d = jsonDecode(File('lib/l10n/app_$loc.arb').readAsStringSync())
        as Map<String, dynamic>;
    final keys = d.keys.where((k) => !k.startsWith('@')).toSet();
    final missing = enKeys.where((k) => !keys.contains(k)).length;
    var sameEn = 0;
    for (final k in keys) {
      if (!en.containsKey(k)) continue;
      if (d[k] is String && en[k] is String && d[k] == en[k]) {
        final s = d[k] as String;
        if (s.length > 2 && !s.contains('{') && !RegExp(r'^[A-Z0-9\s\.\+\-]+$').hasMatch(s)) {
          sameEn++;
        }
      }
    }
    print('$loc: keys=${keys.length} missing=$missing sameAsEn~=$sameEn');
  }
}
