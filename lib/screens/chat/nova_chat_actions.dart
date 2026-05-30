// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api
part of 'nova_chat_screen.dart';

extension NovaChatActionsExtension on _NovaChatScreenState {
  Widget _buildGenericApprovalCard({
    required String id,
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final isApproved = _approvedTasks.contains(id);
    final isRejected = _rejectedTasks.contains(id);

    if (isApproved || isRejected) {
      return Container(
        margin: const EdgeInsets.only(top: 8, left: 40),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isApproved ? Colors.green.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isApproved ? Colors.green.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isApproved ? Colors.green : Colors.redAccent, size: 20,),
            const SizedBox(width: 8),
            Text(isApproved ? l10n.aiStatusApproved : l10n.aiStatusCancelled,
                style: GoogleFonts.outfit(color: isApproved ? Colors.green : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),),
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
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
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
                    text: l10n.aiBtnReject,
                    onPressed: onReject,
                    backgroundColor: Colors.white.withOpacity(0.1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PhobesButton(
                    text: l10n.aiBtnApprove,
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

  // ── Interactive Options Card ─────────────────────────────────────────────

  Widget _buildOptionsCard(Map<String, dynamic> data) {
    final String id = data['id'] ?? '';
    final String question = data['question'] ?? '';
    final List<dynamic> options = data['options'] ?? [];
    final bool answered = _answeredOptions.contains(id);

    if (answered) {
      return Container(
        margin: const EdgeInsets.only(top: 8, left: 40),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white38, size: 16),
            const SizedBox(width: 6),
            Text(AppLocalizations.of(context)!.aiStatusAnswered,
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8, left: 40),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.80),
      child: PhobesGlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: PhobesTheme.primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.help_outline_rounded,
                      color: PhobesTheme.primaryColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    question,
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((opt) {
                final label = opt.toString();
                return GestureDetector(
                  onTap: () {
                    setState(() => _answeredOptions.add(id));
                    _sendMessageDirect(label);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: PhobesTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: PhobesTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Multi-Tasks Approval Card ────────────────────────────────────────────

  Widget _buildMultiTasksCard(Map<String, dynamic> data) {
    final String id = data['id'] ?? '';
    final List<dynamic> tasks = data['tasks'] ?? [];
    final isApproved = _approvedTasks.contains(id);
    final isRejected = _rejectedTasks.contains(id);

    if (isApproved || isRejected) {
      return Container(
        margin: const EdgeInsets.only(top: 8, left: 40),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isApproved
              ? Colors.green.withOpacity(0.1)
              : Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isApproved
                  ? Colors.green.withOpacity(0.3)
                  : Colors.redAccent.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                isApproved
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: isApproved ? Colors.green : Colors.redAccent,
                size: 20),
            const SizedBox(width: 8),
            Text(
                isApproved
                    ? AppLocalizations.of(context)!
                        .aiTasksAddedCount(tasks.length)
                    : AppLocalizations.of(context)!.aiStatusCancelled,
                style: GoogleFonts.outfit(
                    color: isApproved ? Colors.green : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8, left: 40),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.80),
      child: PhobesGlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: PhobesTheme.primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.event_note_rounded,
                      color: PhobesTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!
                        .aiApproveAllTasksTitle(tasks.length),
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...tasks.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 10, top: 2),
                        decoration: const BoxDecoration(
                          color: PhobesTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          t['title'] ?? '',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        '${t['date'] ?? ''} ${t['time'] ?? ''}',
                        style: GoogleFonts.outfit(
                            color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PhobesButton(
                    text: AppLocalizations.of(context)!.cancel,
                    onPressed: () =>
                        setState(() => _rejectedTasks.add(id)),
                    backgroundColor: Colors.white.withOpacity(0.1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PhobesButton(
                    text: AppLocalizations.of(context)!.aiAddAllTasks,
                    onPressed: () => _approveMultiTasks(data),
                    backgroundColor: PhobesTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveMultiTasks(Map<String, dynamic> data) async {
    final l10n = AppLocalizations.of(context)!;
    final String id = data['id'] ?? '';
    final List<dynamic> tasks = data['tasks'] ?? [];
    setState(() => _isLoading = true);
    try {
      for (final t in tasks) {
        final dateStr = t['date'] as String? ?? '';
        final timeStr = t['time'] as String? ?? '09:00';
        DateTime start;
        try {
          start = DateTime.parse('$dateStr $timeStr');
        } catch (_) {
          start = DateTime.now().add(const Duration(hours: 1));
        }
        final newTask = Task(
          userId: '',
          title: t['title'] ?? l10n.defaultTask,
          description: l10n.aiCreatedByNova,
          startTime: start,
          endTime: start.add(const Duration(hours: 1)),
          tags: ['Nova'],
        );
        await _firebaseService.addTask(newTask);
      }
      _novaService.invalidateContextCache();
      if (mounted) setState(() => _approvedTasks.add(id));
    } catch (e, s) {
      _onApproveError(e, s);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildApprovalCard(Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context)!;
    return _buildGenericApprovalCard(
      id: data['id'], title: l10n.aiLabelNewTask, icon: Icons.task_alt, color: PhobesTheme.primaryColor,
      children: [
        _buildApprovalRow(l10n.aiFieldTitle, data['title'] ?? ''),
        _buildApprovalRow(l10n.aiFieldDate, data['date'] ?? ''),
        _buildApprovalRow(l10n.aiFieldTime, data['time'] ?? ''),
      ],
      onApprove: () => _approvePendingTask(data), onReject: () => setState(() => _rejectedTasks.add(data['id'])),
    );
  }

  Widget _buildExpenseApprovalCard(Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context)!;
    return _buildGenericApprovalCard(
      id: data['id'], title: l10n.aiLabelAddExpense, icon: Icons.account_balance_wallet_rounded, color: Colors.orangeAccent,
      children: [
        _buildApprovalRow(l10n.aiFieldDescription, data['title'] ?? ''),
        _buildApprovalRow(l10n.aiFieldAmount, "${data['amount']} ₺"), 
        _buildApprovalRow(l10n.aiFieldCategory, data['category'] ?? ''),
      ],
      onApprove: () => _approveExpense(data), onReject: () => setState(() => _rejectedTasks.add(data['id'])),
    );
  }

  Widget _buildMedicationApprovalCard(Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context)!;
    return _buildGenericApprovalCard(
      id: data['id'], title: l10n.aiLabelMedRecord, icon: Icons.medication_rounded, color: Colors.greenAccent,
      children: [
        _buildApprovalRow(l10n.aiFieldMedName, data['medication_name'] ?? ''),
        _buildApprovalRow(l10n.aiFieldTime, data['time'] ?? ''),
      ],
      onApprove: () => _approveMedication(data), onReject: () => setState(() => _rejectedTasks.add(data['id'])),
    );
  }

  Widget _buildSubtasksApprovalCard(Map<String, dynamic> data) {
    final List<dynamic> st = data['subtasks'] ?? [];
    return _buildGenericApprovalCard(
      id: data['id'], title: AppLocalizations.of(context)!.aiLabelSubtasks, icon: Icons.checklist_rounded, color: Colors.amberAccent,
      children: [
        for (final s in st)
          Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.arrow_right_rounded, color: Colors.white54, size: 16),
            Expanded(child: Text(s.toString(), style: GoogleFonts.outfit(color: Colors.white, fontSize: 13))),
          ],),),
      ],
      onApprove: () => _approveSubtasks(data), onReject: () => setState(() => _rejectedTasks.add(data['id'])),
    );
  }

  Widget _buildAnnouncementApprovalCard(Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context)!;
    return _buildGenericApprovalCard(
      id: data['id'], title: l10n.aiLabelTeamAnnouncement, icon: Icons.campaign_rounded, color: Colors.purpleAccent,
      children: [
        Text(data['message'] ?? '', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, height: 1.4)),
      ],
      onApprove: () => _approveAnnouncement(data), onReject: () => setState(() => _rejectedTasks.add(data['id'])),
    );
  }

  Future<void> _approvePendingTask(Map<String, dynamic> data) async {
    final l10n = AppLocalizations.of(context)!;
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
      final Task newTask = Task(
        userId: '',
        title: data['title'] ?? l10n.newTask,
        description: l10n.aiCreatedByNova,
        startTime: start,
        endTime: start.add(const Duration(hours: 1)),
        tags: ['Nova'],
      );
      await _firebaseService.addTask(newTask);
      _novaService.invalidateContextCache();
      if (mounted) setState(() => _approvedTasks.add(id));
    } catch (e, s) {
      _onApproveError(e, s);
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
        title: data['title'] ?? AppLocalizations.of(context)!.defaultExpense,
        category: data['category'] ?? AppLocalizations.of(context)!.defaultCategoryOther,
        date: DateTime.now(),
        type: TransactionType.expense,
      ),);
      _novaService.invalidateContextCache();
      if (mounted) setState(() => _approvedTasks.add(id));
    } catch (e, s) {
      _onApproveError(e, s);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveMedication(Map<String, dynamic> data) async {
    final String id = data['id'];
    setState(() => _isLoading = true);
    try {
      final name = (data['medication_name'] as String? ?? '').trim();
      final time = data['time'] as String? ??
          DateFormat('HH:mm').format(DateTime.now());
      if (name.isNotEmpty) {
        final meds = await _firebaseService.getMedicationsStream().first;
        final match = meds.where(
          (m) => m.name.toLowerCase() == name.toLowerCase(),
        );
        if (match.isNotEmpty) {
          final med = match.first;
          final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
          await _firebaseService.markMedicationTaken(
            med.id!,
            dateKey,
            time,
          );
        }
      }
      _novaService.invalidateContextCache();
      if (mounted) setState(() => _approvedTasks.add(id));
    } catch (e, s) {
      _onApproveError(e, s);
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
        for (final st in subtasks) {
          newSubtasks.add(SubTask(
            id: '${DateTime.now().millisecondsSinceEpoch}_${index++}',
            title: st.toString(),
          ),);
        }
        await _firebaseService.updateTask(taskData.copyWith(subtasks: newSubtasks));
        _novaService.invalidateContextCache();
        if (mounted) setState(() => _approvedTasks.add(id));
      }
    } catch (e, s) {
      _onApproveError(e, s);
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
      _novaService.invalidateContextCache();
      if (mounted) setState(() => _approvedTasks.add(id));
    } catch (e, s) {
      _onApproveError(e, s);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTaskCancelCard(Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context)!;
    return _buildGenericApprovalCard(
      id: data['id'], title: l10n.aiLabelDeleteTask, icon: Icons.delete_rounded, color: Colors.redAccent,
      children: [
        _buildApprovalRow(l10n.aiFieldTask, data['title'] ?? ''),
        Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(l10n.aiTaskDeletePermanentWarning, style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 12))),
      ],
      onApprove: () => _approveTaskCancel(data), onReject: () => setState(() => _rejectedTasks.add(data['id'])),
    );
  }

  Widget _buildTaskUpdateCard(Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context)!;
    final changes = data['changes'] as Map<String, dynamic>? ?? {};
    return _buildGenericApprovalCard(
      id: data['id'], title: l10n.aiLabelUpdateTask, icon: Icons.edit_rounded, color: Colors.amber,
      children: [
        _buildApprovalRow(l10n.aiFieldTask, data['title'] ?? ''),
        for (final entry in changes.entries)
          _buildApprovalRow(entry.key, entry.value.toString()),
      ],
      onApprove: () => _approveTaskUpdate(data), onReject: () => setState(() => _rejectedTasks.add(data['id'])),
    );
  }

  Widget _buildTaskRescheduleCard(Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context)!;
    return _buildGenericApprovalCard(
      id: data['id'],
      title: l10n.aiLabelRescheduleTask,
      icon: Icons.schedule_rounded,
      color: Colors.orangeAccent,
      children: [
        _buildApprovalRow(l10n.aiFieldTask, data['title'] ?? ''),
        _buildApprovalRow(l10n.aiFieldNewDate, data['date'] ?? ''),
        _buildApprovalRow(l10n.aiFieldNewTime, data['time'] ?? ''),
      ],
      onApprove: () => _approveTaskReschedule(data),
      onReject: () => setState(() => _rejectedTasks.add(data['id'])),
    );
  }

  Widget _buildTaskCompleteCard(Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context)!;
    return _buildGenericApprovalCard(
      id: data['id'], title: l10n.aiLabelCompleteTask, icon: Icons.check_circle_rounded, color: Colors.green,
      children: [
        _buildApprovalRow(l10n.aiFieldTask, data['title'] ?? ''),
      ],
      onApprove: () => _approveTaskComplete(data), onReject: () => setState(() => _rejectedTasks.add(data['id'])),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context)!;
    final minutes = data['duration_minutes'] as int? ?? 60;
    return _buildGenericApprovalCard(
      id: data['id'], title: l10n.aiLabelCreateAppointment, icon: Icons.event_rounded, color: const Color(0xFF2196F3),
      children: [
        _buildApprovalRow(l10n.aiFieldTitle, data['title'] ?? ''),
        _buildApprovalRow(l10n.aiFieldClient, data['client_name'] ?? ''),
        if ((data['phone'] ?? '').isNotEmpty) _buildApprovalRow(l10n.aiFieldPhone, data['phone']),
        _buildApprovalRow(l10n.aiFieldDate, "${data['date']} ${data['time']}"),
        _buildApprovalRow(l10n.aiFieldDuration, l10n.durationMinutesFormat(minutes)),
      ],
      onApprove: () => _approveAppointment(data), onReject: () => setState(() => _rejectedTasks.add(data['id'])),
    );
  }

  Widget _buildApptCancelCard(Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context)!;
    return _buildGenericApprovalCard(
      id: data['id'], title: l10n.aiLabelCancelAppointment, icon: Icons.event_busy_rounded, color: Colors.redAccent,
      children: [
        _buildApprovalRow(l10n.aiFieldAppointmentId, data['appointment_id'] ?? ''),
        Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(l10n.aiAppointmentCancelPermanentWarning, style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 12))),
      ],
      onApprove: () => _approveApptCancel(data), onReject: () => setState(() => _rejectedTasks.add(data['id'])),
    );
  }

