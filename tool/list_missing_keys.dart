// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

void main() {
  final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
      as Map<String, dynamic>;
  final enKeys = en.keys.where((k) => !k.startsWith('@')).toSet();
  final de = jsonDecode(File('lib/l10n/app_de.arb').readAsStringSync())
      as Map<String, dynamic>;
  final missing = enKeys.where((k) => !de.containsKey(k)).toList()..sort();
  print('Missing in de (${missing.length}):');
  for (final k in missing) {
    print('  $k: ${en[k]}');
  }
}
