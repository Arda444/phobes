import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import 'package:phobes/utils/time_utils.dart';
import 'firebase_service.dart';
import 'budget_service.dart';

class NovaService {
  static String? _apiKey;

  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.1-8b-instant';

  /// Firestore 'config/nova' dokümanından Groq API anahtarını çeker ve önbelleğe alır.
  Future<String?> _fetchApiKey() async {
    if (_apiKey != null) return _apiKey;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('nova')
          .get();
      if (doc.exists && doc.data() != null) {
        String? fetchedKey = doc.data()!['groq_api_key'] as String?;
        // Eski sisteme geri dönük uyumluluk veya eğer oraya yazıldıysa
        fetchedKey ??= doc.data()!['gemini_api_key'] as String?;

        if (fetchedKey != null) {
          _apiKey = fetchedKey.trim();
        }
      }
    } catch (e) {
      debugPrint('Nova API key alınamadı: $e');
    }
    return _apiKey;
  }

  Future<Task?> createTaskFromText(String userText) async {
    final localTask = _tryDeterministicParse(userText);
    if (localTask != null) {
      debugPrint("Nova: Yerel (Deterministik) çözümleme başarılı.");
      return localTask;
    }

    debugPrint("Nova: Yerel çözümleme başarısız, Gemini'ye soruluyor...");
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

  Task? _tryDeterministicParse(String text) {
    text = text.toLowerCase().trim();
    DateTime now = DateTime.now();
    DateTime? startTime;
    String title = text;

    if (text.contains('yarın sabah')) {
      final tomorrow = now.add(const Duration(days: 1));
      startTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
      title = title.replaceAll('yarın sabah', '').trim();
    } else if (text.contains('yarın akşam')) {
      final tomorrow = now.add(const Duration(days: 1));
      startTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 19, 0);
      title = title.replaceAll('yarın akşam', '').trim();
    } else if (text.contains('yarın')) {
      final tomorrow = now.add(const Duration(days: 1));
      startTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      title = title.replaceAll('yarın', '').trim();
    } else if (text.contains('bu akşam')) {
      startTime = DateTime(now.year, now.month, now.day, 19, 0);
      title = title.replaceAll('bu akşam', '').trim();
    } else if (text.contains('bugün')) {
      startTime = DateTime(now.year, now.month, now.day);
      title = title.replaceAll('bugün', '').trim();
    }

    final days = {
      'pazartesi': 1,
      'salı': 2,
      'çarşamba': 3,
      'perşembe': 4,
      'cuma': 5,
      'cumartesi': 6,
      'pazar': 7
    };
    for (var entry in days.entries) {
      if (text.contains(entry.key)) {
        int diff = entry.value - now.weekday;
        if (diff <= 0) diff += 7;
        final target = now.add(Duration(days: diff));
        startTime = DateTime(target.year, target.month, target.day);
        title = title.replaceAll(entry.key, '').trim();
        break;
      }
    }

    final timeReg = RegExp(r'(\d{1,2})[:.](\d{2})');
    final match = timeReg.firstMatch(text);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      startTime ??= DateTime(now.year, now.month, now.day);
      startTime = DateTime(
          startTime.year, startTime.month, startTime.day, hour, minute);
      title = title.replaceAll(match.group(0)!, '').trim();
    } else {
      final simpleTimeReg = RegExp(r'saat\s*(\d{1,2})');
      final simpleMatch = simpleTimeReg.firstMatch(text);
      if (simpleMatch != null) {
        int hour = int.parse(simpleMatch.group(1)!);
        startTime ??= DateTime(now.year, now.month, now.day);
        startTime =
            DateTime(startTime.year, startTime.month, startTime.day, hour, 0);
        title = title.replaceAll(simpleMatch.group(0)!, '').trim();
      }
    }

    if (startTime == null) return null;

    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (title.isEmpty) title = "Yeni Görev";

    return Task(
      userId: '',
      title: _capitalize(title),
      description: 'Deterministik olarak analiz edildi.',
      startTime: startTime,
      endTime: startTime.add(const Duration(hours: 1)),
      priority: 1,
      tags: [],
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Future<String> _buildUserContext() async {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName?.split(' ').first ?? 'Dostum';

    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final dayName = DateFormat('EEEE', 'tr').format(now);

    // Get today's tasks
    List<Task> todayTasks = [];
    try {
      final firebaseService = FirebaseService();
      final allTasks = await firebaseService.getAllUserTasksStream().first;
      todayTasks = allTasks.where((t) {
        return t.startTime.year == now.year &&
            t.startTime.month == now.month &&
            t.startTime.day == now.day &&
            !t.isCompleted;
      }).toList();
    } catch (e) {
      debugPrint("Nova RAG: Görevler çekilemedi: $e");
    }

    // Get teams
    String teamsContext = '';
    try {
      final teams = await FirebaseService().getUserTeamsStream().first;
      if (teams.isNotEmpty) {
        teamsContext = '\nYönetici/Üye Olunan Takımlar:\n';
        for (var t in teams) {
          teamsContext += '- Takım Kimliği (ID): ${t.id} | İsim: ${t.name}\n';
        }
      }
    } catch (e) {
      debugPrint("Nova RAG: Takımlar çekilemedi: $e");
    }

    // Get budget limits
    String budgetContext = '';
    try {
      final budgetService = BudgetService();
      final budgetData = await budgetService.getBudgetVsActual();
      final items = budgetData['items'] as List<dynamic>? ?? [];
      if (items.isNotEmpty) {
        budgetContext = '\nBu Ayki Bütçe Durumu:\n';
        for (var item in items) {
          final category = item['category'];
          final limit = item['limit'];
          final actual = item['actual'];
          budgetContext +=
              '- $category: $actual TL harcandı (Limit: $limit TL)\n';
        }
      }
    } catch (e) {
      debugPrint("Nova RAG: Bütçe çekilemedi: $e");
    }

    String tasksContext = todayTasks.isEmpty
        ? 'Bugün için planlanmış veya bekleyen bir görevi yok.'
        : 'Bugünkü Bekleyen Görevler:\n${todayTasks.map((t) => "- Görev Kimliği (ID): ${t.id} | ${t.title} (Saat: ${DateFormat('HH:mm').format(t.startTime)})").join('\n')}';

    return '''Senin adın Nova. Phobes uygulamasının yapay zeka yaşam koçu ve kişisel asistanısın. Türkçe konuşuyorsun.

[KULLANICI BİLGİSİ VE GİZLİ BAĞLAM]
Kullanıcının Adı: $userName
Şu Anki Zaman: ${dateFormat.format(now)} ($dayName)
$tasksContext
$teamsContext
$budgetContext

[KARAKTER VE KURALLAR]
- Çok zeki, samimi, doğrudan, motive edici ve hafif esprili konuş.
- Asla çok uzun paragraflar yazma, bilgiyi hap gibi madde madde veya kısa cümlelerle ver.
- Kullanıcının bugünkü görevlerini veya durumunu biliyorsun ancak o sana sormadıkça veya gerekmedikçe görevlerini yüzüne vurma. Sadece kendi arka plan bilgin olarak kullan.
- Konu açılırsa Phobes uygulamasının siyah zemin ve neon renklerinden (premium havasından) bahsedebilirsin.
- Sorunun bağlamına uygun olarak emojiler kullanmayı unutma.

[KRİTİK ARAÇ KULLANIM KURALLARI]
- Kullanıcı görev EKLEME, OLUŞTURMA, PLANLAMA istediğinde KESİNLİKLE create_task aracını çağır.
- Kullanıcı görev ERTELEME, TAŞIMA istediğinde KESİNLİKLE reschedule_task aracını çağır.
- Kullanıcı görev SİLME, İPTAL istediğinde KESİNLİKLE cancel_task aracını çağır.
- Kullanıcı görev DÜZENLEME, DEĞİŞTİRME istediğinde KESİNLİKLE update_task aracını çağır.
- Kullanıcı görev arama veya sorgulama istediğinde KESİNLİKLE find_task aracını çağır.
- Kullanıcı alt görev ekleme istediğinde KESİNLİKLE add_subtasks aracını çağır.
- Kullanıcı takıma mesaj/duyuru gönderme istediğinde KESİNLİKLE send_team_announcement aracını çağır.
- Kullanıcı bütçesine veya hesabına harcama/gider ekleme/düşme istediğinde KESİNLİKLE add_expense aracını çağır.
- Kullanıcı ilacını içtiğini, aldığını söylediğinde KESİNLİKLE mark_medication_taken aracını çağır.
- Tarih bilgisi verilmezse yarını, saat verilmezse 09:00 varsay. Tarihleri KESİNLİKLE YYYY-MM-DD, saatleri HH:MM formatında gönder.
- ASLA aracı çağırmadan bir işlem yaptığını iddia etme. Önce aracı çağır, sonra sonuca göre yanıt ver.
- KESİNLİKLE __PENDING_TASK__ veya __ADD_SUBTASKS__ gibi etiketleri kendin metin olarak yazma. Sadece araçları (functions) çağır. Sistem bu etiketleri ARAÇ ÇAĞRISI sonucunda otomatik üretecektir.
- Araç çağırdığında, kullanıcıya "Hazırladım, onaylıyor musun?" diye sormayı unutma. 🚀''';
  }

  Future<String?> chatWithNova(List<Map<String, String>> history) async {
    try {
      String systemContext = await _buildUserContext();

      List<Map<String, dynamic>> messages = [
        {"role": "system", "content": systemContext}
      ];

      for (var msg in history) {
        String role = msg['role'] == 'user' ? 'user' : 'assistant';
        messages.add({"role": role, "content": msg['text'] ?? ''});
      }

      final requestBody = {
        "model": _model,
        "messages": messages,
        "temperature": 0.9,
        "tools": [
          {
            "type": "function",
            "function": {
              "name": "create_task",
              "description":
                  "Kullanıcının takvimine veya planına yeni bir görev ekler.",
              "parameters": {
                "type": "object",
                "properties": {
                  "title": {
                    "type": "string",
                    "description":
                        "Görevin başlığı (örn: Spora git, Toplantı yap)"
                  },
                  "date": {
                    "type": "string",
                    "description":
                        "Görev tarihi (KESİNLİKLE YYYY-MM-DD formatında olmalı)"
                  },
                  "time": {
                    "type": "string",
                    "description":
                        "Görev saati (KESİNLİKLE HH:MM formatında olmalı)"
                  }
                },
                "required": ["title", "date", "time"]
              }
            }
          },
          {
            "type": "function",
            "function": {
              "name": "reschedule_task",
              "description":
                  "Gizli bağlamda Kimliği (ID) numarası verilen bir görevi, kullanıcının istediği başka bir tarih ve saate erteler.",
              "parameters": {
                "type": "object",
                "properties": {
                  "task_id": {
                    "type": "string",
                    "description": "Görevin ID'si (Örn: JgX9...)"
                  },
                  "date": {
                    "type": "string",
                    "description": "Yeni tarih (YYYY-MM-DD)"
                  },
                  "time": {"type": "string", "description": "Yeni saat (HH:MM)"}
                },
                "required": ["task_id", "date", "time"]
              }
            }
          },
          {
            "type": "function",
            "function": {
              "name": "cancel_task",
              "description":
                  "Gizli bağlamda Kimliği (ID) numarası verilen bir görevi takvimden siler (iptal eder).",
              "parameters": {
                "type": "object",
                "properties": {
                  "task_id": {
                    "type": "string",
                    "description": "Silinecek Görevin ID'si"
                  }
                },
                "required": ["task_id"]
              }
            }
          },
          {
            "type": "function",
            "function": {
              "name": "send_team_announcement",
              "description":
                  "Gizli bağlamda Kimliği (ID) verilen bir takıma yüksek öncelikli bir duyuru, tavsiye veya mesaj gönderir.",
              "parameters": {
                "type": "object",
                "properties": {
                  "team_id": {
                    "type": "string",
                    "description": "Takımın Kimliği (ID)"
                  },
                  "message": {
                    "type": "string",
                    "description": "Gönderilecek duyuru mesajı metni"
                  }
                },
                "required": ["team_id", "message"]
              }
            }
          },
          {
            "type": "function",
            "function": {
              "name": "add_subtasks",
              "description":
                  "Belirtilen Görev Kimliği (ID)'sine sahip görevin açıklamasına alt görev maddeleri (markdown checklist) ekler.",
              "parameters": {
                "type": "object",
                "properties": {
                  "task_id": {"type": "string", "description": "Görevin ID'si"},
                  "subtasks": {
                    "type": "array",
                    "items": {"type": "string"},
                    "description": "Eklenecek alt görevlerin listesi"
                  }
                },
                "required": ["task_id", "subtasks"]
              }
            }
          },
          {
            "type": "function",
            "function": {
              "name": "update_task",
              "description":
                  "Görev Kimliği (ID)'si verilen bir görevin başlığını, açıklamasını, tarihini veya saatini günceller. Sadece değişecek alanlar doldurulmalıdır.",
              "parameters": {
                "type": "object",
                "properties": {
                  "task_id": {
                    "type": "string",
                    "description": "Değiştirilecek görevin ID'si"
                  },
                  "title": {
                    "type": "string",
                    "description": "(İsteğe bağlı) Yeni başlık"
                  },
                  "description": {
                    "type": "string",
                    "description": "(İsteğe bağlı) Açıklamaya EKLENECEK metin"
                  },
                  "date": {
                    "type": "string",
                    "description": "(İsteğe bağlı) Yeni tarih (YYYY-MM-DD)"
                  },
                  "time": {
                    "type": "string",
                    "description": "(İsteğe bağlı) Yeni başlangıç saati (HH:MM)"
                  }
                },
                "required": ["task_id"]
              }
            }
          },
          {
            "type": "function",
            "function": {
              "name": "find_task",
              "description":
                  "Bağlamda ID'si bulunmayan genel bir görevi aratmak ve kullanıcıya özel bir görev kartı çizdirmek için kullanılır.",
              "parameters": {
                "type": "object",
                "properties": {
                  "keyword": {
                    "type": "string",
                    "description":
                        "Görevin isminde geçen kelime veya arama terimi"
                  }
                },
                "required": ["keyword"]
              }
            }
          },
          {
            "type": "function",
            "function": {
              "name": "add_expense",
              "description": "Kullanıcının bütçesine yeni bir harcama/gider ekler.",
              "parameters": {
                "type": "object",
                "properties": {
                  "title": {"type": "string", "description": "Harcamanın konusu (örn: Market, Kahve, Sinema)"},
                  "amount": {"type": "number", "description": "Harcama tutarı/miktarı (sayısal, örn: 150.5)"},
                  "category": {"type": "string", "description": "Harcama kategorisi (Market, Yemek, Eğitim, Sağlık, Fatura vs.)"}
                },
                "required": ["title", "amount", "category"]
              }
            }
          },
          {
            "type": "function",
            "function": {
              "name": "mark_medication_taken",
              "description": "Kullanıcının ilaç içtiğini/aldığını kaydeder.",
              "parameters": {
                "type": "object",
                "properties": {
                  "medication_name": {"type": "string", "description": "İlacın adı (örn: Parol, Aspirin)"},
                  "time": {"type": "string", "description": "İlacın alındığı saat (HH:MM)"}
                },
                "required": ["medication_name", "time"]
              }
            }
          }
        ],
        "tool_choice": "auto"
      };

      final apiKey = await _fetchApiKey();
      if (apiKey == null) return null;

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choice = data['choices']?[0];
        if (choice != null) {
          final message = choice['message'];
          List<dynamic> toolCalls = message['tool_calls'] ?? [];

          // Fallback parsing for hallucinated raw text function calls (e.g. from Gemini)
          if (toolCalls.isEmpty && message['content'] != null) {
            final String contentStr = message['content'];
            final RegExp fallbackRegExp = RegExp(
                r'=?function=([a-zA-Z_]+)>({.*?})(?:</function>|$)',
                dotAll: true);
            final matches = fallbackRegExp.allMatches(contentStr);
            if (matches.isNotEmpty) {
              for (var m in matches) {
                toolCalls.add({
                  'function': {'name': m.group(1), 'arguments': m.group(2)}
                });
              }
            }
          }

          if (toolCalls.isNotEmpty) {
            String finalResponse = '';

            for (var toolCall in toolCalls) {
              final functionName = toolCall['function']['name'];
              final args = jsonDecode(toolCall['function']['arguments']);

              if (functionName == 'create_task') {
                try {
                  final String title = args['title'] ?? 'Yeni Görev';
                  final String dateStr = args['date'] ??
                      DateFormat('yyyy-MM-dd').format(DateTime.now());
                  final String timeStr = args['time'] ?? '09:00';

                  debugPrint(
                      'Nova create_task: title=$title, date=$dateStr, time=$timeStr');

                  DateTime start = _parseDateTime(dateStr, timeStr);
                  DateTime end = start.add(const Duration(hours: 1));

                  final tasks =
                      await FirebaseService().getAllUserTasksStream().first;
                  final overlap = TimeUtils.getOverlappingTask(start, end, tasks);
                  String overlapWarning = '';

                  if (overlap != null) {
                    final freeSlots = TimeUtils.getFreeSlots(start, tasks);
                    overlapWarning =
                        'Dikkat patron! O saatlerde "${overlap.title}" görevin var. Boş vakitlerin şunlar:\n${freeSlots.join('\n')}\nYine de eklememi istersen diye onaya sundum.\n\n';
                  }

                  final String pendingId =
                      DateTime.now().millisecondsSinceEpoch.toString();
                  final Map<String, dynamic> taskJson = {
                    'id': pendingId,
                    'title': _capitalize(title),
                    'date': DateFormat('yyyy-MM-dd').format(start),
                    'time': DateFormat('HH:mm').format(start),
                  };

                  debugPrint(
                      'Nova create_task: Görev onaya sunuldu (ID: $pendingId)');

                  String jsonStr = jsonEncode(taskJson);
                  finalResponse += '${overlapWarning}__PENDING_TASK__:$jsonStr\nDetayları senin için hazırladım. Lütfen onay ver patron! 👇\n';
                } catch (e) {
                  debugPrint('Nova create_task HATA: $e');
                  finalResponse +=
                      'Görevi eklemek istedim ama bir hata oluştu: $e 😔 Lütfen tekrar dener misin?\n';
                }
              } else if (functionName == 'reschedule_task') {
                try {
                  final String taskId = args['task_id'];
                  final String dateStr = args['date'];
                  final String timeStr = args['time'];

                  DateTime newStart = DateTime.parse('$dateStr $timeStr');

                  final doc = await FirebaseFirestore.instance
                      .collection('tasks')
                      .doc(taskId)
                      .get();
                  if (doc.exists) {
                    final taskData = Task.fromFirestore(doc);
                    final newEnd = newStart.add(
                        taskData.endTime.difference(taskData.startTime));

                    final tasks = await FirebaseService()
                        .getAllUserTasksStream()
                        .first;
                    final otherTasks =
                        tasks.where((t) => t.id != taskId).toList();

                    final overlap = TimeUtils.getOverlappingTask(
                        newStart, newEnd, otherTasks);

                    if (overlap != null) {
                      final freeSlots =
                          TimeUtils.getFreeSlots(newStart, otherTasks);
                      finalResponse +=
                          'Dostum, görevi oraya taşıyamıyorum çünkü "${overlap.title}" ile çakışıyor. O günkü boş vakitlerin şunlar:\n${freeSlots.join('\n')}\nFarklı bir saate taşıyayım mı?\n';
                    } else {
                      final updatedTask = taskData.copyWith(
                          startTime: newStart,
                          endTime: newEnd,
                          postponeCount: taskData.postponeCount + 1);
                      await FirebaseService().updateTask(updatedTask);
                      finalResponse +=
                          'İstediğin görevi başarıyla $dateStr $timeStr tarihine erteledim. Başka bir arzun? ⏳\n';
                    }
                  } else {
                    finalResponse +=
                        'Görevi bulamadım, belki daha önce tamamladın veya sildin.\n';
                  }
                } catch (e) {
                  debugPrint("Nova Reschedule Tool Hatası: $e");
                  finalResponse += 'Erteleme sırasında bir hata oluştu.\n';
                }
              } else if (functionName == 'cancel_task') {
                try {
                  final String taskId = args['task_id'];
                  await FirebaseService().deleteTask(taskId);
                  finalResponse +=
                      'İlgili görevi sildim, patron. Zaten o kadar da önemli değildi bence! 🗑️\n';
                } catch (e) {
                  debugPrint("Nova Cancel Tool Hatası: $e");
                  finalResponse +=
                      'Görev silinirken bir hata ile karşılaştım.\n';
                }
              } else if (functionName == 'send_team_announcement') {
                try {
                  final String teamId = args['team_id'];
                  final String teamMessage = args['message'];
                  
                  final String pendingId = DateTime.now().millisecondsSinceEpoch.toString();
                  final Map<String, dynamic> reqJson = {
                    'id': pendingId,
                    'team_id': teamId,
                    'message': teamMessage,
                  };
                  
                  String jsonStr = jsonEncode(reqJson);
                  finalResponse += '__PENDING_ANNOUNCEMENT__:$jsonStr\nDuyuruyu hazırladım. Takıma göndermek için lütfen onay ver! 📢\n';
                } catch (e) {
                  debugPrint("Nova Team Announcement Tool Hatası: $e");
                  finalResponse +=
                      'Takıma duyuru atarken sorun yaşadım, bağlantını kontrol et.\n';
                }
              } else if (functionName == 'add_subtasks') {
                try {
                  final String taskId = args['task_id'];
                  final List<dynamic> subtasks = args['subtasks'];
                  
                  final String pendingId = DateTime.now().millisecondsSinceEpoch.toString();
                  final Map<String, dynamic> reqJson = {
                    'id': pendingId,
                    'task_id': taskId,
                    'subtasks': subtasks,
                  };

                  String jsonStr = jsonEncode(reqJson);
                  finalResponse += '__PENDING_SUBTASKS__:$jsonStr\nAlt görevleri çıkardım. Görevin detaylarına eklememi onaylıyor musun? ☑️\n';
                } catch (e) {
                  debugPrint("Nova Add Subtasks Tool Hatası: $e");
                  finalResponse += 'Alt görevler ayrıştırılırken sorun oluştu.\n';
                }
              } else if (functionName == 'add_expense') {
                try {
                  final String title = args['title'];
                  final double amount = (args['amount'] as num).toDouble();
                  final String category = args['category'];
                  
                  final String pendingId = DateTime.now().millisecondsSinceEpoch.toString();
                  final Map<String, dynamic> reqJson = {
                    'id': pendingId,
                    'title': title,
                    'amount': amount,
                    'category': category
                  };

                  String jsonStr = jsonEncode(reqJson);
                  finalResponse += '__PENDING_EXPENSE__:$jsonStr\nHarcamayı kaydetmek üzereyim. Girdiğim tutarı doğrulayıp onay verir misin? 💸\n';
                } catch (e) {
                  debugPrint("Nova Add Expense Tool Hatası: $e");
                  finalResponse += 'Harcama işlenirken bir sorun oluştu.\n';
                }
              } else if (functionName == 'mark_medication_taken') {
                try {
                  final String medicationName = args['medication_name'];
                  final String timeStr = args['time'] ?? DateFormat('HH:mm').format(DateTime.now());
                  
                  final String pendingId = DateTime.now().millisecondsSinceEpoch.toString();
                  final Map<String, dynamic> reqJson = {
                    'id': pendingId,
                    'medication_name': medicationName,
                    'time': timeStr
                  };

                  String jsonStr = jsonEncode(reqJson);
                  finalResponse += '__PENDING_MEDICATION__:$jsonStr\nSüpersin, ilacını aksatmaman harika! Sisteme işlemem için onayla yeter. 💊\n';
                } catch (e) {
                  debugPrint("Nova Medication Tool Hatası: $e");
                  finalResponse += 'İlaç bilgisi işlenemedi.\n';
                }
              } else if (functionName == 'update_task') {
                try {
                  final String taskId = args['task_id'];
                  final String? title = args['title'];
                  final String? descriptionAdd = args['description'];
                  final String? dateStr = args['date'];
                  final String? timeStr = args['time'];

                  final doc = await FirebaseFirestore.instance
                      .collection('tasks')
                      .doc(taskId)
                      .get();
                  if (doc.exists) {
                    final taskData = Task.fromFirestore(doc);
                    DateTime currentStart = taskData.startTime;

                    // Sadece gelen verileri güncelle
                    DateTime newStart = currentStart;
                    if (dateStr != null || timeStr != null) {
                      String ymd = dateStr ??
                          DateFormat('yyyy-MM-dd').format(currentStart);
                      String hm =
                          timeStr ?? DateFormat('HH:mm').format(currentStart);
                      newStart = DateTime.tryParse('$ymd $hm') ?? currentStart;
                    }

                    String newDesc = taskData.description;
                    if (descriptionAdd != null && descriptionAdd.isNotEmpty) {
                      newDesc +=
                          (newDesc.isNotEmpty ? '\n' : '') + descriptionAdd;
                    }

                    final updatedTask = taskData.copyWith(
                        title: title ?? taskData.title,
                        description: newDesc,
                        startTime: newStart,
                        endTime: newStart.add(
                            taskData.endTime.difference(taskData.startTime)));

                    await FirebaseService().updateTask(updatedTask);
                    finalResponse +=
                        'Görevin istediğin kısımlarını başarıyla düzenledim patron! ✏️\n';
                  } else {
                    finalResponse +=
                        'O ID ile bir görev bulamadığım için güncelleyemedim.\n';
                  }
                } catch (e) {
                  debugPrint("Nova Update Tool Hatası: $e");
                  finalResponse += 'Düzenleme yaparken bir sorun çıktı.\n';
                }
              } else if (functionName == 'find_task') {
                try {
                  final String keyword =
                      args['keyword']?.toString().toLowerCase() ?? '';
                  final allTasks =
                      await FirebaseService().getAllUserTasksStream().first;

                  final matches = allTasks
                      .where((t) => t.title.toLowerCase().contains(keyword))
                      .toList();

                  if (matches.isNotEmpty) {
                    Task found = matches.first;
                    final formattedDate =
                        DateFormat('dd MMM yyyy HH:mm').format(found.startTime);
                    // Özel etiket: __TASK_CARD__:id|başlık|tarih
                    finalResponse +=
                        '__TASK_CARD__:${found.id}|${found.title}|$formattedDate\nİşte aradığın görevi buldum! Üzerine tıklayarak detayına gidebilirsin. Neresini düzenlememi istersin?\n';
                  } else {
                    finalResponse +=
                        'Maalesef "$keyword" kelimesini içeren bir görev bulamadım.\n';
                  }
                } catch (e) {
                  debugPrint("Nova Find Tool Hatası: $e");
                  finalResponse += 'Görev araması yaparken bir hata oluştu.\n';
                }
              }
            }
            return finalResponse.trim();
          }
          return message['content'];
        }
      } else {
        debugPrint(
            "Nova API Hata (chatWithNova): ${response.statusCode} - ${response.body}");
      }
      return null;
    } catch (e) {
      debugPrint("Chat Hata: $e");
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

  Future<String?> analyzeBurnout(String statsSummary) async {
    final prompt = '''
    İSTATİSTİKLER:
    $statsSummary
    Bu kullanıcının "Tükenmişlik (Burnout)" riskini yorumla ve samimi, kısa bir sağlık tavsiyesi ver. Emoji kullan.
    ''';
    return await _sendRequest(prompt, temperature: 0.7);
  }

  Future<String?> getDailyBriefing(List<Task> tasks, String userName) async {
    if (tasks.isEmpty) {
      return "Merhaba $userName! Bugün boşsun, keyfine bak! 🌟";
    }
    String list = tasks.map((t) => "- ${t.title}").join("\n");
    return await _sendRequest(
        "Kullanıcı: $userName. Görevler:\n$list\nKısa, motive edici günaydın mesajı yaz.",
        temperature: 0.8);
  }

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

  Future<String?> getTaskMotivation(String taskTitle) async {
    final prompt =
        'Görevin adı: "$taskTitle". Bu görevi yapan kişiye "Harikasın, bitirdin!" temalı kısa, esprili ve gaza getirici tek cümlelik bir tebrik sözü yaz.';
    return await _sendRequest(prompt, temperature: 1.0);
  }

  Future<String?> _sendRequest(String prompt,
      {double temperature = 0.7}) async {
    try {
      final apiKey = await _fetchApiKey();
      if (apiKey == null) return null;

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": _model,
          "messages": [
            {"role": "user", "content": prompt}
          ],
          "temperature": temperature
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices']?[0]['message']['content'];
      } else {
        debugPrint(
            "Nova API Hata (_sendRequest): ${response.statusCode} - ${response.body}");
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

    start = clean.indexOf('[');
    end = clean.lastIndexOf(']');
    if (start != -1 && end != -1) return clean.substring(start, end + 1);

    return clean;
  }

  /// LLM'den gelen çeşitli tarih yapılarını (YYYY-MM-DD, DD/MM/YYYY, etc.)
  /// ve saat kombinasyonlarını ayrıştırır. Hata olursa yarın 09:00 döndürür.
  DateTime _parseDateTime(String dateStr, String timeStr) {
    try {
      // Önce standart birleştirme dene (YYYY-MM-DD HH:mm)
      return DateTime.parse('$dateStr $timeStr');
    } catch (_) {
      try {
        // Eğer LLM T ile gönderirse (YYYY-MM-DDTHH:mm)
        if (dateStr.contains('T')) {
          return DateTime.parse(dateStr);
        }
        
        // Türkçe/Avrupa formatı gelirse (DD.MM.YYYY veya DD/MM/YYYY)
        String standardizedDate = dateStr.replaceAll('.', '-').replaceAll('/', '-');
        final parts = standardizedDate.split('-');
        
        if (parts.length == 3) {
          int? year, month, day;
          
          if (parts[0].length == 4) {
            year = int.tryParse(parts[0]);
            month = int.tryParse(parts[1]);
            day = int.tryParse(parts[2]);
          } else if (parts[2].length == 4) {
            day = int.tryParse(parts[0]);
            month = int.tryParse(parts[1]);
            year = int.tryParse(parts[2]);
          }
          
          if (year != null && month != null && day != null) {
            final timeParts = timeStr.split(':');
            int hour = 9;
            int minute = 0;
            if (timeParts.isNotEmpty) hour = int.tryParse(timeParts[0]) ?? 9;
            if (timeParts.length > 1) minute = int.tryParse(timeParts[1]) ?? 0;
            
            return DateTime(year, month, day, hour, minute);
          }
        }
        
        // Hiçbiri tutmazsa yarın 09:00 varsay
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
      } catch (e) {
        debugPrint('Tarih ayrıştırma hatası: $e (date: $dateStr, time: $timeStr)');
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
      }
    }
  }
}
