// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

void main() {
  final en = _read('lib/l10n/app_en.arb');
  final enKeys = _messageKeys(en);
  var errors = 0;

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
    final path = 'lib/l10n/app_$loc.arb';
    try {
      final map = _read(path);
      final keys = _messageKeys(map);
      for (final k in enKeys) {
        if (!keys.contains(k)) {
          print('ERROR $path missing key: $k');
          errors++;
        }
      }
      for (final k in keys) {
        if (!enKeys.contains(k)) {
          print('WARN $path extra key: $k');
        }
        if (en[k] is String && map[k] is String) {
          final enPh = _placeholders(en[k] as String);
          final locPh = _placeholders(map[k] as String);
          if (enPh.toString() != locPh.toString()) {
            print('ERROR $path placeholder mismatch $k: en=$enPh loc=$locPh');
            errors++;
          }
        }
      }
    } catch (e) {
      print('ERROR $path parse failed: $e');
      errors++;
    }
  }

  // Duplicate keys in en (raw line scan)
  final lines = File('lib/l10n/app_en.arb').readAsLinesSync();
  final seen = <String>{};
  for (final line in lines) {
    final m = RegExp(r'^  "([^"@][^"]*)":').firstMatch(line);
    if (m != null) {
      final k = m.group(1)!;
      if (seen.contains(k)) {
        print('ERROR app_en.arb duplicate key: $k');
        errors++;
      }
      seen.add(k);
    }
  }

  if (errors == 0) {
    print('ARB validation OK');
  } else {
    print('ARB validation: $errors error(s)');
    exitCode = 1;
  }
}

Map<String, dynamic> _read(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

Set<String> _messageKeys(Map<String, dynamic> m) =>
    m.keys.where((k) => !k.startsWith('@')).toSet();

Set<String> _placeholders(String s) {
  final out = <String>{};
  for (final m in RegExp(r'\{([^}]+)\}').allMatches(s)) {
    out.add(m.group(1)!);
  }
  return out;
}

int exitCode = 0;
