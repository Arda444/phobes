import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/appointment_service.dart';
import '../../models/appointment_model.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/phobes_widgets.dart';
import '../../core/module_info_catalog.dart';
import '../../widgets/phobes_form_wrapper.dart';
import '../../core/phobes_detail_panel.dart';
import '../../widgets/phobes_module_header.dart';
import '../../core/phobes_theme.dart';
import 'views/timeline_view.dart';
import 'views/weekly_grid_view.dart';
import 'appointment_detail_screen.dart';
import 'appointment_add_edit_screen.dart';
import 'appointment_group_screen.dart';
import 'client_booking_screen.dart';

enum ApptViewMode { timeline, weekly, list }

class AppointmentScreen extends StatefulWidget {
  final VoidCallback? onClose;
  const AppointmentScreen({super.key, this.onClose});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen>
    with SingleTickerProviderStateMixin {
  final AppointmentService _service = AppointmentService();
  late TabController _tabController;
  Widget? _internalView;

  ApptViewMode _viewMode = ApptViewMode.timeline;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showInternalView(Widget view) => setState(() => _internalView = view);

  void _closeInternalView() => setState(() => _internalView = null);

  void _navigateDay(int delta) {
    setState(() {
      _selectedDate =
          DateUtils.dateOnly(_selectedDate).add(Duration(days: delta));
    });
  }

  void _goToToday() {
    setState(() => _selectedDate = DateUtils.dateOnly(DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmoled = PhobesTheme.amoledMode.value;

    return Scaffold(
      backgroundColor: isAmoled && isDark ? Colors.black : cs.surface,
      body: SafeArea(
        child: Stack(
          children: [
            NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                PhobesModuleHeader(
                  title: l10n.appointmentCenter,
                    icon: Icons.event_available_rounded,
                    onClose: () {
                      if (widget.onClose != null) {
                        widget.onClose!();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    info: ModuleInfoCatalog.forAppointments(l10n),
                    onAdd: () => PhobesFormWrapper.show(
                      context,
                      title: l10n.apptNewTitle,
                      form: AppointmentAddEditScreen(
                        onClose: () => Navigator.pop(context),
                      ),
                    ),
                    addTooltip: l10n.apptNewTitle,
                    extraActions: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: cs.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _viewModeButton(
                              Icons.view_day_rounded,
                              ApptViewMode.timeline,
                              cs,
                              l10n.apptTimeline,
                            ),
                            _viewModeButton(
                              Icons.calendar_view_week_rounded,
                              ApptViewMode.weekly,
                              cs,
                              l10n.apptWeeklyGrid,
                            ),
                            _viewModeButton(
                              Icons.list_rounded,
                              ApptViewMode.list,
                              cs,
                              l10n.apptListView,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      PhobesModuleHeaderIconButton(
                        icon: Icons.settings_suggest_outlined,
                        onTap: () => _showInternalView(
                          AppointmentGroupScreen(onClose: _closeInternalView),
                        ),
                      ),
                    ],
                    tabController: _tabController,
                    tabs: [
                      PhobesModuleTab(l10n.managementTab,
                          Icons.admin_panel_settings_rounded),
                      PhobesModuleTab(
                          l10n.myAppointmentsTab, Icons.person_rounded),
                    ],
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _ProviderTab(
                    service: _service,
                    viewMode: _viewMode,
                    selectedDate: _selectedDate,
                    locale: l10n.localeName,
                    onAppointmentTap: (appt) => PhobesDetailPanel.open(
                      context,
                      AppointmentDetailScreen(appointment: appt),
                    ),
                    onEditTap: (appt) => _showInternalView(
                      AppointmentAddEditScreen(
                        appointment: appt,
                        onClose: _closeInternalView,
                      ),
                    ),
                    onEmptySlotTap: (dt) => _showInternalView(
                      AppointmentAddEditScreen(
                        initialDate: dt,
                        onClose: _closeInternalView,
                      ),
                    ),
                    onDayTap: (day) {
                      setState(() => _selectedDate = DateUtils.dateOnly(day));
                    },
                    onNavigateDay: _navigateDay,
                    onGoToday: _goToToday,
                    l10n: l10n,
                  ),
                  _ClientTab(
                    service: _service,
                    viewMode: _viewMode,
                    selectedDate: _selectedDate,
                    locale: l10n.localeName,
                    onAppointmentTap: (appt) => PhobesDetailPanel.open(
                      context,
                      AppointmentDetailScreen(appointment: appt),
                    ),
                    onBookTap: () => _showInternalView(
                      ClientBookingScreen(
                        onClose: _closeInternalView,
                      ),
                    ),
                    onEmptySlotTap: (dt) => _showInternalView(
                      AppointmentAddEditScreen(
                        initialDate: dt,
                        onClose: _closeInternalView,
                      ),
                    ),
                    onDayTap: (day) {
                      setState(() => _selectedDate = DateUtils.dateOnly(day));
                    },
                    onNavigateDay: _navigateDay,
                    onGoToday: _goToToday,
                    l10n: l10n,
                  ),
                ],
              ),
            ),
            if (_internalView != null)
              Positioned.fill(
                child: Container(
                  color: isAmoled && isDark ? Colors.black : cs.surface,
                  child: _internalView,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _viewModeButton(
    IconData icon,
    ApptViewMode mode,
    ColorScheme cs,
    String tooltip,
  ) {
    final isActive = _viewMode == mode;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => setState(() => _viewMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isActive ? cs.primary.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? cs.primary : cs.onSurface.withOpacity(0.4),
          ),
        ),
      ),
    );
  }
}

List<Appointment> _appointmentsOnDay(
  List<Appointment> appointments,
  DateTime day,
) {
  final dayKey = DateUtils.dateOnly(day);
  return appointments
      .where((a) => DateUtils.dateOnly(a.date.toLocal()) == dayKey)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
}

Widget _buildTimelineDayView({
  required List<Appointment> appointments,
  required DateTime selectedDate,
  required ColorScheme cs,
  required AppLocalizations l10n,
  required void Function(Appointment) onAppointmentTap,
  required void Function(DateTime) onEmptySlotTap,
}) {
  final dayAppts = _appointmentsOnDay(appointments, selectedDate);

  if (dayAppts.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 36,
            color: cs.onSurface.withOpacity(0.12),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.msgNoAppointments,
            style: GoogleFonts.outfit(
              color: cs.onSurface.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  return LayoutBuilder(
    builder: (context, constraints) {
      final w = constraints.maxWidth;
      final cols = w >= 1500
          ? 4
          : w >= 1100
              ? 3
              : w >= 700
                  ? 2
                  : 1;
      if (cols == 1) {
        return ListView.builder(
          primary: false,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
          itemCount: dayAppts.length,
          itemBuilder: (context, index) {
            final appt = dayAppts[index];
            return _ListAppointmentCard(
              appointment: appt,
              l10n: l10n,
              onTap: () => onAppointmentTap(appt),
            );
          },
        );
      }
      return GridView.builder(
        primary: false,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 112,
        ),
        itemCount: dayAppts.length,
        itemBuilder: (context, index) {
          final appt = dayAppts[index];
          return _ListAppointmentCard(
            appointment: appt,
            l10n: l10n,
            onTap: () => onAppointmentTap(appt),
          );
        },
      );
    },
  );
}

// ─── Paylaşılan istatistik satırı ─────────────────────────────────────────────

class _AppointmentStatsRow extends StatelessWidget {
  final List<Appointment> appointments;

  const _AppointmentStatsRow({required this.appointments});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final pending =
        appointments.where((a) => a.status == 'pending').length;
    final confirmed =
        appointments.where((a) => a.status == 'confirmed').length;
    final cancelled =
        appointments.where((a) => a.status == 'cancelled').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          _statCard(
              l10n.filterAll, appointments.length.toString(), Colors.blue, cs),
          const SizedBox(width: 8),
          _statCard(l10n.statusPending, pending.toString(), Colors.orange, cs),
          const SizedBox(width: 8),
          _statCard(
              l10n.statusConfirmed, confirmed.toString(), Colors.green, cs),
          const SizedBox(width: 8),
          _statCard(
              l10n.statusCancelled, cancelled.toString(), Colors.red, cs),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, ColorScheme cs) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Provider (Yönetim) Tab ───────────────────────────────────────────────────

class _ProviderTab extends StatefulWidget {
  final AppointmentService service;
  final ApptViewMode viewMode;
  final DateTime selectedDate;
  final String locale;
  final Function(Appointment) onAppointmentTap;
  final Function(Appointment) onEditTap;
  final Function(DateTime) onEmptySlotTap;
  final Function(DateTime) onDayTap;
  final Function(int) onNavigateDay;
  final VoidCallback onGoToday;
  final AppLocalizations l10n;

  const _ProviderTab({
    required this.service,
    required this.viewMode,
    required this.selectedDate,
    required this.locale,
    required this.onAppointmentTap,
    required this.onEditTap,
    required this.onEmptySlotTap,
    required this.onDayTap,
    required this.onNavigateDay,
    required this.onGoToday,
    required this.l10n,
  });

  @override
  State<_ProviderTab> createState() => _ProviderTabState();
}

class _ProviderTabState extends State<_ProviderTab> {
  String _searchQuery = '';
  final String _statusFilter = 'all';
  late Stream<List<Appointment>> _appointmentsStream;

  List<Appointment> _cached = [];

  @override
  void initState() {
    super.initState();
    _appointmentsStream = _createStream();
  }

  @override
  void didUpdateWidget(covariant _ProviderTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewMode != widget.viewMode) {
      _appointmentsStream = _createStream();
    }
  }

  Stream<List<Appointment>> _createStream() {
    if (widget.viewMode == ApptViewMode.weekly) {
      final monday = widget.selectedDate
          .subtract(Duration(days: widget.selectedDate.weekday - 1));
      final sunday =
          monday.add(const Duration(days: 6, hours: 23, minutes: 59));
      return widget.service.getAppointmentsForDateRange(monday, sunday);
    }
    return widget.service.getAppointmentsStream();
  }

  List<Appointment> _managementAppointments(List<Appointment> raw) =>
      raw
          .where((a) => a.groupId != null && a.groupId!.isNotEmpty)
          .toList();

  Widget _buildHeader(
    AppLocalizations l10n,
    ColorScheme cs,
    List<Appointment> managementAppts,
  ) {
    return Column(
      children: [
        _AppointmentStatsRow(appointments: managementAppts),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
          child: PhobesTextField(
            hintText: l10n.apptSearchHint,
            prefixIcon: Icons.search_rounded,
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        if (widget.viewMode == ApptViewMode.timeline) _buildDateNavigator(cs),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Builder(
      builder: (nestedContext) => StreamBuilder<List<Appointment>>(
        stream: _appointmentsStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _cached = snapshot.data!;
          }
          final raw = snapshot.data ?? _cached;
          final managementAppts = _managementAppointments(raw);
          final header = _buildHeader(widget.l10n, cs, managementAppts);

          return ModuleNestedScroll.scrollView(
            context: nestedContext,
            slivers: [
              SliverToBoxAdapter(child: header),
              SliverFillRemaining(
                hasScrollBody: widget.viewMode == ApptViewMode.timeline,
                child: _buildView(
                  managementAppts,
                  cs,
                  timelineAppointments: raw,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateNavigator(ColorScheme cs) {
    final l10n = widget.l10n;
    final isToday = TimelineView.isSameCalendarDay(
      widget.selectedDate,
      DateTime.now(),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => widget.onNavigateDay(-1),
            child: Icon(
              Icons.chevron_left_rounded,
              color: cs.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: widget.onGoToday,
              child: Column(
                children: [
                  Text(
                    DateFormat('d MMMM EEEE', widget.locale)
                        .format(widget.selectedDate),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!isToday)
                    Text(
                      l10n.apptToday,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: cs.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => widget.onNavigateDay(1),
            child: Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildView(
    List<Appointment> appointments,
    ColorScheme cs, {
    List<Appointment>? timelineAppointments,
  }) {
    final l10n = widget.l10n;
    // Apply status + search filters
    var filtered = _statusFilter == 'all'
        ? appointments
        : _statusFilter == 'today'
            ? appointments.where((a) => a.isToday).toList()
            : appointments.where((a) => a.status == _statusFilter).toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (a) =>
                a.title.toLowerCase().contains(q) ||
                a.clientName.toLowerCase().contains(q) ||
                (a.notes?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }

    switch (widget.viewMode) {
      case ApptViewMode.timeline:
        return _buildTimelineDayView(
          appointments: timelineAppointments ?? filtered,
          selectedDate: widget.selectedDate,
          cs: cs,
          l10n: l10n,
          onAppointmentTap: widget.onAppointmentTap,
          onEmptySlotTap: widget.onEmptySlotTap,
        );

      case ApptViewMode.weekly:
        return WeeklyGridView(
          focusedDate: widget.selectedDate,
          appointments: filtered,
          onAppointmentTap: widget.onAppointmentTap,
          onEmptySlotTap: widget.onEmptySlotTap,
          onDayTap: widget.onDayTap,
          locale: widget.locale,
        );

      case ApptViewMode.list:
        final sorted = List<Appointment>.from(filtered)
          ..sort((a, b) => a.date.compareTo(b.date));

        if (sorted.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_rounded,
                  size: 56,
                  color: cs.onSurface.withOpacity(0.1),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.msgNoAppointments,
                  style: GoogleFonts.outfit(
                    color: cs.onSurface.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final cols = w >= 1500
                ? 4
                : w >= 1100
                    ? 3
                    : w >= 700
                        ? 2
                        : 1;
            if (cols == 1) {
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final appt = sorted[index];
                  return _ListAppointmentCard(
                    appointment: appt,
                    l10n: l10n,
                    onTap: () => widget.onAppointmentTap(appt),
                  );
                },
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 112,
              ),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final appt = sorted[index];
                return _ListAppointmentCard(
                  appointment: appt,
                  l10n: l10n,
                  onTap: () => widget.onAppointmentTap(appt),
                );
              },
            );
          },
        );
    }
  }
}

// ─── Client (Randevularım) Tab ────────────────────────────────────────────────

class _ClientTab extends StatefulWidget {
  final AppointmentService service;
  final ApptViewMode viewMode;
  final DateTime selectedDate;
  final String locale;
  final AppLocalizations l10n;
  final Function(Appointment) onAppointmentTap;
  final VoidCallback onBookTap;
  final Function(DateTime) onEmptySlotTap;
  final Function(DateTime) onDayTap;
  final Function(int) onNavigateDay;
  final VoidCallback onGoToday;

  const _ClientTab({
    required this.service,
    required this.viewMode,
    required this.selectedDate,
    required this.locale,
    required this.l10n,
    required this.onAppointmentTap,
    required this.onBookTap,
    required this.onEmptySlotTap,
    required this.onDayTap,
    required this.onNavigateDay,
    required this.onGoToday,
  });

  @override
  State<_ClientTab> createState() => _ClientTabState();
}

class _ClientTabState extends State<_ClientTab> {
  late final Stream<List<Appointment>> _appointmentsStream;
  String _searchQuery = '';
  List<Appointment> _cached = [];

  @override
  void initState() {
    super.initState();
    _appointmentsStream = widget.service.getMyAppointmentsAsClientStream();
  }

  Widget _buildHeader(ColorScheme cs, List<Appointment> appointments) {
    return Column(
      children: [
        _AppointmentStatsRow(appointments: appointments),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
          child: PhobesTextField(
            hintText: widget.l10n.apptSearchHint,
            prefixIcon: Icons.search_rounded,
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        if (widget.viewMode == ApptViewMode.timeline) _buildDateNavigator(cs),
      ],
    );
  }

  Widget _buildDateNavigator(ColorScheme cs) {
    final l10n = widget.l10n;
    final isToday = TimelineView.isSameCalendarDay(
      widget.selectedDate,
      DateTime.now(),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => widget.onNavigateDay(-1),
            child: Icon(
              Icons.chevron_left_rounded,
              color: cs.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: widget.onGoToday,
              child: Column(
                children: [
                  Text(
                    DateFormat('d MMMM EEEE', widget.locale)
                        .format(widget.selectedDate),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!isToday)
                    Text(
                      l10n.apptToday,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: cs.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => widget.onNavigateDay(1),
            child: Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientView(List<Appointment> appointments, ColorScheme cs) {
    final l10n = widget.l10n;
    var filtered = appointments;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (a) =>
                a.title.toLowerCase().contains(q) ||
                a.clientName.toLowerCase().contains(q) ||
                (a.notes?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }

    switch (widget.viewMode) {
      case ApptViewMode.timeline:
        return _buildTimelineDayView(
          appointments: filtered,
          selectedDate: widget.selectedDate,
          cs: cs,
          l10n: l10n,
          onAppointmentTap: widget.onAppointmentTap,
          onEmptySlotTap: widget.onEmptySlotTap,
        );

      case ApptViewMode.weekly:
        return WeeklyGridView(
          focusedDate: widget.selectedDate,
          appointments: filtered,
          onAppointmentTap: widget.onAppointmentTap,
          onEmptySlotTap: widget.onEmptySlotTap,
          onDayTap: widget.onDayTap,
          locale: widget.locale,
        );

      case ApptViewMode.list:
        final sorted = List<Appointment>.from(filtered)
          ..sort((a, b) => a.date.compareTo(b.date));

        if (sorted.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_rounded,
                  size: 36,
                  color: cs.onSurface.withOpacity(0.12),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.msgNoAppointments,
                  style: GoogleFonts.outfit(
                    color: cs.onSurface.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final cols = w >= 1500
                ? 4
                : w >= 1100
                    ? 3
                    : w >= 700
                        ? 2
                        : 1;
            if (cols == 1) {
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final appt = sorted[index];
                  return _ListAppointmentCard(
                    appointment: appt,
                    l10n: l10n,
                    onTap: () => widget.onAppointmentTap(appt),
                  );
                },
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 112,
              ),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final appt = sorted[index];
                return _ListAppointmentCard(
                  appointment: appt,
                  l10n: l10n,
                  onTap: () => widget.onAppointmentTap(appt),
                );
              },
            );
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Builder(
      builder: (nestedContext) => StreamBuilder<List<Appointment>>(
        stream: _appointmentsStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _cached = snapshot.data!;
          }
          final appointments = snapshot.data ?? _cached;

          if (appointments.isEmpty && !snapshot.hasData) {
            return ModuleNestedScroll.centered(
              context: nestedContext,
              child: PhobesEmptyState(
                icon: Icons.event_note_rounded,
                title: widget.l10n.msgNoAppointments,
                buttonText: widget.l10n.bookAppointment,
                buttonIcon: Icons.add_rounded,
                onButtonTap: widget.onBookTap,
              ),
            );
          }

          if (appointments.isEmpty) {
            return ModuleNestedScroll.scrollView(
              context: nestedContext,
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(cs, appointments)),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: PhobesEmptyState(
                      icon: Icons.event_note_rounded,
                      title: widget.l10n.msgNoAppointments,
                      buttonText: widget.l10n.bookAppointment,
                      buttonIcon: Icons.add_rounded,
                      onButtonTap: widget.onBookTap,
                    ),
                  ),
                ),
              ],
            );
          }

          return ModuleNestedScroll.scrollView(
            context: nestedContext,
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(cs, appointments)),
              SliverFillRemaining(
                hasScrollBody: widget.viewMode == ApptViewMode.timeline,
                child: _buildClientView(appointments, cs),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _ListAppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _ListAppointmentCard({
    required this.appointment,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = Color(appointment.color);
    final dateStr =
        DateFormat('d MMM', l10n.localeName).format(appointment.date);
    final timeStr = DateFormat('HH:mm').format(appointment.date);
    final isCancelled = appointment.status == 'cancelled';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PhobesCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Sol renk şeridi + tarih
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.12)),
              ),
              child: Column(
                children: [
                  Text(
                    dateStr.split(' ').first,
                    style: GoogleFonts.outfit(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    dateStr.split(' ').length > 1
                        ? dateStr.split(' ').last
                        : '',
                    style: GoogleFonts.outfit(
                      color: color.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    timeStr,
                    style: GoogleFonts.outfit(
                      color: cs.onSurface.withOpacity(0.4),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // İçerik
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.title,
                    style: GoogleFonts.outfit(
                      color: isCancelled
                          ? cs.onSurface.withOpacity(0.35)
                          : cs.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration:
                          isCancelled ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 13,
                        color: cs.onSurface.withOpacity(0.35),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          appointment.clientName,
                          style: GoogleFonts.outfit(
                            color: cs.onSurface.withOpacity(0.45),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Durum pill
            _StatusPill(status: appointment.status, l10n: l10n),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  final AppLocalizations l10n;

  const _StatusPill({required this.status, required this.l10n});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    switch (status) {
      case 'confirmed':
        color = const Color(0xFF10B981);
        text = l10n.statusConfirmed;
        break;
      case 'cancelled':
        color = const Color(0xFFEF4444);
        text = l10n.statusCancelled;
        break;
      case 'completed':
        color = const Color(0xFF6B7280);
        text = l10n.statusCompleted;
        break;
      default:
        color = const Color(0xFFF59E0B);
        text = l10n.statusPending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
