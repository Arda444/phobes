// Merges string maps into app_en.arb / app_tr.arb (template + Turkish only).
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart run tool/merge_l10n.dart <batch.json>');
    exit(1);
  }
  final batch =
      jsonDecode(File(args[0]).readAsStringSync()) as Map<String, dynamic>;
  final enNew = batch['en'] as Map<String, dynamic>;
  final trNew = batch['tr'] as Map<String, dynamic>;
  final meta = batch['meta'] as Map<String, dynamic>?;

  _merge('lib/l10n/app_en.arb', enNew, meta);
  _merge('lib/l10n/app_tr.arb', trNew, null);
  print('Merged ${enNew.length} keys into en + tr ARB files.');
}

void _merge(
  String path,
  Map<String, dynamic> additions,
  Map<String, dynamic>? meta,
) {
  final file = File(path);
  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  var added = 0;
  for (final e in additions.entries) {
    if (e.key.startsWith('@')) continue;
    if (!data.containsKey(e.key)) {
      data[e.key] = e.value;
      added++;
      if (meta != null && meta.containsKey(e.key)) {
        data['@$e.key'] = meta[e.key];
      }
    }
  }
  const encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync('${encoder.convert(data)}\n');
  print('$path: +$added new keys');
}
