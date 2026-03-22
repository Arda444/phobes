import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../services/nova_service.dart';
import '../../services/firebase_service.dart';
import '../../core/phobes_theme.dart';
import '../../widgets/phobes_widgets.dart';
import '../tasks/task_detail_screen.dart';
import '../../models/task_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../../services/budget_service.dart';
import '../../models/budget_model.dart';

class NovaChatScreen extends StatefulWidget {
  const NovaChatScreen({super.key});

  @override
  State<NovaChatScreen> createState() => _NovaChatScreenState();
}

class _NovaChatScreenState extends State<NovaChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final NovaService _novaService = NovaService();
  final FirebaseService _firebaseService = FirebaseService();
  final FocusNode _focusNode = FocusNode();

  final List<Map<String, String>> _messages = [];
  final Set<String> _approvedTasks = {};
  final Set<String> _rejectedTasks = {};
  bool _isLoading = false;

  final stt.SpeechToText _speechToText = stt.SpeechToText();

  bool _isListening = false;
  bool _isSpeechEnabled = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadDailyBriefing();
  }

  Future<void> _initSpeech() async {
    _isSpeechEnabled = await _speechToText.initialize(
      onError: (val) => debugPrint('STT Error: $val'),
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
  }

  void _listenToggle() async {
    if (!_isListening) {
      if (_isSpeechEnabled) {
        setState(() => _isListening = true);
        await _speechToText.listen(
          onResult: (val) {
            setState(() {
              _controller.text = val.recognizedWords;
            });
          },
          localeId: 'tr_TR',
        );
      } else {
        _isSpeechEnabled = await _speechToText.initialize();
        if (_isSpeechEnabled) _listenToggle();
      }
    } else {
      setState(() => _isListening = false);
      await _speechToText.stop();
      if (_controller.text.trim().isNotEmpty) {
        _sendMessage();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadDailyBriefing() async {
    setState(() => _isLoading = true);

    try {
      final allTasks = await _firebaseService.getAllUserTasksStream().first;
      final today = DateTime.now();

      final todayTasks = allTasks.where((t) {
        return t.startTime.year == today.year &&
            t.startTime.month == today.month &&
            t.startTime.day == today.day;
      }).toList();

      final user = _firebaseService.currentUser;
      final name = user?.displayName?.split(' ')[0] ?? "Dostum";

      final briefing = await _novaService.getDailyBriefing(todayTasks, name);

      if (mounted) {
        if (briefing != null) {
          _addMessage('model', briefing);
        } else {
          String msg =
              "Merhaba $name! Ben Nova. Bugün sana nasıl yardımcı olabilirim?";
          _addMessage('model', msg);
        }
      }
    } catch (e) {
      if (mounted) {
        _addMessage('model',
            "Selam! Bağlantıları kontrol ediyorum... Bugün neler yapalım?");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addMessage(String role, String text) {
    setState(() {
      _messages.add({'role': role, 'text': text});
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: PhobesTheme.animNormal,
          curve: PhobesTheme.curveDefault,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    _addMessage('user', text);

    setState(() => _isLoading = true);

    final history = _messages.length > 10
        ? _messages.sublist(_messages.length - 10)
        : _messages;

    final response = await _novaService.chatWithNova(history);

    if (mounted) {
      setState(() => _isLoading = false);
      if (response != null) {
        _addMessage('model', response);
      } else {
        String errMsg = "Bağlantıda bir sorun oldu, tekrar dener misin?";
        _addMessage('model', errMsg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmoled = PhobesTheme.amoledMode.value;

    return Scaffold(
      backgroundColor: isAmoled && isDark ? Colors.black : cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildPremiumHeader(),
            Expanded(
              child: _messages.isEmpty && _isLoading
                  ? _buildInitialLoading()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _messages.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length && _isLoading) {
                          return _buildTypingIndicator();
                        }
                        return _buildMessageBubble(_messages[index], index);
                      },
                    ),
            ),
            _buildPremiumInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 48, 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: PhobesTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(Icons.auto_awesome, color: cs.onPrimary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Nova AI",
                  style: GoogleFonts.outfit(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Çevrimiçi",
                      style: GoogleFonts.outfit(
                        color: cs.onSurface.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PhobesIconButton(
            icon: Icons.help_outline_rounded,
            onTap: () => _showNovaGuide(context),
          ),
          const SizedBox(width: 8),
          const SizedBox(width: 8),
          PhobesIconButton(
            icon: Icons.more_vert_rounded,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _showNovaGuide(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: PhobesGlassCard(
              padding: const EdgeInsets.all(24),
              borderRadius: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: PhobesTheme.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Nova Kullanım Kılavuzu",
                              style: GoogleFonts.outfit(
                                color: cs.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              "Nova neler yapabilir?",
                              style: GoogleFonts.outfit(
                                color: cs.onSurface.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildGuideItem(
                              Icons.add_task_rounded,
                              "Görev Oluşturma",
                              '"Yarın sabah 8\'e spor görevi ekle"'),
                          _buildGuideItem(
                              Icons.edit_calendar_rounded,
                              "Tam Yetkili Düzenleme",
                              '"Spor görevimi Cuma 15:00\'e ertele", "Görevimin başlığını yürüyüş yap" veya "Açıklamasına su almayı ekle"'),
                          _buildGuideItem(
                              Icons.delete_sweep_rounded,
                              "Görev İptali",
                              '"Projeyi bitir görevini sil, vazgeçtim"'),
                          _buildGuideItem(
                              Icons.search_rounded,
                              "Görev Arama & Kart (UI)",
                              '"Bana yürüyüş görevimi bul" (Tıklanabilir kart çizer)'),
                          _buildGuideItem(
                              Icons.account_tree_rounded,
                              "Alt Görev Parçalama",
                              '"Şu görevime e-posta yazma ve sunum yapma alt görevlerini ekle"'),
                          _buildGuideItem(Icons.groups_rounded, "Pano Duyurusu",
                              '"Yazılım takımı panosuna yarın toplantı var diye duyuru geç"'),
                          _buildGuideItem(Icons.mic_rounded, "Jarvis Modu",
                              'Klavyenin yanındaki mikrofonla sesli komut verebilirsiniz.'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PhobesTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text("Anladım",
                          style: GoogleFonts.outfit(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildGuideItem(IconData icon, String title, String description) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                      fontSize: 14)),
              const SizedBox(height: 2),
              Text(description,
                  style: GoogleFonts.outfit(
                      color: cs.onSurface.withValues(alpha: 0.7),
                      fontSize: 13,
                      height: 1.4)),
            ],
          ))
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, String> msg, int index) {
    final isUser = msg['role'] == 'user';
    String text = msg['text']!;

    bool hasTaskCard = false;
    String? taskId;
    String? taskTitle;
    String? taskDate;
    
    bool isPending = false;
    String? foundPendingType;
    Map<String, dynamic>? pendingData;
    
    String displayMessage = text;

    if (!isUser && text.contains('__TASK_CARD__:')) {
      hasTaskCard = true;
      final parts = text.split('__TASK_CARD__:');
      final beforeCard = parts[0];
      final afterCardPart = parts[1];

      final newLineIdx = afterCardPart.indexOf('\n');
      String cardData = afterCardPart;
      String afterText = '';
      if (newLineIdx != -1) {
        cardData = afterCardPart.substring(0, newLineIdx);
        afterText = afterCardPart.substring(newLineIdx + 1);
      }

      final cardParts = cardData.split('|');
      if (cardParts.length >= 3) {
        taskId = cardParts[0];
        taskTitle = cardParts[1];
        taskDate = cardParts[2];
      }

      displayMessage = beforeCard.trim() +
          (beforeCard.trim().isNotEmpty && afterText.trim().isNotEmpty
              ? '\n\n'
              : '') +
          afterText.trim();
    } else if (!isUser) {
      final pendingTypes = [
        '__PENDING_TASK__',
        '__PENDING_EXPENSE__',
        '__PENDING_MEDICATION__',
        '__PENDING_SUBTASKS__',
        '__ADD_SUBTASKS__',
        '__PENDING_ANNOUNCEMENT__'
      ];

      for (var pType in pendingTypes) {
        if (text.contains(pType)) {
          isPending = true;
          foundPendingType = pType;
          break;
        }
      }

      if (isPending && foundPendingType != null) {
        // Find where the JSON starts
        final startIndex = text.indexOf(foundPendingType);
        final beforeCard = text.substring(0, startIndex);
        final afterTag = text.substring(startIndex + foundPendingType.length);
        
        // Find the first '{' after the tag
        final jsonStartIdx = afterTag.indexOf('{');
        if (jsonStartIdx != -1) {
          String cardData = afterTag.substring(jsonStartIdx);
          String afterText = '';
          
          // Find the last '}'
          final lastBraceIdx = cardData.lastIndexOf('}');
          if (lastBraceIdx != -1) {
            afterText = cardData.substring(lastBraceIdx + 1);
            cardData = cardData.substring(0, lastBraceIdx + 1);
          }

          try {
            pendingData = jsonDecode(cardData.trim());
          } catch (e) {
            debugPrint('JSON ayrıştırma hatası ($foundPendingType): $e');
            // Try lenient parsing if it has extra underscores or colons
            final cleanData = cardData.replaceAll(RegExp(r'^[:_]+'), '').trim();
             try {
               pendingData = jsonDecode(cleanData);
             } catch (_) {}
          }

          displayMessage = beforeCard.trim() +
              (beforeCard.trim().isNotEmpty && afterText.trim().isNotEmpty
                  ? '\n\n'
                  : '') +
              afterText.trim();
        }
      }
    }

    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      delay: Duration(milliseconds: index < 3 ? index * 100 : 0),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment:
                  isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isUser) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: PhobesTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                ],
                if (displayMessage.isNotEmpty)
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isUser ? PhobesTheme.secondaryGradient : null,
                      color: isUser ? null : PhobesTheme.surfaceColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isUser ? 20 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 20),
                      ),
                      border: isUser
                          ? null
                          : Border.all(
                              color: Colors.white.withValues(alpha: 0.08)),
                      boxShadow: isUser
                          ? [
                              BoxShadow(
                                color: PhobesTheme.secondaryColor
                                    .withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      displayMessage,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                if (isUser) const SizedBox(width: 8),
              ],
            ),
            if (hasTaskCard && taskId != null)
              _buildTaskCard(taskId, taskTitle ?? 'Görev', taskDate ?? ''),
            if (isPending && pendingData != null) ...[
              if (foundPendingType == '__PENDING_TASK__')
                _buildApprovalCard(pendingData),
              if (foundPendingType == '__PENDING_EXPENSE__')
                _buildExpenseApprovalCard(pendingData),
              if (foundPendingType == '__PENDING_MEDICATION__')
                _buildMedicationApprovalCard(pendingData),
              if (foundPendingType == '__PENDING_SUBTASKS__' || foundPendingType == '__ADD_SUBTASKS__')
                _buildSubtasksApprovalCard(pendingData),
              if (foundPendingType == '__PENDING_ANNOUNCEMENT__')
                _buildAnnouncementApprovalCard(pendingData),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGenericApprovalCard({
    required String id,
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) {
    final isApproved = _approvedTasks.contains(id);
    final isRejected = _rejectedTasks.contains(id);

    if (isApproved || isRejected) {
      return Container(
        margin: const EdgeInsets.only(top: 8, left: 40),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isApproved ? Colors.green.withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isApproved ? Colors.green.withValues(alpha: 0.3) : Colors.redAccent.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isApproved ? Colors.green : Colors.redAccent, size: 20),
            const SizedBox(width: 8),
            Text(isApproved ? 'Onaylandı' : 'İptal Edildi',
                style: GoogleFonts.outfit(color: isApproved ? Colors.green : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8, left: 40),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      child: PhobesGlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PhobesButton(
                    text: 'İptal',
                    onPressed: onReject,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PhobesButton(
                    text: 'Onayla',
                    onPressed: onApprove,
                    backgroundColor: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalCard(Map<String, dynamic> data) {
    return _buildGenericApprovalCard(
      id: data['id'], title: "Yeni Görev", icon: Icons.task_alt, color: PhobesTheme.primaryColor,
      children: [
        _buildApprovalRow('Görev', data['title'] ?? ''),
        _buildApprovalRow('Tarih', data['date'] ?? ''),
        _buildApprovalRow('Saat', data['time'] ?? ''),
      ],
      onApprove: () => _approvePendingTask(data), onReject: () => setState(() => _rejectedTasks.add(data['id'])),
    );
  }

  Widget _buildExpenseApprovalCard(Map<String, dynamic> data) {
    return _buildGenericApprovalCard(
      id: data['id'], title: "Harcama Ekle", icon: Icons.account_balance_wallet_rounded, color: Colors.orangeAccent,
      children: [
        _buildApprovalRow('Açıklama', data['title'] ?? ''),
        _buildApprovalRow('Tutar', "${data['amount']} TL"),
        _buildApprovalRow('Kategori', data['category'] ?? ''),
      ],
      onApprove: () => _approveExpense(data), onReject: () => setState(() => _rejectedTasks.add(data['id'])),
    );
  }

  Widget _buildMedicationApprovalCard(Map<String, dynamic> data) {
    return _buildGenericApprovalCard(
      id: data['id'], title: "İlaç Kaydı", icon: Icons.medication_rounded, color: Colors.greenAccent,
      children: [
        _buildApprovalRow('İlaç Adı', data['medication_name'] ?? ''),
        _buildApprovalRow('Saat', data['time'] ?? ''),
      ],
      onApprove: () => _approveMedication(data), onReject: () => setState(() => _rejectedTasks.add(data['id'])),
    );
  }

  Widget _buildSubtasksApprovalCard(Map<String, dynamic> data) {
    List<dynamic> st = data['subtasks'] ?? [];
    return _buildGenericApprovalCard(
      id: data['id'], title: "Alt Görevler", icon: Icons.checklist_rounded, color: Colors.amberAccent,
      children: [
        for (var s in st)
          Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.arrow_right_rounded, color: Colors.white54, size: 16),
            Expanded(child: Text(s.toString(), style: GoogleFonts.outfit(color: Colors.white, fontSize: 13))),
          ])),
      ],
      onApprove: () => _approveSubtasks(data), onReject: () => setState(() => _rejectedTasks.add(data['id'])),
    );
  }

  Widget _buildAnnouncementApprovalCard(Map<String, dynamic> data) {
    return _buildGenericApprovalCard(
      id: data['id'], title: "Takım Duyurusu", icon: Icons.campaign_rounded, color: Colors.purpleAccent,
      children: [
        Text(data['message'] ?? '', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, height: 1.4)),
      ],
      onApprove: () => _approveAnnouncement(data), onReject: () => setState(() => _rejectedTasks.add(data['id'])),
    );
  }

  Future<void> _approvePendingTask(Map<String, dynamic> data) async {
    final String id = data['id'];
    setState(() => _isLoading = true);
    try {
      final String dateStr = data['date'];
      final String timeStr = data['time'];
      DateTime start;
      try {
        start = DateTime.parse('$dateStr $timeStr');
      } catch (_) {
        start = DateTime.now().add(const Duration(hours: 1));
      }
      Task newTask = Task(
        userId: '', title: data['title'] ?? 'Yeni Görev', description: 'Nova tarafından oluşturuldu.',
        startTime: start, endTime: start.add(const Duration(hours: 1)), priority: 1, tags: ['Nova'], isAllDay: false,
      );
      await _firebaseService.addTask(newTask);
      if (mounted) setState(() => _approvedTasks.add(id));
      
    } catch (e) {
      debugPrint("Gorev onaylanirken hata: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveExpense(Map<String, dynamic> data) async {
    final String id = data['id'];
    setState(() => _isLoading = true);
    try {
      final budgetService = BudgetService();
      await budgetService.addTransaction(BudgetTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _firebaseService.currentUserId ?? 'unknown_user',
        amount: (data['amount'] as num).toDouble(),
        title: data['title'] ?? 'Harcama',
        category: data['category'] ?? 'Diğer',
        date: DateTime.now(),
        type: TransactionType.expense,
      ));
      if (mounted) setState(() => _approvedTasks.add(id));
      
    } catch (e) {
      debugPrint("Harcama onay hatasi: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveMedication(Map<String, dynamic> data) async {
    final String id = data['id'];
    setState(() => _isLoading = true);
    try {
      if (mounted) setState(() => _approvedTasks.add(id));
      
    } catch (e) {
      debugPrint("Ilac onay hatasi: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveSubtasks(Map<String, dynamic> data) async {
    final String id = data['id'];
    setState(() => _isLoading = true);
    try {
      final String taskId = data['task_id'];
      final List<dynamic> subtasks = data['subtasks'] ?? [];
      final doc = await FirebaseFirestore.instance.collection('tasks').doc(taskId).get();
      if (doc.exists) {
        final taskData = Task.fromFirestore(doc);
        final newSubtasks = List<SubTask>.from(taskData.subtasks);
        int index = 0;
        for (var st in subtasks) {
          newSubtasks.add(SubTask(
            id: '${DateTime.now().millisecondsSinceEpoch}_${index++}',
            title: st.toString(),
          ));
        }
        await _firebaseService.updateTask(taskData.copyWith(subtasks: newSubtasks));
        if (mounted) setState(() => _approvedTasks.add(id));
        
      }
    } catch (e) {
      debugPrint("Alt gorev onay hatasi: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveAnnouncement(Map<String, dynamic> data) async {
    final String id = data['id'];
    setState(() => _isLoading = true);
    try {
      final String teamId = data['team_id'];
      final String msg = data['message'];
      await _firebaseService.updateTeamAnnouncement(teamId, msg);
      if (mounted) setState(() => _approvedTasks.add(id));
      
    } catch (e) {
      debugPrint("Duyuru onay hatasi: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildApprovalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(String id, String title, String date) {
    return Container(
      margin: const EdgeInsets.only(top: 8, left: 40),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      child: GestureDetector(
        onTap: () async {
          // TaskDetailScreen'e git
          final doc = await FirebaseFirestore.instance
              .collection('tasks')
              .doc(id)
              .get();
          if (doc.exists && mounted) {
            final task = Task.fromFirestore(doc);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => TaskDetailScreen(task: task)));
          }
        },
        child: PhobesGlassCard(
          padding: const EdgeInsets.all(12),
          borderRadius: 16,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: PhobesTheme.primaryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.task_alt,
                    color: PhobesTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white54, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return FadeIn(
      child: Padding(
        padding: const EdgeInsets.only(left: 40, bottom: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: PhobesTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 600 + (index * 200)),
                    builder: (context, value, child) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(alpha: 0.3 + (value * 0.4)),
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: PhobesTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: PhobesTheme.primaryColor.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child:
                const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            "Nova hazırlanıyor...",
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumInputArea() {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          top: BorderSide(color: cs.outline.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: PhobesGlassCard(
              padding: EdgeInsets.zero,
              margin: EdgeInsets.zero,
              borderRadius: 24,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style:
                          GoogleFonts.outfit(color: cs.onSurface, fontSize: 14),
                      decoration: InputDecoration(
                        hintText:
                            "Dinliyor..." /*...veya "Nova'ya bir şey sor..." */,
                        hintStyle: GoogleFonts.outfit(
                            color: cs.onSurface.withValues(alpha: 0.3)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _listenToggle,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening
                            ? Colors.redAccent
                            : cs.primary.withValues(alpha: 0.6),
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isLoading ? null : _sendMessage,
            child: AnimatedContainer(
              duration: PhobesTheme.animFast,
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: _isLoading ? null : PhobesTheme.primaryGradient,
                color: _isLoading ? cs.surfaceContainer : null,
                shape: BoxShape.circle,
                boxShadow: _isLoading
                    ? null
                    : [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: _isLoading
                  ? Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: cs.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
