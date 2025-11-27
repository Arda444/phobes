import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/task_model.dart';

class NovaService {
  // ⚠️ API KEY'İNİ BURAYA YAPISTIR
  static const String _apiKey = 'AIzaSyCNowKOm-oUqmBbfRGP3uGod0GgbYwo9Vo';

  // Model: gemini-2.0-flash
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  // --- 1. GÖREV OLUŞTURMA MODU ---
  Future<Task?> createTaskFromText(String userText) async {
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final dayName = DateFormat('EEEE', 'tr').format(now);

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

      String cleanJson = _cleanJson(response);
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
        userId: '',
        title: taskData['title'] ?? 'Yeni Görev',
        description: taskData['description'] ?? '',
        startTime: start,
        endTime: end,
        priority: taskData['priority'] is int ? taskData['priority'] : 1,
        tags: List<String>.from(taskData['tags'] ?? []),
        isAllDay: false,
        color: 0xFF4285F4,
      );
    } catch (e) {
      debugPrint("Task Oluşturma Hatası: $e");
      return null;
    }
  }

  // --- 2. SOHBET MODU ---
  Future<String?> chatWithNova(List<Map<String, String>> history) async {
    try {
      List<Map<String, dynamic>> contents = history.map((msg) {
        return {
          "role": msg['role'],
          "parts": [
            {"text": msg['text']}
          ]
        };
      }).toList();

      final requestBody = {
        "system_instruction": {
          "parts": [
            {
              "text":
                  "Senin adın Nova. Zeki, esprili ve motive edici bir yaşam koçusun. Türkçe konuş."
            }
          ]
        },
        "contents": contents,
        "generationConfig": {"temperature": 0.9}
      };

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates']?[0]['content']['parts']?[0]['text'];
      }
      return null;
    } catch (e) {
      debugPrint("Chat Hata: $e");
      return null;
    }
  }

  // --- 3. NOTLARDAN GÖREV ÇIKARMA ---
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
        int start = cleanJson.indexOf('[');
        int end = cleanJson.lastIndexOf(']');
        if (start != -1 && end != -1) {
          cleanJson = cleanJson.substring(start, end + 1);
        } else {
          return [];
        }
      }

      final List<dynamic> dataList = jsonDecode(cleanJson);
      return dataList.map((data) {
        DateTime start = DateTime.tryParse(data['startTime'] ?? '') ??
            DateTime.now().add(const Duration(days: 1));
        return Task(
          userId: '',
          title: data['title'] ?? 'Not Görevi',
          description: "Notlardan: ${data['description'] ?? ''}",
          startTime: start,
          endTime: start.add(const Duration(hours: 1)),
          priority: data['priority'] ?? 1,
          tags: List<String>.from(data['tags'] ?? []),
        );
      }).toList();
    } catch (e) {
      debugPrint("Not Analiz Hatası: $e");
      return [];
    }
  }

  // --- 4. AKILLI ZAMANLAMA ---
  Future<DateTime?> findBestSlot(Task task, List<Task> existingTasks) async {
    final now = DateTime.now();
    String schedule = existingTasks
        .map((t) =>
            "${DateFormat('yyyy-MM-dd HH:mm').format(t.startTime)} - ${DateFormat('HH:mm').format(t.endTime)}")
        .join("\n");

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

  // --- 5. TÜKENMİŞLİK ANALİZİ ---
  Future<String?> analyzeBurnout(String statsSummary) async {
    final prompt = '''
    İSTATİSTİKLER:
    $statsSummary
    Bu kullanıcının "Tükenmişlik (Burnout)" riskini yorumla ve samimi, kısa bir sağlık tavsiyesi ver. Emoji kullan.
    ''';
    return await _sendRequest(prompt, temperature: 0.7);
  }

  // --- 6. GÜNLÜK BRİFİNG ---
  Future<String?> getDailyBriefing(List<Task> tasks, String userName) async {
    if (tasks.isEmpty) {
      return "Merhaba $userName! Bugün boşsun, keyfine bak! 🌟";
    }
    String list = tasks.map((t) => "- ${t.title}").join("\n");
    return await _sendRequest(
        "Kullanıcı: $userName. Görevler:\n$list\nKısa, motive edici günaydın mesajı yaz.",
        temperature: 0.8);
  }

  // --- 7. ALT GÖREVLER ---
  Future<List<String>> generateSubtasks(String taskTitle) async {
    final res = await _sendRequest(
        "Görev: $taskTitle. 3-5 alt adıma böl. Sadece maddeler.",
        temperature: 0.5);
    if (res == null) return [];
    return res
        .split('\n')
        .map((e) => e.replaceAll('-', '').trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  // --- 8. GÖREV MOTİVASYONU (EKSİK OLAN BUYDU) ---
  Future<String?> getTaskMotivation(String taskTitle) async {
    final prompt =
        'Görevin adı: "$taskTitle". Bu görevi yapan kişiye "Harikasın, bitirdin!" temalı kısa, esprili ve gaza getirici tek cümlelik bir tebrik sözü yaz.';
    return await _sendRequest(prompt, temperature: 1.0);
  }

  // --- YARDIMCI FONKSİYONLAR ---
  Future<String?> _sendRequest(String prompt,
      {double temperature = 0.7}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ],
          "generationConfig": {"temperature": temperature}
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates']?[0]['content']['parts']?[0]['text'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String _cleanJson(String raw) {
    String clean = raw.replaceAll('```json', '').replaceAll('```', '');
    int start = clean.indexOf('{');
    int end = clean.lastIndexOf('}');
    if (start != -1 && end != -1) return clean.substring(start, end + 1);

    // Liste kontrolü
    start = clean.indexOf('[');
    end = clean.lastIndexOf(']');
    if (start != -1 && end != -1) return clean.substring(start, end + 1);

    return clean;
  }
}
