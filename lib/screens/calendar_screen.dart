import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt; // EKLENDİ
import '../l10n/app_localizations.dart';
import '../models/task_model.dart';
import '../models/note_model.dart';
import '../services/firebase_service.dart';
import '../services/nova_service.dart';
import 'task_add_edit_screen.dart';
import 'note_add_edit_screen.dart';
import 'task_detail_screen.dart';

enum CalendarFilter { all, personal, team }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fabController;
  late final Animation<double> _fabAnimation;
  late final AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final FirebaseService _firebaseService = FirebaseService();
  late Stream<List<Note>> _notesStream;

  CalendarFilter _currentFilter = CalendarFilter.all;
  String? _weeklyNote;
  int _direction = 0;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _notesStream = _firebaseService.getNotesStream();

    _fabController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fabAnimation =
        CurvedAnimation(parent: _fabController, curve: Curves.easeOutBack);
    _fabController.forward();

    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _slideController, curve: Curves.easeInOutCubic));
  }

  @override
  void dispose() {
    _fabController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Map<DateTime, List<Task>> _processTasksForCalendar(List<Task> tasks) {
    final map = <DateTime, List<Task>>{};
    final DateTime endDate = DateTime.now().add(const Duration(days: 365));

    for (final t in tasks) {
      bool show = true;
      if (_currentFilter == CalendarFilter.personal && t.groupId != null) {
        show = false;
      }
      if (_currentFilter == CalendarFilter.team && t.groupId == null) {
        show = false;
      }
      if (!show) continue;

      if (t.repeatRule == 'none') {
        final dateOnly = DateUtils.dateOnly(t.startTime);
        map[dateOnly] = [...?map[dateOnly], t];
        continue;
      }

      DateTime nextDate = t.startTime;
      while (nextDate.isBefore(endDate)) {
        final dateOnly = DateUtils.dateOnly(nextDate);
        final virtualTask = t.copyWith(
          startTime: DateTime(nextDate.year, nextDate.month, nextDate.day,
              t.startTime.hour, t.startTime.minute),
          endTime: DateTime(nextDate.year, nextDate.month, nextDate.day,
              t.endTime.hour, t.endTime.minute),
        );
        map[dateOnly] = [...?map[dateOnly], virtualTask];

        if (t.repeatRule == 'daily') {
          nextDate = nextDate.add(const Duration(days: 1));
        } else if (t.repeatRule == 'weekly') {
          nextDate = nextDate.add(const Duration(days: 7));
        } else if (t.repeatRule == 'monthly') {
          var newYear = nextDate.year;
          var newMonth = nextDate.month + 1;
          if (newMonth > 12) {
            newMonth = 1;
            newYear++;
          }
          var daysInNewMonth = DateUtils.getDaysInMonth(newYear, newMonth);
          var newDay = t.startTime.day > daysInNewMonth
              ? daysInNewMonth
              : t.startTime.day;
          nextDate = DateTime(
              newYear, newMonth, newDay, t.startTime.hour, t.startTime.minute);
        } else {
          break;
        }
      }
    }
    return map;
  }

  Map<DateTime, List<Note>> _processNotesForCalendar(List<Note> notes) {
    final map = <DateTime, List<Note>>{};
    for (final n in notes) {
      final day = DateUtils.dateOnly(n.date);
      map[day] = [...?map[day], n];
    }
    return map;
  }

  void _goToToday() {
    setState(() {
      _focusedDay = DateTime.now();
      _selectedDay = DateTime.now();
      _direction = 0;
    });
    _startSlideAnimation();
  }

  void _goToPreviousWeek() {
    setState(() {
      _focusedDay = _focusedDay.subtract(const Duration(days: 7));
      _direction = -1;
    });
    _startSlideAnimation();
  }

  void _goToNextWeek() {
    setState(() {
      _focusedDay = _focusedDay.add(const Duration(days: 7));
      _direction = 1;
    });
    _startSlideAnimation();
  }

  void _startSlideAnimation() {
    _slideController.reset();
    _slideAnimation = Tween<Offset>(
            begin: Offset(_direction.toDouble(), 0.0), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _slideController, curve: Curves.easeInOutCubic));
    _slideController.forward();
  }

  void _editWeeklyNote() {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(
        text: _weeklyNote == l10n.writeYourNotes ? "" : _weeklyNote);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(l10n.weeklyNotesTitle,
            style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 5,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
              hintText: l10n.writeYourNotes,
              hintStyle: const TextStyle(color: Colors.grey)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel)),
          ElevatedButton(
              onPressed: () {
                setState(() => _weeklyNote = controller.text);
                Navigator.pop(context);
              },
              child: Text(l10n.save))
        ],
      ),
    );
  }

  List<DateTime> _getWeekDays(DateTime focused) {
    DateTime startOfWeek =
        focused.subtract(Duration(days: focused.weekday - 1));
    return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
  }

  void _showDayMenu(DateTime day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _EventListSheet(day: day, currentFilter: _currentFilter),
    );
  }

  // --- NOVA AI SİHİRBAZI (MİKROFON EKLENDİ) ---
  void _showNovaWizard() {
    final TextEditingController promptController = TextEditingController();
    bool isLoading = false;
    bool isListening = false;
    stt.SpeechToText speech = stt.SpeechToText();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) => StatefulBuilder(
        builder: (sheetContext, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          const Icon(Icons.auto_fix_high, color: Colors.teal),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Nova Asistan",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "Yaz veya konuş, senin için göreve çevireyim.",
                  style:
                      GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: promptController,
                  style: GoogleFonts.poppins(color: Colors.white),
                  maxLines: 3,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "Buraya yaz...",
                    hintStyle: GoogleFonts.poppins(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.black38,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    // MİKROFON İKONU
                    suffixIcon: IconButton(
                      icon: Icon(
                        isListening ? Icons.mic : Icons.mic_none,
                        color:
                            isListening ? Colors.redAccent : Colors.tealAccent,
                      ),
                      onPressed: () async {
                        if (!isListening) {
                          bool available = await speech.initialize();
                          if (available) {
                            setModalState(() => isListening = true);
                            speech.listen(onResult: (result) {
                              promptController.text = result.recognizedWords;
                              if (result.finalResult) {
                                setModalState(() => isListening = false);
                              }
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Mikrofon izni yok.")));
                          }
                        } else {
                          setModalState(() => isListening = false);
                          speech.stop();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isLoading
                        ? null
                        : () async {
                            final text = promptController.text.trim();
                            if (text.isEmpty) return;

                            setModalState(() => isLoading = true);

                            try {
                              final novaService = NovaService();
                              final generatedTask =
                                  await novaService.createTaskFromText(text);

                              if (modalContext.mounted) {
                                Navigator.pop(modalContext);
                              }

                              if (generatedTask != null) {
                                if (mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TaskAddEditScreen(
                                        selectedDate: generatedTask.startTime,
                                        task: generatedTask,
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text("Nova anlayamadı.")));
                                }
                              }
                            } catch (e) {
                              setModalState(() => isLoading = false);
                            }
                          },
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Colors.white),
                              const SizedBox(width: 8),
                              Text("Oluştur",
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _weeklyNote ??= l10n.writeYourNotes;
    final weekDays = _getWeekDays(_focusedDay);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              child: Text(
                  DateFormat('MMMM yyyy', l10n.localeName).format(_focusedDay),
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: Colors.white)),
            ),
            Text(
                _currentFilter == CalendarFilter.all
                    ? l10n.filterAll
                    : (_currentFilter == CalendarFilter.personal
                        ? l10n.filterPersonal
                        : l10n.filterTeam),
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          PopupMenuButton<CalendarFilter>(
            icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
            color: Colors.grey.shade900,
            onSelected: (CalendarFilter result) {
              setState(() {
                _currentFilter = result;
              });
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<CalendarFilter>>[
              PopupMenuItem<CalendarFilter>(
                value: CalendarFilter.all,
                child: Text(l10n.filterAll,
                    style: TextStyle(
                        color: _currentFilter == CalendarFilter.all
                            ? Colors.blue
                            : Colors.white)),
              ),
              PopupMenuItem<CalendarFilter>(
                value: CalendarFilter.personal,
                child: Text(l10n.filterPersonal,
                    style: TextStyle(
                        color: _currentFilter == CalendarFilter.personal
                            ? Colors.blue
                            : Colors.white)),
              ),
              PopupMenuItem<CalendarFilter>(
                value: CalendarFilter.team,
                child: Text(l10n.filterTeam,
                    style: TextStyle(
                        color: _currentFilter == CalendarFilter.team
                            ? Colors.blue
                            : Colors.white)),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.article_rounded, color: Colors.white),
            onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _AllNotesSheet()),
          ),
          IconButton(
              icon: const Icon(Icons.today_rounded, color: Colors.white),
              onPressed: _goToToday),
        ],
      ),
      body: StreamBuilder<List<Task>>(
        stream: _firebaseService.getAllUserTasksStream(),
        builder: (context, taskSnapshot) {
          return StreamBuilder<List<Note>>(
            stream: _notesStream,
            builder: (context, noteSnapshot) {
              if (taskSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.purple));
              }

              final tasks = taskSnapshot.data ?? [];
              final notes = noteSnapshot.data ?? [];

              final eventsMap = _processTasksForCalendar(tasks);
              final notesMap = _processNotesForCalendar(notes);

              return Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(children: [
                      _navButton(Icons.chevron_left_rounded, _goToPreviousWeek),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(
                              '${DateFormat('d MMM', l10n.localeName).format(weekDays[0])} - ${DateFormat('d MMM yyyy', l10n.localeName).format(weekDays[6])}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                  fontSize: 14, color: Colors.white70))),
                      const SizedBox(width: 12),
                      _navButton(Icons.chevron_right_rounded, _goToNextWeek),
                    ]),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity! > 500) {
                          _goToPreviousWeek();
                        } else if (details.primaryVelocity! < -500) {
                          _goToNextWeek();
                        }
                      },
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: SizedBox(
                          width: screenWidth,
                          child: Column(
                            children: [
                              Expanded(
                                  flex: 1,
                                  child: _buildRow(weekDays.sublist(0, 3),
                                      eventsMap, notesMap)),
                              Expanded(
                                  flex: 1,
                                  child: _buildRow(weekDays.sublist(3, 6),
                                      eventsMap, notesMap)),
                              Expanded(
                                  flex: 1,
                                  child: _buildThirdRow(
                                      weekDays[6], l10n, eventsMap, notesMap)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: FloatingActionButton.small(
              heroTag: 'fab_nova',
              backgroundColor: Colors.teal,
              onPressed: _showNovaWizard,
              tooltip: 'Nova AI ile Oluştur',
              child: const Icon(Icons.auto_fix_high, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          ElasticIn(
            child: ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton(
                heroTag: 'fab_calendar',
                backgroundColor: Colors.purple.shade600,
                elevation: 12,
                onPressed: () async {
                  _fabController.reverse();
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => TaskAddEditScreen(
                              selectedDate: _selectedDay ?? DateTime.now())));
                  _fabController.forward();
                },
                child: const Icon(Icons.add_rounded, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade800,
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16))),
        child: Icon(icon, size: 28));
  }

  Widget _buildRow(List<DateTime> days, Map<DateTime, List<Task>> eventsMap,
      Map<DateTime, List<Note>> notesMap) {
    return Row(
        children:
            days.map((day) => _buildDayBox(day, eventsMap, notesMap)).toList());
  }

  Widget _buildThirdRow(DateTime sunday, AppLocalizations l10n,
      Map<DateTime, List<Task>> eventsMap, Map<DateTime, List<Note>> notesMap) {
    return Row(children: [
      _buildDayBox(sunday, eventsMap, notesMap),
      Expanded(flex: 2, child: _buildWeeklyNoteBox(l10n)),
    ]);
  }

  Widget _buildWeeklyNoteBox(AppLocalizations l10n) {
    return FadeInUp(
      child: GestureDetector(
        onTap: _editWeeklyNote,
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.shade600)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.weeklyNotesTitle,
                  style: GoogleFonts.poppins(
                      color: Colors.purple.shade300,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Expanded(
                  child: Text(_weeklyNote!,
                      style: GoogleFonts.poppins(
                          color: Colors.white70, fontSize: 12),
                      maxLines: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayBox(DateTime day, Map<DateTime, List<Task>> eventsMap,
      Map<DateTime, List<Note>> notesMap) {
    final l10n = AppLocalizations.of(context)!;
    final dateKey = DateUtils.dateOnly(day);

    final events = eventsMap[dateKey] ?? [];
    final notes = notesMap[dateKey] ?? [];

    final isToday = DateUtils.isSameDay(day, DateTime.now());
    final isSelected = DateUtils.isSameDay(day, _selectedDay);

    const int maxItems = 3;
    final int notesToShow = (maxItems - events.length).clamp(0, maxItems);
    final int totalItems = events.length + notes.length;
    final int hiddenCount = totalItems > maxItems ? totalItems - maxItems : 0;

    return Expanded(
      child: FadeInUp(
        child: GestureDetector(
          onTap: () {
            setState(() => _selectedDay = day);
            _showDayMenu(day);
          },
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: isToday
                      ? [Colors.orange.shade700, Colors.orange.shade900]
                      : isSelected
                          ? [Colors.purple.shade600, Colors.purple.shade800]
                          : [Colors.grey.shade900, Colors.grey.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade700, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                        DateFormat('EEE', l10n.localeName)
                            .format(day)
                            .toUpperCase(),
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600))),
                Text('${day.day}',
                    style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ...events.take(maxItems).map((e) => _buildItemChip(
                          e.title, Color(e.color), e.isCompleted)),
                      ...notes.take(notesToShow).map((n) => _buildItemChip(
                          n.title.isEmpty ? l10n.untitledNote : n.title,
                          Colors.orange.shade700,
                          false)),
                    ],
                  ),
                ),
                if (hiddenCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(l10n.hiddenItemsCount(hiddenCount),
                        style: GoogleFonts.poppins(
                            fontSize: 9, color: Colors.white70)),
                  ),
                if (hiddenCount == 0) const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemChip(String title, Color color, bool isCompleted) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
          color: isCompleted
              ? color.withValues(alpha: 0.4)
              : color.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(4)),
      child: Text(title,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
              fontSize: 9,
              color: isCompleted ? Colors.white54 : Colors.white,
              decoration: isCompleted
                  ? TextDecoration.lineThrough
                  : TextDecoration.none),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
    );
  }
}

class _EventListSheet extends StatefulWidget {
  final DateTime day;
  final CalendarFilter currentFilter;
  const _EventListSheet({required this.day, required this.currentFilter});
  @override
  State<_EventListSheet> createState() => _EventListSheetState();
}

class _EventListSheetState extends State<_EventListSheet> {
  final FirebaseService _firebaseService = FirebaseService();
  int? _expandedTaskIndex;

  void _showPostponeMenu(BuildContext context, Task task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (ctx) => Wrap(
        children: [
          _buildPostponeItem(
              ctx, task, "15 Dakika", const Duration(minutes: 15)),
          _buildPostponeItem(ctx, task, "1 Saat", const Duration(hours: 1)),
          _buildPostponeItem(ctx, task, "Yarına", const Duration(days: 1)),
        ],
      ),
    );
  }

  Widget _buildPostponeItem(
      BuildContext ctx, Task task, String label, Duration duration) {
    return ListTile(
      leading: const Icon(Icons.update, color: Colors.white70),
      title: Text(label, style: GoogleFonts.poppins(color: Colors.white)),
      onTap: () async {
        await _firebaseService.updateTask(task.copyWith(
          startTime: task.startTime.add(duration),
          endTime: task.endTime.add(duration),
          postponeCount: task.postponeCount + 1,
        ));
        if (ctx.mounted) Navigator.pop(ctx);
      },
    );
  }

  void _confirmDelete(Task task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text("Sil", style: TextStyle(color: Colors.white)),
        content: const Text("Emin misiniz?",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _firebaseService.deleteTask(task.id!);
              Navigator.pop(ctx);
            },
            child: const Text("Sil"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Container(
            width: 60,
            height: 6,
            decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(3))),
        const SizedBox(height: 16),
        Text(DateFormat('d MMMM yyyy', l10n.localeName).format(widget.day),
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
                child: _buildQuickActionBtn(
                    icon: Icons.event,
                    label: l10n.addEvent,
                    color: Colors.blue.shade700,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  TaskAddEditScreen(selectedDate: widget.day)));
                    })),
            const SizedBox(width: 12),
            Expanded(
                child: _buildQuickActionBtn(
                    icon: Icons.note_add,
                    label: l10n.addNote,
                    color: Colors.green.shade700,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  NoteAddEditScreen(selectedDate: widget.day)));
                    })),
            const SizedBox(width: 12),
            Expanded(
                child: _buildQuickActionBtn(
                    icon: Icons.description,
                    label: l10n.allNotes,
                    color: Colors.purple.shade700,
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => _AllNotesSheet());
                    })),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(color: Colors.white10),
        Expanded(
            child: StreamBuilder<List<Task>>(
                stream: _firebaseService.getAllUserTasksStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final tasks = snapshot.data ?? [];
                  final dailyTasks = tasks.where((t) {
                    bool isSameDay = false;
                    if (t.repeatRule == 'none') {
                      isSameDay = DateUtils.isSameDay(t.startTime, widget.day);
                    } else if (t.startTime.isAfter(widget.day)) {
                      isSameDay = false;
                    } else if (t.repeatRule == 'daily') {
                      isSameDay = true;
                    } else if (t.repeatRule == 'weekly') {
                      isSameDay = t.startTime.weekday == widget.day.weekday;
                    } else if (t.repeatRule == 'monthly') {
                      isSameDay = t.startTime.day == widget.day.day;
                    }

                    if (!isSameDay) return false;

                    if (widget.currentFilter == CalendarFilter.personal &&
                        t.groupId != null) {
                      return false;
                    }
                    if (widget.currentFilter == CalendarFilter.team &&
                        t.groupId == null) {
                      return false;
                    }

                    return true;
                  }).toList();

                  if (dailyTasks.isEmpty) {
                    return Center(
                        child: Text(l10n.noEvents,
                            style: GoogleFonts.poppins(
                                color: Colors.grey.shade500)));
                  }

                  return ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                    itemCount: dailyTasks.length,
                    itemBuilder: (context, i) {
                      final e = dailyTasks[i];
                      final isTeamTask = e.groupId != null;
                      final bool isExpanded = _expandedTaskIndex == i;

                      return FadeInUp(
                        delay: Duration(milliseconds: i * 50),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(16),
                              border: isExpanded
                                  ? Border.all(
                                      color:
                                          Colors.purple.withValues(alpha: 0.5))
                                  : Border.all(color: Colors.white10)),
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                onTap: () => setState(() =>
                                    _expandedTaskIndex = isExpanded ? null : i),
                                leading: Container(
                                    width: 4,
                                    height: 40,
                                    decoration: BoxDecoration(
                                        color: Color(e.color),
                                        borderRadius:
                                            BorderRadius.circular(2))),
                                title: Text(e.title,
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                        decoration: e.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null)),
                                subtitle: Row(
                                  children: [
                                    Text(
                                        DateFormat('HH:mm').format(e.startTime),
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 12)),
                                    if (isTeamTask) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: Colors.indigo.shade900,
                                              borderRadius:
                                                  BorderRadius.circular(4)),
                                          child: Text(l10n.team,
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white)))
                                    ]
                                  ],
                                ),
                                trailing: Icon(
                                    isExpanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: Colors.white54),
                              ),
                              if (isExpanded)
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                  child: Column(
                                    children: [
                                      const Divider(
                                          color: Colors.white10, height: 1),
                                      const SizedBox(height: 8),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _actionButton(
                                              icon: e.isCompleted
                                                  ? Icons.check_circle
                                                  : Icons.check_circle_outline,
                                              color: Colors.green,
                                              label: "Tamamla",
                                              onTap: () => _firebaseService
                                                  .updateTask(e.copyWith(
                                                      isCompleted:
                                                          !e.isCompleted)),
                                            ),
                                            _actionButton(
                                                icon: Icons.info_outline,
                                                color: Colors.blueGrey,
                                                label: "Detay",
                                                onTap: () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (_) =>
                                                            TaskDetailScreen(
                                                                task: e)))),
                                            _actionButton(
                                                icon: Icons.edit,
                                                color: Colors.blue,
                                                label: "Düzenle",
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (_) =>
                                                              TaskAddEditScreen(
                                                                  selectedDate:
                                                                      e.startTime,
                                                                  task: e)));
                                                }),
                                            _actionButton(
                                                icon: Icons.update,
                                                color: Colors.orange,
                                                label: "Ertele",
                                                onTap: () => _showPostponeMenu(
                                                    context, e)),
                                            _actionButton(
                                                icon: Icons.delete,
                                                color: Colors.red,
                                                label: "Sil",
                                                onTap: () => _confirmDelete(e)),
                                          ]),
                                    ],
                                  ),
                                )
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }))
      ]),
    );
  }

  Widget _buildQuickActionBtn(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis)
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
      {required IconData icon,
      required Color color,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10))
        ]),
      ),
    );
  }
}

class _AllNotesSheet extends StatelessWidget {
  final FirebaseService _firebaseService = FirebaseService();
  _AllNotesSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(children: [
        const SizedBox(height: 20),
        Text(l10n.allNotes,
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
        Expanded(
            child: StreamBuilder<List<Note>>(
                stream: _firebaseService.getNotesStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, i) {
                        final note = snapshot.data![i];
                        return ListTile(
                            leading: const Icon(Icons.description,
                                color: Colors.blueGrey),
                            title: Text(
                                note.title.isEmpty
                                    ? l10n.untitledNote
                                    : note.title,
                                style: const TextStyle(color: Colors.white)),
                            subtitle: Text(
                                DateFormat('d MMM yyyy').format(note.date),
                                style: const TextStyle(color: Colors.grey)),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => NoteAddEditScreen(
                                        selectedDate: note.date, note: note))));
                      });
                }))
      ]),
    );
  }
}
