import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app_locales.dart';

/// Resolves [AppLocalizations] without [BuildContext] (services, isolates).
AppLocalizations l10nFor(String? languageCode) {
  final code = effectiveLanguageCode(languageCode);
  return lookupAppLocalizations(Locale(code));
}

/// Normalizes prefs / system codes to a supported app language.
String effectiveLanguageCode(String? languageCode) {
  final code = languageCode?.trim();
  if (code != null && kSupportedLanguageCodes.contains(code)) {
    return code;
  }
  return 'en';
}
