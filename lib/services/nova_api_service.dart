import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cloud_functions/cloud_functions.dart';
import '../core/firebase_errors.dart';

/// Routes all Nova AI requests through Firebase Cloud Functions.
/// The Groq API key lives ONLY on the server — never sent to the client.
class NovaApiService {
  NovaApiService._();
  static final NovaApiService _instance = NovaApiService._();
  factory NovaApiService() => _instance;

  static const String defaultModel = 'llama-3.1-8b-instant';

  // Keep these for backward-compat constants used in nova_service.dart.
  static const String baseUrl =
      'https://europe-west1-phobes-d428d.cloudfunctions.net/novaChat';

  final _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');

  // ── Single-turn text prompt ────────────────────────────────────────────────

  Future<String?> sendRequest(String prompt,
      {double temperature = 0.7, String model = defaultModel,}) async {
    try {
      final callable = _functions.httpsCallable('novaSimplePrompt');
      final result = await callable.call<Map<dynamic, dynamic>>({
        'prompt': prompt,
        'temperature': temperature,
        'model': model,
      });
      return result.data['content'] as String?;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[NovaApiService] sendRequest error: ${e.code} ${e.message}');
      throw NovaApiException(
        e.message ?? 'Nova isteği başarısız.',
        code: e.code,
      );
    } catch (e) {
      debugPrint('[NovaApiService] sendRequest unexpected: $e');
      if (e is NovaApiException) rethrow;
      throw NovaApiException('Nova isteği başarısız.');
    }
  }

  // ── Multi-turn chat with tools ─────────────────────────────────────────────

  Future<Map<String, dynamic>?> sendChat({
    required List<Map<String, dynamic>> messages,
    List<Map<String, dynamic>>? tools,
    double temperature = 0.9,
    String model = defaultModel,
  }) async {
    try {
      final callable = _functions.httpsCallable('novaChat');
      final payload = <String, dynamic>{
        'messages': messages,
        'temperature': temperature,
        'model': model,
      };
      if (tools != null && tools.isNotEmpty) payload['tools'] = tools;

      final result = await callable.call<Map<dynamic, dynamic>>(payload);
      // Callable returns a Map<dynamic,dynamic>; convert to Map<String,dynamic>
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[NovaApiService] sendChat error: ${e.code} ${e.message}');
      throw NovaApiException(
        e.message ?? 'Nova sohbeti başarısız.',
        code: e.code,
      );
    } catch (e) {
      debugPrint('[NovaApiService] sendChat unexpected: $e');
      if (e is NovaApiException) rethrow;
      throw NovaApiException('Nova sohbeti başarısız.');
    }
  }

  /// Strips markdown code fences and extracts the first JSON object or array.
  static String cleanJson(String raw) {
    final String clean = raw.replaceAll('```json', '').replaceAll('```', '');
    int start = clean.indexOf('{');
    int end = clean.lastIndexOf('}');
    if (start != -1 && end != -1) return clean.substring(start, end + 1);
    start = clean.indexOf('[');
    end = clean.lastIndexOf(']');
    if (start != -1 && end != -1) return clean.substring(start, end + 1);
    return clean;
  }

  // fetchApiKey kept for backward-compat; returns null — key is now server-side.
  Future<String?> fetchApiKey() async => null;
  void clearApiKeyCache() {}
}
