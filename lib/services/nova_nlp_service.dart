import '../models/task_model.dart';

/// Pure deterministic NLP — no network calls, no state.
/// Extracts task data from Turkish natural-language text using regex + keyword rules.
class NovaNlpService {
  const NovaNlpService._();

  /// Returns a [Task] if the text can be deterministically parsed, or null
  /// if the text is ambiguous and needs LLM assistance.
  static Task? tryParse(String text, {String userId = ''}) {
    text = text.toLowerCase().trim();
    final now = DateTime.now();
    DateTime? startTime;
    String title = text;

    // ── Day keywords ────────────────────────────────────────────────────────
    if (text.contains('yarın sabah')) {
      final tomorrow = now.add(const Duration(days: 1));
      startTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
      title = title.replaceAll('yarın sabah', '').trim();
    } else if (text.contains('yarın akşam')) {
      final tomorrow = now.add(const Duration(days: 1));
      startTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 19);
      title = title.replaceAll('yarın akşam', '').trim();
    } else if (text.contains('yarın')) {
      final tomorrow = now.add(const Duration(days: 1));
      startTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      title = title.replaceAll('yarın', '').trim();
    } else if (text.contains('bu akşam')) {
      startTime = DateTime(now.year, now.month, now.day, 19);
      title = title.replaceAll('bu akşam', '').trim();
    } else if (text.contains('bugün')) {
      startTime = DateTime(now.year, now.month, now.day);
      title = title.replaceAll('bugün', '').trim();
    }

    // ── Weekday keywords ────────────────────────────────────────────────────
    const days = {
      'pazartesi': 1,
      'salı': 2,
      'çarşamba': 3,
      'perşembe': 4,
      'cuma': 5,
      'cumartesi': 6,
      'pazar': 7,
    };
    for (final entry in days.entries) {
      if (text.contains(entry.key)) {
        int diff = entry.value - now.weekday;
        if (diff <= 0) diff += 7;
        final target = now.add(Duration(days: diff));
        startTime = DateTime(target.year, target.month, target.day);
        title = title.replaceAll(entry.key, '').trim();
        break;
      }
    }

    // ── Time extraction ─────────────────────────────────────────────────────
    final timeReg = RegExp(r'(\d{1,2})[:.](\d{2})');
    final match = timeReg.firstMatch(text);
    if (match != null) {
      final hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      startTime ??= DateTime(now.year, now.month, now.day);
      startTime =
          DateTime(startTime.year, startTime.month, startTime.day, hour, minute);
      title = title.replaceAll(match.group(0)!, '').trim();
    } else {
      final simpleTimeReg = RegExp(r'saat\s*(\d{1,2})');
      final simpleMatch = simpleTimeReg.firstMatch(text);
      if (simpleMatch != null) {
        final hour = int.parse(simpleMatch.group(1)!);
        startTime ??= DateTime(now.year, now.month, now.day);
        startTime = DateTime(
            startTime.year, startTime.month, startTime.day, hour,);
        title = title.replaceAll(simpleMatch.group(0)!, '').trim();
      }
    }

    if (startTime == null) return null;

    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (title.isEmpty) title = 'Yeni Görev';

    return Task(
      userId: userId,
      title: capitalize(title),
      description: 'Deterministik olarak analiz edildi.',
      startTime: startTime,
      endTime: startTime.add(const Duration(hours: 1)),
      tags: [],
    );
  }

  static String capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

}
