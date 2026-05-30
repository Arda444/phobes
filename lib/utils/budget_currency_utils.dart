import 'package:intl/intl.dart';
import 'package:phobes/l10n/app_localizations.dart';

const Map<String, String> kCurrencySymbols = {
  'TRY': '₺',
  'USD': '\$',
  'EUR': '€',
  'GBP': '£',
  'JPY': '¥',
  'CHF': 'CHF ',
  'CAD': 'CA\$',
  'AUD': 'A\$',
  'CNY': '¥',
  'RUB': '₽',
};

const List<String> kSupportedCurrencies = [
  'TRY', 'USD', 'EUR', 'GBP', 'JPY', 'CHF', 'CAD', 'AUD', 'CNY', 'RUB',
];

String getCurrencySymbol(String? code) =>
    kCurrencySymbols[code ?? 'TRY'] ?? (code ?? '₺');

String formatCurrency(double amount, String? currencyCode) {
  final symbol = getCurrencySymbol(currencyCode);
  return NumberFormat.currency(symbol: symbol, decimalDigits: 0).format(amount);
}

/// Firestore category values (Turkish keys) used across the budget module.
const List<String> kBudgetCategoryStorageKeys = [
  'Genel',
  'Yemek',
  'Market',
  'Ulaşım',
  'Eğlence',
  'Kira',
  'Fatura',
  'Sağlık',
  'Maaş',
  'Diğer',
];

String budgetCategoryLabel(AppLocalizations l10n, String storageKey) {
  switch (storageKey) {
    case 'Genel':
      return l10n.budgetCatGeneral;
    case 'Yemek':
      return l10n.budgetCatFood;
    case 'Market':
      return l10n.budgetCatGroceries;
    case 'Ulaşım':
      return l10n.budgetCatTransport;
    case 'Eğlence':
      return l10n.budgetCatEntertainment;
    case 'Kira':
      return l10n.budgetCatRent;
    case 'Fatura':
      return l10n.budgetCatBills;
    case 'Sağlık':
      return l10n.budgetCatHealth;
    case 'Maaş':
      return l10n.budgetCatSalary;
    case 'Diğer':
      return l10n.budgetCatOther;
    default:
      return storageKey;
  }
}

String formatCurrencyCompact(double amount, String? currencyCode) {
  final symbol = getCurrencySymbol(currencyCode);
  if (amount.abs() >= 1000000) {
    return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
  }
  if (amount.abs() >= 1000) {
    return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
  }
  return '$symbol${amount.toStringAsFixed(0)}';
}
