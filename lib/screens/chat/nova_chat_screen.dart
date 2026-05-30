import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import 'package:animate_do/animate_do.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../services/nova_service.dart';
import '../../services/firebase_service.dart';
import '../../core/phobes_theme.dart';
import '../../core/phobes_detail_panel.dart';
import '../../widgets/phobes_widgets.dart';
import '../tasks/task_detail_screen.dart';
import '../../models/task_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../services/budget_service.dart';
import '../../models/appointment_model.dart';
import '../../models/note_model.dart';
import '../../services/notification_service.dart';
import '../../models/budget_model.dart';
part 'nova_chat_actions.dart';

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
  final Set<String> _answeredOptions = {};
  bool _isLoading = false;

  final stt.SpeechToText _speechToText = stt.SpeechToText();

  bool _isListening = false;
  bool _isSpeechEnabled = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    Future.microtask(() => _loadDailyBriefing());
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

  Future<void> _listenToggle() async {
    if (!_isListening) {
      if (_isSpeechEnabled) {
        setState(() => _isListening = true);
        await _speechToText.listen(
          onResult: (val) {
            if (!mounted) return;
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
    _speechToText.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadDailyBriefing() async {
    final l10n = AppLocalizations.of(context)!;
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
      final name = user?.displayName?.split(' ')[0] ?? l10n.friend;

      final briefing = await _novaService.getDailyBriefing(todayTasks, name);

      if (mounted) {
        if (briefing != null) {
          _addMessage('model', briefing);
        } else {
          _addMessage('model', AppLocalizations.of(context)!.aiInitialGreeting(name));
        }
      }
    } catch (e) {
      if (mounted) {
        _addMessage('model', l10n.aiErrorConnection);
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

  /// Sends a message directly (used when user taps an option chip).
  Future<void> _sendMessageDirect(String text) async {
    if (text.isEmpty || _isLoading) return;
    _addMessage('user', text);
    setState(() => _isLoading = true);

    final history = _messages.length > 10
        ? _messages.sublist(_messages.length - 10)
        : _messages;

    final l10n = AppLocalizations.of(context)!;
    final response = await _novaService.chatWithNova(
      history,
      language: l10n.localeName == 'tr' ? 'Türkçe' : 'English',
      contextUserHeader: l10n.aiContextUser,
      currentTimeLabel: l10n.aiContextCurrentTime,
      tasksTodayLabel: l10n.aiLabelTasksToday,
      upcomingTasksLabel: l10n.aiLabelUpcomingTasks,
      appointmentsLabel: l10n.aiLabelAppointments,
      medicationsLabel: l10n.aiLabelActiveMeds,
      habitsLabel: l10n.aiLabelDailyHabits,
      notesLabel: l10n.aiLabelRecentNotes,
      teamsLabel: l10n.aiLabelActiveTeams,
      budgetLabel: l10n.aiLabelBudgetStatus,
      systemRole: l10n.aiSystemRole(l10n.localeName == 'tr' ? 'Türkçe' : 'English'),
      toolUsageRulesHeader: l10n.aiInstructionToolUsage,
      readyInstruction: l10n.aiInstructionReady,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (response != null) {
        _addMessage('model', response);
      } else {
        _addMessage('model', l10n.aiErrorConnection);
      }
    }
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

    final l10n = AppLocalizations.of(context)!;
    final response = await _novaService.chatWithNova(
      history,
      language: l10n.localeName == 'tr' ? 'Türkçe' : 'English',
      contextUserHeader: l10n.aiContextUser,
      currentTimeLabel: l10n.aiContextCurrentTime,
      tasksTodayLabel: l10n.aiLabelTasksToday,
      upcomingTasksLabel: l10n.aiLabelUpcomingTasks,
      appointmentsLabel: l10n.aiLabelAppointments,
      medicationsLabel: l10n.aiLabelActiveMeds,
      habitsLabel: l10n.aiLabelDailyHabits,
      notesLabel: l10n.aiLabelRecentNotes,
      teamsLabel: l10n.aiLabelActiveTeams,
      budgetLabel: l10n.aiLabelBudgetStatus,
      systemRole: l10n.aiSystemRole(l10n.localeName == 'tr' ? 'Türkçe' : 'English'),
      toolUsageRulesHeader: l10n.aiInstructionToolUsage,
      readyInstruction: l10n.aiInstructionReady,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (response != null) {
        _addMessage('model', response);
      } else {
        _addMessage('model', l10n.aiErrorConnection);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmoled = PhobesTheme.amoledMode.value;

    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: isAmoled && isDark ? Colors.black : cs.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: isWide ? 860 : double.infinity),
            child: Column(
              children: [
                _buildPremiumHeader(isWide: isWide),
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
        ),
      ),
    );
  }

  Widget _buildPremiumHeader({bool isWide = false}) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, isWide ? 20 : 48, 16),
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
                  color: cs.primary.withOpacity(0.4),
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
                  'Nova AI',
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
                      AppLocalizations.of(context)!.aiOnline,
                      style: GoogleFonts.outfit(
                        color: cs.onSurface.withOpacity(0.5),
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
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: cs.onSurface),
            onSelected: (value) {
              if (value == 'clear') {
                setState(() => _messages.clear());
                if (mounted) {
                  PhobesSnackbar.show(
                    context,
                    message: AppLocalizations.of(context)?.novaChatCleared ??
                        'Chat cleared',
                    type: PhobesSnackbarType.success,
                  );
                }
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep_rounded, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      AppLocalizations.of(ctx)?.novaClearChat ?? 'Clear chat',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNovaGuide(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
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
                            color: Colors.white, size: 28,),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.aiGuideTitle,
                              style: GoogleFonts.outfit(
                                color: cs.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              l10n.aiGuideSubtitle,
                              style: GoogleFonts.outfit(
                                color: cs.onSurface.withOpacity(0.7),
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
                              l10n.aiGuideItem1Title,
                              l10n.aiGuideItem1Desc,),
                          _buildGuideItem(
                              Icons.edit_calendar_rounded,
                              l10n.aiGuideItem2Title,
                              l10n.aiGuideItem2Desc,),
                          _buildGuideItem(
                              Icons.delete_sweep_rounded,
                              l10n.aiGuideItem3Title,
                              l10n.aiGuideItem3Desc,),
                          _buildGuideItem(
                              Icons.search_rounded,
                              l10n.aiGuideItem4Title,
                              l10n.aiGuideItem4Desc,),
                          _buildGuideItem(
                              Icons.account_tree_rounded,
                              l10n.aiGuideItem5Title,
                              l10n.aiGuideItem5Desc,),
                          _buildGuideItem(Icons.groups_rounded,
                              l10n.aiGuideItem6Title,
                              l10n.aiGuideItem6Desc,),
                          _buildGuideItem(Icons.mic_rounded,
                              l10n.aiGuideItem7Title,
                              l10n.aiGuideItem7Desc,),
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
                            borderRadius: BorderRadius.circular(16),),
                      ),
                      child: Text(l10n.aiGuideAnladim,
                          style: GoogleFonts.outfit(
                              fontSize: 16, fontWeight: FontWeight.bold,),),
                    ),
                  ),
                ],
              ),
            ),
            ),
          );
        },);
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
                color: cs.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),),
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
                      fontSize: 14,),),
              const SizedBox(height: 2),
              Text(description,
                  style: GoogleFonts.outfit(
                      color: cs.onSurface.withOpacity(0.7),
                      fontSize: 13,
                      height: 1.4,),),
            ],
          ),),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, String> msg, int index) {
    final isUser = msg['role'] == 'user';
    final String text = msg['text']!;

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
        '__NOVA_OPTIONS__',
        '__PENDING_MULTI_TASKS__',
        '__PENDING_TASK__',
        '__PENDING_EXPENSE__',
        '__PENDING_MEDICATION__',
        '__PENDING_SUBTASKS__',
        '__ADD_SUBTASKS__',
        '__PENDING_ANNOUNCEMENT__',
        '__PENDING_TASK_CANCEL__',
        '__PENDING_TASK_UPDATE__',
        '__PENDING_TASK_RESCHEDULE__',
        '__PENDING_TASK_COMPLETE__',
        '__PENDING_APPOINTMENT__',
        '__PENDING_APPT_CANCEL__',
        '__PENDING_APPT_RESCHEDULE__',
        '__PENDING_NOTE__',
        '__PENDING_HABIT__',
        '__PENDING_INCOME__',
        '__PENDING_SAVINGS_GOAL__',
      ];

      for (final pType in pendingTypes) {
        if (text.contains(pType)) {
          isPending = true;
          foundPendingType = pType;
          break;
        }
      }

      if (isPending && foundPendingType != null) {

        final startIndex = text.indexOf(foundPendingType);
        final beforeCard = text.substring(0, startIndex);
        final afterTag = text.substring(startIndex + foundPendingType.length);

        final jsonStartIdx = afterTag.indexOf('{');
        if (jsonStartIdx != -1) {
          String cardData = afterTag.substring(jsonStartIdx);
          String afterText = '';

          final lastBraceIdx = cardData.lastIndexOf('}');
          if (lastBraceIdx != -1) {
            afterText = cardData.substring(lastBraceIdx + 1);
            cardData = cardData.substring(0, lastBraceIdx + 1);
          }

          try {
            pendingData = jsonDecode(cardData.trim());
          } catch (e) {
            debugPrint('JSON ayrıştırma hatası ($foundPendingType): $e');

            final cleanData = cardData.replaceAll(RegExp(r'^[:_]+'), '').trim();
             try {
               pendingData = jsonDecode(cleanData);
             } catch (e, s) {
               debugPrint('Nova chat: cleaned JSON parse error: $e');
               if (!kDebugMode) FirebaseCrashlytics.instance.recordError(e, s, information: ['pendingType: $foundPendingType']);
               isPending = false;
               displayMessage = AppLocalizations.of(context)!
                   .aiActionCreateFailed;
             }
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
                        color: Colors.white, size: 16,),
                  ),
                  const SizedBox(width: 8),
                ],
                if (displayMessage.isNotEmpty)
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: (MediaQuery.of(context).size.width * 0.72)
                          .clamp(0.0, 580.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12,),
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
                              color: Colors.white.withOpacity(0.08),),
                      boxShadow: isUser
                          ? [
                              BoxShadow(
                                color: PhobesTheme.secondaryColor
                                    .withOpacity(0.3),
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
              _buildTaskCard(
                taskId,
                taskTitle ?? AppLocalizations.of(context)!.defaultTask,
                taskDate ?? '',
              ),
            if (isPending && pendingData != null) ...[
              if (foundPendingType == '__NOVA_OPTIONS__')
                _buildOptionsCard(pendingData),
              if (foundPendingType == '__PENDING_MULTI_TASKS__')
                _buildMultiTasksCard(pendingData),
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
              if (foundPendingType == '__PENDING_TASK_CANCEL__')
                _buildTaskCancelCard(pendingData),
              if (foundPendingType == '__PENDING_TASK_UPDATE__')
                _buildTaskUpdateCard(pendingData),
              if (foundPendingType == '__PENDING_TASK_RESCHEDULE__')
                _buildTaskRescheduleCard(pendingData),
              if (foundPendingType == '__PENDING_TASK_COMPLETE__')
                _buildTaskCompleteCard(pendingData),
              if (foundPendingType == '__PENDING_APPOINTMENT__')
                _buildAppointmentCard(pendingData),
              if (foundPendingType == '__PENDING_APPT_CANCEL__')
                _buildApptCancelCard(pendingData),
              if (foundPendingType == '__PENDING_APPT_RESCHEDULE__')
                _buildApptRescheduleCard(pendingData),
              if (foundPendingType == '__PENDING_NOTE__')
                _buildNoteCard(pendingData),
              if (foundPendingType == '__PENDING_HABIT__')
                _buildHabitCard(pendingData),
              if (foundPendingType == '__PENDING_INCOME__')
                _buildIncomeCard(pendingData),
              if (foundPendingType == '__PENDING_SAVINGS_GOAL__')
                _buildSavingsGoalCard(pendingData),
            ],
          ],
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
                border: Border.all(color: Colors.white.withOpacity(0.08)),
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
                              .withOpacity(0.3 + (value * 0.4)),
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
                  color: PhobesTheme.primaryColor.withOpacity(0.4),
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
            AppLocalizations.of(context)!.novaPreparing,
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
          top: BorderSide(color: cs.outline.withOpacity(0.1)),
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
                            AppLocalizations.of(context)!.novaListening,
                        hintStyle: GoogleFonts.outfit(
                            color: cs.onSurface.withOpacity(0.3),),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14,),
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
                            : cs.primary.withOpacity(0.6),
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
                color: _isLoading ? cs.surfaceVariant : null,
                shape: BoxShape.circle,
                boxShadow: _isLoading
                    ? null
                    : [
                        BoxShadow(
                          color: cs.primary.withOpacity(0.4),
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
                      color: Colors.white, size: 22,),
            ),
          ),
        ],
      ),
    );
  }
}
