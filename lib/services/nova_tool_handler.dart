import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../core/l10n_lookup.dart';
import '../l10n/app_localizations.dart';
import '../utils/time_utils.dart';
import 'firebase_service.dart';

/// Dispatches Nova AI tool calls to individual private handler methods.
/// Each handler builds a pending-action string that the chat UI presents
/// to the user for approval before any real mutation occurs.
class NovaToolHandler {
  const NovaToolHandler._();

  static Future<String> handleToolCall(
    String functionName,
    Map<String, dynamic> args, {
    String? languageCode,
  }) async {
    switch (functionName) {
      case 'create_task':
        return _handleCreateTask(args, languageCode: languageCode);
      case 'create_multiple_tasks':
        return _handleCreateMultipleTasks(args, languageCode: languageCode);
      case 'create_day_plan':
        return _handleCreateDayPlan(args, languageCode: languageCode);
      case 'ask_user_options':
        return _handleAskUserOptions(args, languageCode: languageCode);
      case 'reschedule_task':
        return _handleRescheduleTask(args, languageCode: languageCode);
      case 'cancel_task':
        return _handleCancelTask(args, languageCode: languageCode);
      case 'update_task':
        return _handleUpdateTask(args, languageCode: languageCode);
      case 'complete_task':
        return _handleCompleteTask(args, languageCode: languageCode);
      case 'find_task':
        return _handleFindTask(args, languageCode: languageCode);
      case 'add_subtasks':
        return _handleAddSubtasks(args, languageCode: languageCode);
      case 'create_appointment':
        return _handleCreateAppointment(args, languageCode: languageCode);
      case 'cancel_appointment':
        return _handleCancelAppointment(args, languageCode: languageCode);
      case 'reschedule_appointment':
        return _handleRescheduleAppointment(args, languageCode: languageCode);
      case 'create_note':
        return _handleCreateNote(args, languageCode: languageCode);
      case 'add_habit':
        return _handleAddHabit(args, languageCode: languageCode);
      case 'mark_medication_taken':
        return _handleMarkMedicationTaken(args, languageCode: languageCode);
      case 'add_expense':
        return _handleAddExpense(args, languageCode: languageCode);
      case 'add_income':
        return _handleAddIncome(args, languageCode: languageCode);
      case 'add_savings_goal':
        return _handleAddSavingsGoal(args, languageCode: languageCode);
      case 'send_team_announcement':
        return _handleSendTeamAnnouncement(args, languageCode: languageCode);
      default:
        debugPrint('[NovaToolHandler] Unknown tool: $functionName');
        return '';
    }
  }

  // ── Multi-task / Plan handlers ────────────────────────────────────────────

  static AppLocalizations _l(String? languageCode) => l10nFor(languageCode);

  static Future<String> _handleCreateMultipleTasks(
    Map<String, dynamic> args, {
    String? languageCode,
  }) async {
    final l = _l(languageCode);
    try {
      final tasksList = args['tasks'] as List<dynamic>;
      if (tasksList.isEmpty) {
        return _handleCreateTask(args, languageCode: languageCode);
      }

      final pendingId = DateTime.now().millisecondsSinceEpoch.toString();
      final processed = tasksList.map((t) {
        final title = _capitalize((t['title'] as String? ?? l.defaultTask));
        final dateStr = t['date'] as String? ??
            DateFormat('yyyy-MM-dd')
                .format(DateTime.now().add(const Duration(days: 1)));
        final timeStr = t['time'] as String? ?? '09:00';
        final start = _parseDateTime(dateStr, timeStr);
        return {
          'title': title,
          'date': DateFormat('yyyy-MM-dd').format(start),
          'time': DateFormat('HH:mm').format(start),
        };
      }).toList();

      final multiJson = jsonEncode({'id': pendingId, 'tasks': processed});
      return '__PENDING_MULTI_TASKS__:$multiJson\n'
          '${l.aiPromptApproveAllTasks}\n';
    } catch (e) {
      debugPrint('[NovaToolHandler] create_multiple_tasks error: $e');
      return '${l.aiToolErrorGeneric}\n';
    }
  }

