import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/l10n_lookup.dart';
import '../models/task_model.dart';
import 'nova_api_service.dart';
import 'nova_nlp_service.dart';
import 'nova_context_builder.dart';
import 'nova_tool_handler.dart';
import 'nova_tool_definitions.dart';

class NovaService {
  final _api = NovaApiService();
  final _ctx = NovaContextBuilder();

  String get _currentUserId =>
      FirebaseAuth.instance.currentUser?.uid ?? '';

  void invalidateContextCache() => _ctx.invalidate();

  // ── Private wrappers that delegate to dedicated services ─────────────────
  Future<String?> _sendRequest(String prompt, {double temperature = 0.7}) async {
    try {
      return await _api.sendRequest(prompt, temperature: temperature);
    } catch (e) {
      debugPrint('[NovaService] request failed: $e');
      return null;
    }
  }
  String _cleanJson(String raw) => NovaApiService.cleanJson(raw);
  Task? _tryDeterministicParse(String text) =>
      NovaNlpService.tryParse(text, userId: _currentUserId);
  Future<Task?> createTaskFromText(String userText) async {
    final localTask = _tryDeterministicParse(userText);
    if (localTask != null) {
      debugPrint('Nova: Yerel (Deterministik) çözümleme başarılı.');
      return localTask;
    }

    debugPrint("Nova: Yerel çözümleme başarısız, Gemini'ye soruluyor...");
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final locale = effectiveLanguageCode(
      (await SharedPreferences.getInstance()).getString('language_code'),
    );
    final dayName = DateFormat('EEEE', locale).format(now);

    final prompt = '''
    Sen bir sistem asistanısın. Kullanıcı girdisini analiz et ve JSON döndür.
    ŞU AN: ${dateFormat.format(now)} ($dayName)
    GİRDİ: "$userText"
    KURALLAR:
    - Tarih yoksa: Yarın 09:00.
    - Süre yoksa: 1 saat.
    - Saf JSON döndür (Markdown yok).
    FORMAT:
    {"title": "...", "description": "...", "startTime": "YYYY-MM-DD HH:mm", "endTime": "YYYY-MM-DD HH:mm", "priority": 1, "tags": ["..."]}
    ''';

    try {
      final response = await _sendRequest(prompt, temperature: 0.3);
      if (response == null) return null;

      final String cleanJson = _cleanJson(response);
      final Map<String, dynamic> taskData = jsonDecode(cleanJson);

      DateTime start;
      try {
        start = DateTime.parse(taskData['startTime']);
      } catch (e) {
        start = DateTime.now().add(const Duration(days: 1));
      }

      DateTime end;
      try {
        end = DateTime.parse(taskData['endTime']);
      } catch (e) {
        end = start.add(const Duration(hours: 1));
      }

      return Task(
        userId: _currentUserId,
        title: taskData['title'] ?? 'Yeni Görev',
        description: taskData['description'] ?? '',
        startTime: start,
        endTime: end,
        priority: taskData['priority'] is int ? taskData['priority'] : 1,
        tags: List<String>.from(taskData['tags'] ?? []),
      );
    } catch (e) {
      debugPrint('Task Oluşturma Hatası: $e');
      return null;
    }
  }

