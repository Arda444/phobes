import 'package:flutter/material.dart';

/// Supported app languages with native display labels (language picker).
class AppLocaleOption {
  const AppLocaleOption(this.locale, this.nativeLabel);

  final Locale locale;
  final String nativeLabel;
}

/// Keep in sync with [AppLocalizations.supportedLocales].
const List<AppLocaleOption> kAppLocaleOptions = [
  AppLocaleOption(Locale('ar'), 'العربية'),
  AppLocaleOption(Locale('de'), 'Deutsch'),
  AppLocaleOption(Locale('en'), 'English'),
  AppLocaleOption(Locale('es'), 'Español'),
  AppLocaleOption(Locale('fr'), 'Français'),
  AppLocaleOption(Locale('hi'), 'हिन्दी'),
  AppLocaleOption(Locale('it'), 'Italiano'),
  AppLocaleOption(Locale('ja'), '日本語'),
  AppLocaleOption(Locale('pt'), 'Português'),
  AppLocaleOption(Locale('ru'), 'Русский'),
  AppLocaleOption(Locale('tr'), 'Türkçe'),
  AppLocaleOption(Locale('zh'), '中文'),
];

const Set<String> kSupportedLanguageCodes = {
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
};

AppLocaleOption? localeOptionForCode(String? code) {
  if (code == null) return null;
  for (final o in kAppLocaleOptions) {
    if (o.locale.languageCode == code) return o;
  }
  return null;
}