  static Future<String> _handleCreateDayPlan(
    Map<String, dynamic> args, {
    String? languageCode,
  }) async {
    final l = _l(languageCode);
    try {
      final dateStr = args['date'] as String? ??
          DateFormat('yyyy-MM-dd')
              .format(DateTime.now().add(const Duration(days: 1)));
      final tasksList = args['tasks'] as List<dynamic>;

      final pendingId = DateTime.now().millisecondsSinceEpoch.toString();
      final processed = tasksList.map((t) {
        final title = _capitalize((t['title'] as String? ?? l.defaultTask));
        final timeStr = t['time'] as String? ?? '09:00';
        final start = _parseDateTime(dateStr, timeStr);
        return {
          'title': title,
          'date': DateFormat('yyyy-MM-dd').format(start),
          'time': DateFormat('HH:mm').format(start),
        };
      }).toList();

      final planJson = jsonEncode({'id': pendingId, 'tasks': processed});
      return '__PENDING_MULTI_TASKS__:$planJson\n'
          '${l.aiPromptApproveDayPlan}\n';
    } catch (e) {
      debugPrint('[NovaToolHandler] create_day_plan error: $e');
      return '${l.aiToolErrorGeneric}\n';
    }
  }

  static Future<String> _handleAskUserOptions(
    Map<String, dynamic> args, {
    String? languageCode,
  }) async {
    final l = _l(languageCode);
    try {
      final question =
          args['question'] as String? ?? l.aiPromptWhatWouldYouLike;
      final options = (args['options'] as List<dynamic>)
          .map((o) => o.toString())
          .toList();
      final pendingId = DateTime.now().millisecondsSinceEpoch.toString();
      final optJson = jsonEncode({
        'id': pendingId,
        'question': question,
        'options': options,
      });
      return '__NOVA_OPTIONS__:$optJson\n';
    } catch (e) {
      debugPrint('[NovaToolHandler] ask_user_options error: $e');
      return '${args['question'] ?? l.aiPromptWhatWouldYouLike}\n';
    }
  }

  // ── Task handlers ────────────────────────────────────────────────────────

  static Future<String> _handleCreateTask(
    Map<String, dynamic> args, {
    String? languageCode,
  }) async {
    final l = _l(languageCode);
    try {
      final title = args['title'] as String? ?? l.defaultTask;
      final dateStr = args['date'] as String? ??
          DateFormat('yyyy-MM-dd').format(DateTime.now());
      final timeStr = args['time'] as String? ?? '09:00';

      final start = _parseDateTime(dateStr, timeStr);
      final end = start.add(const Duration(hours: 1));

      final tasks = await FirebaseService().getAllUserTasksStream().first;
      final overlap = TimeUtils.getOverlappingTask(start, end, tasks);
      var overlapWarning = '';

      if (overlap != null) {
        final freeSlots = TimeUtils.getFreeSlots(start, tasks);
        overlapWarning = '${l.aiTaskOverlapWarning(overlap.title, freeSlots.join('\n'))}\n\n';
      }

      final pendingId = DateTime.now().millisecondsSinceEpoch.toString();
      final taskJson = jsonEncode({
        'id': pendingId,
        'title': _capitalize(title),
        'date': DateFormat('yyyy-MM-dd').format(start),
        'time': DateFormat('HH:mm').format(start),
      });
      return '${overlapWarning}__PENDING_TASK__:$taskJson\n'
          '${l.aiInstructionReady}\n';
    } catch (e) {
      debugPrint('[NovaToolHandler] create_task error: $e');
      return '${l.aiToolErrorGeneric}\n';
    }
  }

  static Future<String> _handleRescheduleTask(
    Map<String, dynamic> args, {
    String? languageCode,
  }) async {
    final l = _l(languageCode);
    try {
      final taskId = args['task_id'] as String;
      final dateStr = args['date'] as String;
      final timeStr = args['time'] as String;

      final taskData = await FirebaseService().getTaskStream(taskId).first;
      if (taskData == null) {
        return '${l.aiToolErrorTaskNotFound}\n';
      }

      DateTime newStart;
      try {
        newStart = DateTime.parse('$dateStr $timeStr');
      } catch (_) {
        newStart = _parseDateTime(dateStr, timeStr);
      }

      final newEnd =
          newStart.add(taskData.endTime.difference(taskData.startTime));
      final tasks = await FirebaseService().getAllUserTasksStream().first;
      final otherTasks = tasks.where((t) => t.id != taskId).toList();
      final overlap = TimeUtils.getOverlappingTask(newStart, newEnd, otherTasks);

      if (overlap != null) {
        final freeSlots = TimeUtils.getFreeSlots(newStart, otherTasks);
        return '${l.aiTaskOverlapWarning(overlap.title, freeSlots.join('\n'))}\n';
      }

      final pendingId = DateTime.now().millisecondsSinceEpoch.toString();
      final reschedJson = jsonEncode({
        'id': pendingId,
        'task_id': taskId,
        'title': taskData.title,
        'date': dateStr,
        'time': timeStr,
      });
      return '__PENDING_TASK_RESCHEDULE__:$reschedJson\n'
          '${l.aiInstructionReady}\n';
    } catch (e) {
      debugPrint('[NovaToolHandler] reschedule_task error: $e');
      return '${l.aiToolErrorGeneric}\n';
    }
  }