  Future<String> _buildUserContext({
    required String language,
    required String contextUserHeader,
    required String currentTimeLabel,
    required String tasksTodayLabel,
    required String upcomingTasksLabel,
    required String appointmentsLabel,
    required String medicationsLabel,
    required String habitsLabel,
    required String notesLabel,
    required String teamsLabel,
    required String budgetLabel,
    required String systemRole,
    required String toolUsageRulesHeader,
    required String readyInstruction,
  }) =>
      _ctx.build(
        language: language,
        contextUserHeader: contextUserHeader,
        currentTimeLabel: currentTimeLabel,
        tasksTodayLabel: tasksTodayLabel,
        upcomingTasksLabel: upcomingTasksLabel,
        appointmentsLabel: appointmentsLabel,
        medicationsLabel: medicationsLabel,
        habitsLabel: habitsLabel,
        notesLabel: notesLabel,
        teamsLabel: teamsLabel,
        budgetLabel: budgetLabel,
        systemRole: systemRole,
        toolUsageRulesHeader: toolUsageRulesHeader,
        readyInstruction: readyInstruction,
      );
  Future<String?> chatWithNova(
    List<Map<String, String>> history, {
    required String language,
    required String contextUserHeader,
    required String currentTimeLabel,
    required String tasksTodayLabel,
    required String upcomingTasksLabel,
    required String appointmentsLabel,
    required String medicationsLabel,
    required String habitsLabel,
    required String notesLabel,
    required String teamsLabel,
    required String budgetLabel,
    required String systemRole,
    required String toolUsageRulesHeader,
    required String readyInstruction,
  }) async {
    try {
      final String systemContext = await _buildUserContext(
        language: language,
        contextUserHeader: contextUserHeader,
        currentTimeLabel: currentTimeLabel,
        tasksTodayLabel: tasksTodayLabel,
        upcomingTasksLabel: upcomingTasksLabel,
        appointmentsLabel: appointmentsLabel,
        medicationsLabel: medicationsLabel,
        habitsLabel: habitsLabel,
        notesLabel: notesLabel,
        teamsLabel: teamsLabel,
        budgetLabel: budgetLabel,
        systemRole: systemRole,
        toolUsageRulesHeader: toolUsageRulesHeader,
        readyInstruction: readyInstruction,
      );

      final List<Map<String, dynamic>> messages = [
        {'role': 'system', 'content': systemContext},
      ];

      for (final msg in history) {
        final String role = msg['role'] == 'user' ? 'user' : 'assistant';
        messages.add({'role': role, 'content': msg['text'] ?? ''});
      }

      Map<String, dynamic>? data;
      try {
        data = await _api.sendChat(
          messages: messages,
          tools: List<Map<String, dynamic>>.from(NovaToolDefinitions.tools),
        );
      } catch (e) {
        debugPrint('[NovaService] sendChat failed: $e');
        return null;
      }

      if (data == null) return null;

      final choice = (data['choices'] as List?)?.firstOrNull;
      if (choice != null) {
        final message = choice['message'] as Map?;
        if (message == null) return null;

        final List<dynamic> toolCalls =
            List<dynamic>.from(message['tool_calls'] ?? []);

        if (toolCalls.isEmpty && message['content'] != null) {
          final String contentStr = message['content'] as String;
          final fallbackRe = RegExp(
              r'=?function=([a-zA-Z_]+)>({.*?})(?:</function>|$)',
              dotAll: true,);
          for (final m in fallbackRe.allMatches(contentStr)) {
            toolCalls.add({
              'function': {'name': m.group(1), 'arguments': m.group(2)},
            });
          }
        }

        if (toolCalls.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          final langCode = prefs.getString('language_code');
          String finalResponse = '';
          for (final toolCall in toolCalls) {
            final functionName = toolCall['function']['name'] as String;
            Map<String, dynamic> args;
            try {
              args = jsonDecode(
                    toolCall['function']['arguments'] as String,
                  )
                  as Map<String, dynamic>;
            } catch (e) {
              debugPrint('[NovaService] tool args parse: $e');
              continue;
            }
            finalResponse += await NovaToolHandler.handleToolCall(
              functionName,
              args,
              languageCode: langCode,
            );
          }
          return finalResponse.trim();
        }
        return message['content'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Chat Hata: $e');
      return null;
    }
  }

  Future<List<Task>> extractTasksFromNote(String noteContent) async {
    final now = DateTime.now();
    final prompt = '''
    Aşağıdaki notu analiz et ve içindeki "yapılacak işleri" bul.
    Her iş için bir JSON nesnesi oluştur ve bunları bir liste olarak döndür.
    NOT İÇERİĞİ: "$noteContent"
    ŞU AN: ${DateFormat('yyyy-MM-dd').format(now)}
    KURALLAR:
    - Belirsiz tarihler için "yarın" varsay.
    - Sadece JSON listesi döndür: `[{"title": "...", ...}, ...]`
    ''';

    try {
      final response = await _sendRequest(prompt, temperature: 0.4);
      if (response == null) return [];

      String cleanJson = _cleanJson(response);
      if (!cleanJson.startsWith('[')) {
        final int start = cleanJson.indexOf('[');
        final int end = cleanJson.lastIndexOf(']');
        if (start != -1 && end != -1) {
          cleanJson = cleanJson.substring(start, end + 1);
        } else {
          return [];
        }
      }

      final List<dynamic> dataList = jsonDecode(cleanJson);
      return dataList.map((data) {
        final DateTime start = DateTime.tryParse(data['startTime'] ?? '') ??
            DateTime.now().add(const Duration(days: 1));
        return Task(
          userId: _currentUserId,
          title: data['title'] ?? 'Not Görevi',
          description: "Notlardan: ${data['description'] ?? ''}",
          startTime: start,
          endTime: start.add(const Duration(hours: 1)),
          priority: data['priority'] ?? 1,
          tags: List<String>.from(data['tags'] ?? []),
        );
      }).toList();
    } catch (e) {
      debugPrint('Not Analiz Hatası: $e');
      return [];
    }
  }

  Future<DateTime?> findBestSlot(Task task, List<Task> existingTasks) async {
    final now = DateTime.now();
    final String schedule = existingTasks
        .map((t) =>
            "${DateFormat('yyyy-MM-dd HH:mm').format(t.startTime)} - ${DateFormat('HH:mm').format(t.endTime)}",)
        .join('\n');

    final prompt = '''
    MEVCUT PROGRAM:
    $schedule

    ERTELENECEK GÖREV:
    ${task.title} (Süre: ${(task.endTime.difference(task.startTime).inMinutes)} dk)

    ŞU AN: ${DateFormat('yyyy-MM-dd HH:mm').format(now)}

    KURALLAR:
    - Önümüzdeki 3 gün içinde, 09:00-22:00 arası EN UYGUN boş zamanı bul.
    - SADECE tarihi döndür: "YYYY-MM-DD HH:mm"
    ''';

    try {
      final response = await _sendRequest(prompt, temperature: 0.2);
      if (response == null) return null;
      return DateTime.tryParse(response.trim());
    } catch (e) {
      return null;
    }
  }

  Future<String?> analyzeBurnout(String statsSummary) async {
    final prompt = '''
    İSTATİSTİKLER:
    $statsSummary
    Bu kullanıcının "Tükenmişlik (Burnout)" riskini yorumla ve samimi, kısa bir sağlık tavsiyesi ver. Emoji kullan.
    ''';
    return await _sendRequest(prompt);
  }

  Future<String?> getDailyBriefing(List<Task> tasks, String userName) async {
    if (tasks.isEmpty) {
      return 'Merhaba $userName! Bugün boşsun, keyfine bak! 🌟';
    }
    final String list = tasks.map((t) => '- ${t.title}').join('\n');
    return await _sendRequest(
        'Kullanıcı: $userName. Görevler:\n$list\nKısa, motive edici günaydın mesajı yaz.',
        temperature: 0.8,);
  }

  Future<List<String>> generateSubtasks(String taskTitle) async {
    final res = await _sendRequest(
        'Görev: $taskTitle. 3-5 alt adıma böl. Sadece maddeler.',
        temperature: 0.5,);
    if (res == null) return [];
    return res
        .split('\n')
        .map((e) => e.replaceAll('-', '').trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<String?> getTaskMotivation(String taskTitle) async {
    final prompt =
        'Görevin adı: "$taskTitle". Bu görevi yapan kişiye "Harikasın, bitirdin!" temalı kısa, esprili ve gaza getirici tek cümlelik bir tebrik sözü yaz.';
    return await _sendRequest(prompt, temperature: 1.0);
  }

}