  Widget _buildApptRescheduleCard(Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context)!;
    return _buildGenericApprovalCard(
      id: data['id'], title: l10n.aiLabelRescheduleAppointment, icon: Icons.event_repeat_rounded, color: Colors.blueAccent,
      children: [
        _buildApprovalRow(l10n.aiFieldNewDate, "${data['date']} ${data['time']}"),
      ],
      onApprove: () => _approveApptReschedule(data), onReject: () => setState(() => _rejectedTasks.add(data['id'])),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context)!;
    final content = (data['content'] ?? '') as String;
    return _buildGenericApprovalCard(
      id: data['id'], title: l10n.aiLabelCreateNote, icon: Icons.note_alt_rounded, color: const Color(0xFF8B5CF6),
      children: [
        _buildApprovalRow(l10n.aiFieldTitle, data['title'] ?? ''),
        if (content.isNotEmpty)
          _buildApprovalRow(l10n.aiFieldContent, content.length > 80 ? '${content.substring(0, 80)}…' : content),
        if ((data['notebook_name'] ?? '').isNotEmpty)
          _buildApprovalRow(l10n.aiFieldNotebook, data['notebook_name']),
      ],
      onApprove: () => _approveNote(data), onReject: () => setState(() => _rejectedTasks.add(data['id'])),
    );
  }

  Widget _buildHabitCard(Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context)!;
    return _buildGenericApprovalCard(
      id: data['id'], title: l10n.aiLabelAddHabit, icon: Icons.local_fire_department_rounded, color: const Color(0xFF4CAF50),
      children: [
        _buildApprovalRow(l10n.aiFieldHabit, data['title'] ?? ''),
        if ((data['reminder_time'] ?? '').isNotEmpty)
          _buildApprovalRow(l10n.aiFieldReminder, data['reminder_time']),
      ],
      onApprove: () => _approveHabit(data), onReject: () => setState(() => _rejectedTasks.add(data['id'])),
    );
  }

  Widget _buildIncomeCard(Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context)!;
    return _buildGenericApprovalCard(
      id: data['id'], title: l10n.aiLabelAddIncome, icon: Icons.savings_rounded, color: const Color(0xFF26A69A),
      children: [
        _buildApprovalRow(l10n.aiFieldDescription, data['title'] ?? ''),
        _buildApprovalRow(l10n.aiFieldAmount, "${data['amount']} TL"),
        _buildApprovalRow(l10n.aiFieldCategory, data['category'] ?? ''),
      ],
      onApprove: () => _approveIncome(data), onReject: () => setState(() => _rejectedTasks.add(data['id'])),
    );
  }

  Widget _buildSavingsGoalCard(Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context)!;
    return _buildGenericApprovalCard(
      id: data['id'], title: l10n.aiLabelSavingsGoal, icon: Icons.flag_rounded, color: const Color(0xFFFF9800),
      children: [
        _buildApprovalRow(l10n.aiFieldGoal, data['title'] ?? ''),
        _buildApprovalRow(l10n.aiFieldAmount, "${data['target_amount']} TL"),
        if ((data['deadline'] ?? '').isNotEmpty) _buildApprovalRow(l10n.aiFieldDeadline, data['deadline']),
      ],
      onApprove: () => _approveSavingsGoal(data), onReject: () => setState(() => _rejectedTasks.add(data['id'])),
    );
  }

  Future<void> _approveTaskCancel(Map<String, dynamic> data) async {
    final String id = data['id'];
    setState(() => _isLoading = true);
    try {
      await _firebaseService.deleteTask(data['task_id']);
      _novaService.invalidateContextCache();
      if (mounted) setState(() => _approvedTasks.add(id));
    } catch (e, s) {
      _onApproveError(e, s);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveTaskUpdate(Map<String, dynamic> data) async {
    final String id = data['id'];
    setState(() => _isLoading = true);
    try {
      final String taskId = data['task_id'];
      final changes = data['changes'] as Map<String, dynamic>? ?? {};
      final doc = await FirebaseFirestore.instance.collection('tasks').doc(taskId).get();
      if (doc.exists) {
        final taskData = Task.fromFirestore(doc);
        final DateTime currentStart = taskData.startTime;
        DateTime newStart = currentStart;
        if (changes.containsKey('date') || changes.containsKey('time')) {
          final dateStr = changes['date'] ?? '${currentStart.year}-${currentStart.month.toString().padLeft(2,'0')}-${currentStart.day.toString().padLeft(2,'0')}';
          final timeStr = changes['time'] ?? '${currentStart.hour.toString().padLeft(2,'0')}:${currentStart.minute.toString().padLeft(2,'0')}';
          newStart = DateTime.tryParse('$dateStr $timeStr') ?? currentStart;
        }
        String newDesc = taskData.description;
        if (changes.containsKey('description') && (changes['description'] as String).isNotEmpty) {
          newDesc += (newDesc.isNotEmpty ? '\n' : '') + changes['description'];
        }
        final updated = taskData.copyWith(
          title: changes['title'] ?? taskData.title,
          description: newDesc,
          startTime: newStart,
          endTime: newStart.add(taskData.endTime.difference(taskData.startTime)),
        );
        await _firebaseService.updateTask(updated);
        _novaService.invalidateContextCache();
        if (mounted) setState(() => _approvedTasks.add(id));
      }
    } catch (e, s) {
      _onApproveError(e, s);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveTaskReschedule(Map<String, dynamic> data) async {
    final String id = data['id'];
    setState(() => _isLoading = true);
    try {
      final String taskId = data['task_id'];
      final dateStr = data['date'] as String? ?? '';
      final timeStr = data['time'] as String? ?? '09:00';
      final doc =
          await FirebaseFirestore.instance.collection('tasks').doc(taskId).get();
      if (doc.exists) {
        final taskData = Task.fromFirestore(doc);
        final newStart =
            DateTime.tryParse('$dateStr $timeStr') ?? taskData.startTime;
        final updated = taskData.copyWith(
          startTime: newStart,
          endTime: newStart.add(taskData.endTime.difference(taskData.startTime)),
          postponeCount: taskData.postponeCount + 1,
        );
        await _firebaseService.updateTask(updated);
        _novaService.invalidateContextCache();
        if (mounted) setState(() => _approvedTasks.add(id));
      }
    } catch (e, s) {
      _onApproveError(e, s);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveTaskComplete(Map<String, dynamic> data) async {
    final String id = data['id'];
    setState(() => _isLoading = true);
    try {
      final String taskId = data['task_id'];
      final doc = await FirebaseFirestore.instance.collection('tasks').doc(taskId).get();
      if (doc.exists) {
        await _firebaseService.setTaskCompleted(taskId, true);
        _novaService.invalidateContextCache();
        if (mounted) setState(() => _approvedTasks.add(id));
      }
    } catch (e, s) {
      _onApproveError(e, s);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveAppointment(Map<String, dynamic> data) async {
    final String id = data['id'];
    setState(() => _isLoading = true);
    try {
      final dateStr = data['date'] ?? '';
      final timeStr = data['time'] ?? '09:00';
      final DateTime apptDate = DateTime.tryParse('$dateStr $timeStr') ?? DateTime.now().add(const Duration(days: 1));
      final userId = _firebaseService.currentUserId ?? '';
      await _firebaseService.addAppointment(Appointment(
        userId: userId,
        title: data['title'] ?? 'Randevu',
        clientName: data['client_name'] ?? '',
        phoneNumber: data['phone'],
        date: apptDate,
        durationMinutes: data['duration_minutes'] ?? 60,
      ),);
      _novaService.invalidateContextCache();
      if (mounted) setState(() => _approvedTasks.add(id));
    } catch (e, s) {
      _onApproveError(e, s);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveApptCancel(Map<String, dynamic> data) async {
    final String id = data['id'];
    setState(() => _isLoading = true);
    try {
      await _firebaseService.deleteAppointment(data['appointment_id']);
      _novaService.invalidateContextCache();
      if (mounted) setState(() => _approvedTasks.add(id));
    } catch (e, s) {
      _onApproveError(e, s);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveApptReschedule(Map<String, dynamic> data) async {
    final String id = data['id'];
    setState(() => _isLoading = true);
    try {
      final String apptId = data['appointment_id'];
      final doc = await FirebaseFirestore.instance.collection('appointments').doc(apptId).get();
      if (doc.exists) {
        final appt = Appointment.fromFirestore(doc);
        final newDate = DateTime.tryParse("${data['date']} ${data['time']}") ?? appt.date;
        await _firebaseService.updateAppointment(Appointment(
          id: appt.id, userId: appt.userId, title: appt.title,
          clientName: appt.clientName, phoneNumber: appt.phoneNumber,
          date: newDate, durationMinutes: appt.durationMinutes,
          status: appt.status, notes: appt.notes,
        ),);
        _novaService.invalidateContextCache();
        if (mounted) setState(() => _approvedTasks.add(id));
      }
    } catch (e, s) {
      _onApproveError(e, s);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveNote(Map<String, dynamic> data) async {
    final String id = data['id'];
    setState(() => _isLoading = true);
    try {
      final userId = _firebaseService.currentUserId ?? '';
      await _firebaseService.addNote(Note(
        userId: userId,
        title: data['title'] ?? AppLocalizations.of(context)!.defaultNote,
        content: data['content'] ?? '',
        date: DateTime.now(),
      ),);
      _novaService.invalidateContextCache();
      if (mounted) setState(() => _approvedTasks.add(id));
    } catch (e, s) {
      _onApproveError(e, s);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveHabit(Map<String, dynamic> data) async {
    final String id = data['id'];
    setState(() => _isLoading = true);
    try {
      final habitId = await _firebaseService.addHabit(
        data['title'] ?? AppLocalizations.of(context)!.defaultHabit,
      );
      if (habitId != null && (data['reminder_time'] ?? '').isNotEmpty) {
        final parts = (data['reminder_time'] as String).split(':');
        if (parts.length == 2) {
          final time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          await NotificationService().scheduleDailyHabitReminder(
            habitId: habitId, habitName: data['title'] ?? '', time: time,);
        }
      }
      _novaService.invalidateContextCache();
      if (mounted) setState(() => _approvedTasks.add(id));
    } catch (e, s) {
      _onApproveError(e, s);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveIncome(Map<String, dynamic> data) async {
    final String id = data['id'];
    setState(() => _isLoading = true);
    try {
      final budgetService = BudgetService();
      await budgetService.addTransaction(BudgetTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _firebaseService.currentUserId ?? '',
        amount: (data['amount'] as num).toDouble(),
        title: data['title'] ?? 'Gelir',
        category: data['category'] ??
            AppLocalizations.of(context)!.defaultCategoryOther,
        date: DateTime.now(),
        type: TransactionType.income,
      ),);
      _novaService.invalidateContextCache();
      if (mounted) setState(() => _approvedTasks.add(id));
    } catch (e, s) {
      _onApproveError(e, s);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveSavingsGoal(Map<String, dynamic> data) async {
    final String id = data['id'];
    setState(() => _isLoading = true);
    try {
      final budgetService = BudgetService();
      final deadlineStr = data['deadline'] ?? '';
      await budgetService.addGoal(SavingsGoal(
        userId: _firebaseService.currentUserId ?? '',
        title: data['title'] ?? 'Hedef',
        targetAmount: (data['target_amount'] as num).toDouble(),
        deadline: deadlineStr.isNotEmpty ? DateTime.tryParse(deadlineStr) : null,
      ),);
      _novaService.invalidateContextCache();
      if (mounted) setState(() => _approvedTasks.add(id));
    } catch (e, s) {
      _onApproveError(e, s);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onApproveError(Object e, StackTrace s) {
    final l10n = AppLocalizations.of(context)!;
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(e, s, information: ['nova approve action'],);
    }
    if (mounted) {
      PhobesSnackbar.show(
        context,
        message: l10n.aiActionFailed,
        type: PhobesSnackbarType.error,
      );
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

          final doc = await FirebaseFirestore.instance
              .collection('tasks')
              .doc(id)
              .get();
          if (doc.exists && mounted) {
            final task = Task.fromFirestore(doc);
            PhobesDetailPanel.open(
              context,
              TaskDetailScreen(task: task),
            );
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
                  color: PhobesTheme.primaryColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.task_alt,
                    color: PhobesTheme.primaryColor, size: 20,),
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
                  color: Colors.white54, size: 14,),
            ],
          ),
        ),
      ),
    );
  }

}