  static Future<String> _handleCancelTask(
    Map<String, dynamic> args, {
    String? languageCode,
  }) async {
    final l = _l(languageCode);
    try {
      final taskId = args['task_id'] as String;
      final found = await FirebaseService().getTaskStream(taskId).first;
      final taskTitle = found?.title ?? l.defaultTask;

      final pendingId = DateTime.now().millisecondsSinceEpoch.toString();
      final cancelJson =
          jsonEncode({'id': pendingId, 'task_id': taskId, 'title': taskTitle});
      return '__PENDING_TASK_CANCEL__:$cancelJson\n'
          '${l.aiPromptDeleteTask(taskTitle)}\n';
    } catch (e) {
      debugPrint('[NovaToolHandler] cancel_task error: $e');
      return '${l.aiToolErrorGeneric}\n';
    }
  }

  static Future<String> _handleUpdateTask(
    Map<String, dynamic> args, {
    String? languageCode,
  }) async {
    final l = _l(languageCode);
    try {
      final taskId = args['task_id'] as String;
      final found = await FirebaseService().getTaskStream(taskId).first;
      final taskTitle = found?.title ?? l.defaultTask;

      final changes = <String, dynamic>{};
      if (args['title'] != null) changes['title'] = args['title'];
      if (args['description'] != null) changes['description'] = args['description'];
      if (args['date'] != null) changes['date'] = args['date'];
      if (args['time'] != null) changes['time'] = args['time'];

      final pendingId = DateTime.now().millisecondsSinceEpoch.toString();
      final updateJson = jsonEncode({
        'id': pendingId,
        'task_id': taskId,
        'title': taskTitle,
        'changes': changes,
      });
      return '__PENDING_TASK_UPDATE__:$updateJson\n'
          '${l.aiPromptUpdateTask(taskTitle)}\n';
    } catch (e) {
      debugPrint('[NovaToolHandler] update_task error: $e');
      return '${l.aiToolErrorGeneric}\n';
    }
  }

  static Future<String> _handleCompleteTask(
    Map<String, dynamic> args, {
    String? languageCode,
  }) async {
    final l = _l(languageCode);
    try {
      final taskId = args['task_id'] as String;
      final found = await FirebaseService().getTaskStream(taskId).first;
      final taskTitle = found?.title ?? l.defaultTask;

      final pendingId = DateTime.now().millisecondsSinceEpoch.toString();
      final completeJson =
          jsonEncode({'id': pendingId, 'task_id': taskId, 'title': taskTitle});
      return '__PENDING_TASK_COMPLETE__:$completeJson\n'
          '${l.aiInstructionReady}\n';
    } catch (e) {
      debugPrint('[NovaToolHandler] complete_task error: $e');
      return '${l.aiToolErrorGeneric}\n';
    }
  }

  static Future<String> _handleFindTask(
    Map<String, dynamic> args, {
    String? languageCode,
  }) async {
    final l = _l(languageCode);
    try {
      final keyword =
          (args['keyword'] as String? ?? '').toLowerCase();
      final allTasks = await FirebaseService().getAllUserTasksStream().first;
      final matches = allTasks
          .where((t) => t.title.toLowerCase().contains(keyword))
          .toList();

      if (matches.isNotEmpty) {
        final found = matches.first;
        final formatted =
            DateFormat('dd MMM yyyy HH:mm').format(found.startTime);
        return '__TASK_CARD__:${found.id}|${found.title}|$formatted\n'
            '${l.aiInstructionReady}\n';
      }
      return '${l.aiToolErrorTaskNotFound}\n';
    } catch (e) {
      debugPrint('[NovaToolHandler] find_task error: $e');
      return '${l.aiToolErrorGeneric}\n';
    }
  }

  static Future<String> _handleAddSubtasks(
    Map<String, dynamic> args, {
    String? languageCode,
  }) async {
    final l = _l(languageCode);
    try {
      final taskId = args['task_id'] as String;
      final subtasks = args['subtasks'] as List<dynamic>;
      final pendingId = DateTime.now().millisecondsSinceEpoch.toString();
      final reqJson = jsonEncode({
        'id': pendingId,
        'task_id': taskId,
        'subtasks': subtasks,
      });
      return '__PENDING_SUBTASKS__:$reqJson\n'
          '${l.aiInstructionReady}\n';
    } catch (e) {
      debugPrint('[NovaToolHandler] add_subtasks error: $e');
      return '${l.aiToolErrorGeneric}\n';
    }
  }

