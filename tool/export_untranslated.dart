// Exports keys that still match English (need real translation).
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final locale = args.isNotEmpty ? args[0] : 'de';
  final en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
      as Map<String, dynamic>;
  final loc = jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
      as Map<String, dynamic>;

  final out = <String, String>{};
  for (final k in loc.keys) {
    if (k.startsWith('@')) continue;
    if (!en.containsKey(k)) continue;
    if (loc[k] is String && en[k] is String && loc[k] == en[k]) {
      out[k] = en[k] as String;
    }
  }
  final path = 'tool/l10n_untranslated/$locale.json';
  File(path).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(out)}\n');
  print('Wrote ${out.length} keys to $path');
}
