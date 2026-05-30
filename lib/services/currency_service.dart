import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  final Map<String, double> _cache = {};
  final Map<String, DateTime> _cacheTime = {};
  static const _cacheTtl = Duration(minutes: 5);

  bool _isCacheValid(String key) {
    final t = _cacheTime[key];
    return t != null && DateTime.now().difference(t) < _cacheTtl;
  }

  final Map<String, String> _cryptoMapping = {
    'BTC': 'bitcoin',
    'ETH': 'ethereum',
    'SOL': 'solana',
    'AVAX': 'avalanche-2',
    'XRP': 'ripple',
    'LINK': 'chainlink',
    'ADA': 'cardano',
    'DOT': 'polkadot',
    'DOGE': 'dogecoin',
    'BNB': 'binancecoin',
  };

  Future<double?> getLivePrice(String symbol, String type) async {
    final key = '${type}_$symbol'.toUpperCase();
    if (_isCacheValid(key)) return _cache[key];
    try {
      final upperSymbol = symbol.toUpperCase();
      double? price;
      if (type.toLowerCase() == 'crypto') {
        price = await _getCryptoPrice(upperSymbol);
      } else if (type.toLowerCase() == 'currency' ||
          type.toLowerCase() == 'gold') {
        price = await _getFiatOrGoldPrice(upperSymbol);
      }
      if (price != null) {
        _cache[key] = price;
        _cacheTime[key] = DateTime.now();
      }
      return price;
    } catch (e) {
      debugPrint('CurrencyService Error ($symbol): $e');
      return null;
    }
  }

  Future<double?> _getCryptoPrice(String symbol) async {
    final id = _cryptoMapping[symbol] ?? symbol.toLowerCase();
    final url =
        'https://api.coingecko.com/api/v3/simple/price?ids=$id&vs_currencies=try';

    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data[id] != null && data[id]['try'] != null) {
          return (data[id]['try'] as num).toDouble();
        }
      }
    } catch (e) {
      debugPrint('CoinGecko API Error: $e');
    }
    return null;
  }

  Future<double?> _getFiatOrGoldPrice(String symbol) async {
    const url = 'https://api.exchangerate-api.com/v4/latest/TRY';

    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;

        if (symbol == 'GAU' || symbol == 'GOLD' || symbol == 'XAU') {
          final xauRate = rates['XAU'] ?? rates['GOLD'];
          if (xauRate != null) {
            final ouncePriceTry = 1.0 / (xauRate as num).toDouble();
            return ouncePriceTry / 31.1035;
          }
        } else if (rates[symbol] != null) {
          return 1.0 / (rates[symbol] as num).toDouble();
        }
      }
    } catch (e) {
      debugPrint('Fiat API Error: $e');
    }
    return null;
  }
}
