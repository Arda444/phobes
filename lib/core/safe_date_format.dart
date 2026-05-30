import 'package:intl/intl.dart';

/// Locales that [AppLocalizations] supports — keep in sync with [AppLocalizations.supportedLocales].
const List<String> kAppDateLocaleCodes = [
  'ar',
  'de',
  'en',
  'es',
  'fr',
  'hi',
  'it',
  'ja',
  'pt',
  'ru',
  'tr',
  'zh',
];

/// Formats [date] with [pattern] and [localeName], falling back to English when
/// locale symbol data is missing (avoids intl `cachedDateSymbols!` crashes on web).
String formatDateSafe(String pattern, DateTime date, String localeName) {
  final code = _languageCode(localeName);
  try {
    return DateFormat(pattern, code).format(date);
  } catch (_) {
    try {
      return DateFormat(pattern, 'en').format(date);
    } catch (_) {
      return DateFormat(pattern).format(date);
    }
  }
}

String _languageCode(String localeName) {
  final idx = localeName.indexOf('_');
  return idx == -1 ? localeName : localeName.substring(0, idx);
}
