import 'package:flutter/material.dart';
import 'package:phobes/l10n/app_localizations.dart';

/// Wraps [child] with MaterialApp + localizations for widget tests.
Widget wrapTestApp(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}