  // ── Appointment handlers ──────────────────────────────────────────────────

  static Future<String> _handleCreateAppointment(
    Map<String, dynamic> args, {
    String? languageCode,
  }) async {
    final l = _l(languageCode);
    try {
      final title = args['title'] as String? ?? l.defaultAppointment;
      final clientName = args['client_name'] as String? ?? '';
      final phone = args['phone'] as String? ?? '';
      final dateStr = args['date'] as String? ??
          DateFormat('yyyy-MM-dd')
              .format(DateTime.now().add(const Duration(days: 1)));
      final timeStr = args['time'] as String? ?? '09:00';
      final duration = args['duration_minutes'] as int? ?? 60;

      final pendingId = DateTime.now().millisecondsSinceEpoch.toString();
      final apptJson = jsonEncode({
        'id': pendingId,
        'title': title,
        'client_name': clientName,
        'phone': phone,
        'date': dateStr,
        'time': timeStr,
        'duration_minutes': duration,
      });
      return '__PENDING_APPOINTMENT__:$apptJson\n'
          '${l.aiPromptCreateAppointment}\n';
    } catch (e) {
      debugPrint('[NovaToolHandler] create_appointment error: $e');
      return '${l.aiToolErrorGeneric}\n';
    }
  }

  static Future<String> _handleCancelAppointment(
    Map<String, dynamic> args, {
    String? languageCode,
  }) async {
    final l = _l(languageCode);
    try {
      final apptId = args['appointment_id'] as String;
      final pendingId = DateTime.now().millisecondsSinceEpoch.toString();
      final cancelJson =
          jsonEncode({'id': pendingId, 'appointment_id': apptId});
      return '__PENDING_APPT_CANCEL__:$cancelJson\n'
          '${l.aiAppointmentCancelPermanentWarning}\n';
    } catch (e) {
      debugPrint('[NovaToolHandler] cancel_appointment error: $e');
      return '${l.aiToolErrorGeneric}\n';
    }
  }

  static Future<String> _handleRescheduleAppointment(
    Map<String, dynamic> args, {
    String? languageCode,
  }) async {
    final l = _l(languageCode);
    try {
      final apptId = args['appointment_id'] as String;
      final dateStr = args['date'] as String;
      final timeStr = args['time'] as String;
      final pendingId = DateTime.now().millisecondsSinceEpoch.toString();
      final reschedJson = jsonEncode({
        'id': pendingId,
        'appointment_id': apptId,
        'date': dateStr,
        'time': timeStr,
      });
      return '__PENDING_APPT_RESCHEDULE__:$reschedJson\n'
          '${l.aiInstructionReady}\n';
    } catch (e) {
      debugPrint('[NovaToolHandler] reschedule_appointment error: $e');
      return '${l.aiToolErrorGeneric}\n';
    }
  }

  // ── Other handlers ────────────────────────────────────────────────────────

  static Future<String> _handleCreateNote(
    Map<String, dynamic> args, {
    String? languageCode,
  }) async {
    final l = _l(languageCode);
    try {
      final title = args['title'] as String? ?? l.defaultNote;
      final content = args['content'] as String? ?? '';
      final notebookName = args['notebook_name'] as String? ?? '';
      final pendingId = DateTime.now().millisecondsSinceEpoch.toString();
      final noteJson = jsonEncode({
        'id': pendingId,
        'title': title,
        'content': content,
        'notebook_name': notebookName,
      });
      return '__PENDING_NOTE__:$noteJson\n${l.aiInstructionReady}\n';
    } catch (e) {
      debugPrint('[NovaToolHandler] create_note error: $e');
      return '${l.aiToolErrorGeneric}\n';
    }
  }

  static Future<String> _handleAddHabit(
    Map<String, dynamic> args, {
    String? languageCode,
  }) async {
    final l = _l(languageCode);
    try {
      final title = args['title'] as String? ?? l.defaultHabit;
      final reminderTime = args['reminder_time'] as String? ?? '';
      final pendingId = DateTime.now().millisecondsSinceEpoch.toString();
      final habitJson = jsonEncode({
        'id': pendingId,
        'title': title,
        'reminder_time': reminderTime,
      });
      return '__PENDING_HABIT__:$habitJson\n${l.aiInstructionReady}\n';
    } catch (e) {
      debugPrint('[NovaToolHandler] add_habit error: $e');
      return '${l.aiToolErrorGeneric}\n';
    }
  }

