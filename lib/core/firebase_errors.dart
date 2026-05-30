import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../widgets/phobes_widgets.dart';

/// Maps Firebase errors to user-facing messages.
class FirebaseErrors {
  FirebaseErrors._();

  static String message(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context);
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return l10n?.errorPermissionDenied ??
              'You do not have permission for this action.';
        case 'not-found':
          return l10n?.errorNotFound ?? 'Record not found.';
        case 'unavailable':
          return l10n?.errorUnavailable ??
              'Service temporarily unavailable. Try again.';
        case 'resource-exhausted':
          return l10n?.errorRateLimited ??
              'Too many requests. Please wait.';
        default:
          break;
      }
    }
    if (error is FirebaseFunctionsException) {
      switch (error.code) {
        case 'permission-denied':
        case 'unauthenticated':
          return l10n?.errorPermissionDenied ??
              'You do not have permission for this action.';
        case 'not-found':
          return l10n?.errorNotFound ?? 'Record not found.';
        case 'resource-exhausted':
          return l10n?.errorRateLimited ??
              'Too many requests. Please wait.';
        case 'invalid-argument':
          return error.message ??
              (l10n?.errorInvalidInput ?? 'Invalid input.');
        default:
          return error.message ??
              (l10n?.errorGeneric(error.code) ?? 'Something went wrong.');
      }
    }
    if (error is FirebaseAuthException) {
      return error.message ?? (l10n?.errorAuth ?? 'Authentication error.');
    }
    final msg = error.toString();
    if (msg.contains('BUDGET_LIMIT_EXCEEDED')) {
      return l10n?.budgetLimitExceeded('') ??
          'Budget Limit Exceeded! 🚨';
    }
    return l10n?.errorGeneric(error.toString()) ??
        'Something went wrong. Please try again.';
  }

  static void showSnackBar(BuildContext context, Object error) {
    if (!context.mounted) return;
    PhobesSnackbar.show(
      context,
      message: message(context, error),
      type: PhobesSnackbarType.error,
    );
  }
}

/// Nova API failure with a user-visible message.
class NovaApiException implements Exception {
  NovaApiException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => message;
}