  static Future<String> _handleMarkMedicationTaken(
    Map<String, dynamic> args, {
    String? languageCode,
  }) async {
    final l = _l(languageCode);
    try {
      final medicationName = args['medication_name'] as String;
      final timeStr = args['time'] as String? ??
          DateFormat('HH:mm').format(DateTime.now());
      final pendingId = DateTime.now().millisecondsSinceEpoch.toString();
      final medJson = jsonEncode({
        'id': pendingId,
        'medication_name': medicationName,
        'time': timeStr,
      });
      return '__PENDING_MEDICATION__:$medJson\n'
          '${l.aiPromptMarkMedication}\n';
    } catch (e) {
      debugPrint('[NovaToolHandler] mark_medication_taken error: $e');
      return '${l.aiToolErrorGeneric}\n';
    }
  }

  static Future<String> _handleAddExpense(
    Map<String, dynamic> args, {
    String? languageCode,
  }) async {
    final l = _l(languageCode);
    try {
      final title = args['title'] as String;
      final amount = (args['amount'] as num).toDouble();
      final category = args['category'] as String;
      final pendingId = DateTime.now().millisecondsSinceEpoch.toString();
      final expJson = jsonEncode({
        'id': pendingId,
        'title': title,
        'amount': amount,
        'category': category,
      });
      return '__PENDING_EXPENSE__:$expJson\n'
          '${l.aiPromptAddExpense}\n';
    } catch (e) {
      debugPrint('[NovaToolHandler] add_expense error: $e');
      return '${l.aiToolErrorGeneric}\n';
    }
  }

  static Future<String> _handleAddIncome(
    Map<String, dynamic> args, {
    String? languageCode,
  }) async {
    final l = _l(languageCode);
    try {
      final title = args['title'] as String;
      final amount = (args['amount'] as num).toDouble();
      final category = args['category'] as String;
      final pendingId = DateTime.now().millisecondsSinceEpoch.toString();
      final incomeJson = jsonEncode({
        'id': pendingId,
        'title': title,
        'amount': amount,
        'category': category,
      });
      return '__PENDING_INCOME__:$incomeJson\n'
          '${l.aiInstructionReady}\n';
    } catch (e) {
      debugPrint('[NovaToolHandler] add_income error: $e');
      return '${l.aiToolErrorGeneric}\n';
    }
  }

  static Future<String> _handleAddSavingsGoal(
    Map<String, dynamic> args, {
    String? languageCode,
  }) async {
    final l = _l(languageCode);
    try {
      final title = args['title'] as String;
      final targetAmount = (args['target_amount'] as num).toDouble();
      final deadline = args['deadline'] as String? ?? '';
      final pendingId = DateTime.now().millisecondsSinceEpoch.toString();
      final goalJson = jsonEncode({
        'id': pendingId,
        'title': title,
        'target_amount': targetAmount,
        'deadline': deadline,
      });
      return '__PENDING_SAVINGS_GOAL__:$goalJson\n'
          '${l.aiInstructionReady}\n';
    } catch (e) {
      debugPrint('[NovaToolHandler] add_savings_goal error: $e');
      return '${l.aiToolErrorGeneric}\n';
    }
  }

  static Future<String> _handleSendTeamAnnouncement(
    Map<String, dynamic> args, {
    String? languageCode,
  }) async {
    final l = _l(languageCode);
    try {
      final teamId = args['team_id'] as String;
      final teamMessage = args['message'] as String;
      final pendingId = DateTime.now().millisecondsSinceEpoch.toString();
      final reqJson = jsonEncode({
        'id': pendingId,
        'team_id': teamId,
        'message': teamMessage,
      });
      return '__PENDING_ANNOUNCEMENT__:$reqJson\n'
          '${l.aiPromptTeamAnnouncement}\n';
    } catch (e) {
      debugPrint('[NovaToolHandler] send_team_announcement error: $e');
      return '${l.aiToolErrorGeneric}\n';
    }
  }

  // ── Utilities ────────────────────────────────────────────────────────────

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static DateTime _parseDateTime(String dateStr, String timeStr) {
    try {
      return DateTime.parse('$dateStr $timeStr');
    } catch (_) {
      try {
        if (dateStr.contains('T')) return DateTime.parse(dateStr);

        final normalized = dateStr.replaceAll('.', '-').replaceAll('/', '-');
        final parts = normalized.split('-');
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
            final hour = int.tryParse(timeParts[0]) ?? 9;
            final minute =
                timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
            return DateTime(year, month, day, hour, minute);
          }
        }
      } catch (e) {
        debugPrint('[NovaToolHandler] Date parse error: $e');
      }
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
    }
  }
}
