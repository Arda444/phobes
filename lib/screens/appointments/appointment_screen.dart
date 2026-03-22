import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/firebase_service.dart';
import '../../models/appointment_model.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/phobes_widgets.dart';
import 'appointment_detail_screen.dart';
import 'appointment_add_edit_screen.dart';
import 'appointment_group_screen.dart';
import 'client_booking_screen.dart';

class AppointmentScreen extends StatefulWidget {
  final VoidCallback? onClose;
  const AppointmentScreen({super.key, this.onClose});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Widget? _internalView;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(context, l10n),
                    const SizedBox(height: 16),
                    _buildCustomTabBar(l10n),
                    const SizedBox(height: 10),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _ProviderDashboardTab(
                            onAppointmentTap: (appt) => _showInternalView(
                                AppointmentDetailScreen(
                                    appointment: appt,
                                    onClose: _closeInternalView)),
                            onEditTap: (appt) => _showInternalView(
                                AppointmentAddEditScreen(
                                    appointment: appt,
                                    onClose: _closeInternalView)),
                          ),
                          _ClientHistoryTab(
                            onAppointmentTap: (appt) => _showInternalView(
                                AppointmentDetailScreen(
                                    appointment: appt,
                                    onClose: _closeInternalView)),
                            onBookTap: () => _showInternalView(
                                ClientBookingScreen(
                                    onClose: _closeInternalView)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_internalView != null)
                  Positioned.fill(
                    child: Container(
                      color: cs.surface,
                      child: _internalView,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInternalView(Widget view) {
    setState(() => _internalView = view);
  }

  void _closeInternalView() {
    setState(() => _internalView = null);
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 48, 10),
      child: Row(
        children: [
          PhobesIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () {
              if (widget.onClose != null) {
                widget.onClose!();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appointmentCenter,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              PhobesIconButton(
                icon: Icons.settings_suggest_outlined,
                onTap: () => _showInternalView(
                    AppointmentGroupScreen(onClose: _closeInternalView)),
              ),
              const SizedBox(width: 8),
              PhobesIconButton(
                icon: Icons.add_rounded,
                color: Colors.black,
                backgroundColor: Colors.tealAccent,
                onTap: () => _showInternalView(
                    ClientBookingScreen(onClose: _closeInternalView)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCustomTabBar(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: cs.outline.withValues(alpha: 0.1)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: cs.primary.withValues(alpha: 0.5)),
        ),
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurface.withValues(alpha: 0.5),
        dividerColor: Colors.transparent,
        labelStyle:
            GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: [
          Tab(text: l10n.managementTab),
          Tab(text: l10n.myAppointmentsTab),
        ],
      ),
    );
  }
}

class _ProviderDashboardTab extends StatefulWidget {
  final Function(Appointment) onAppointmentTap;
  final Function(Appointment) onEditTap;
  const _ProviderDashboardTab(
      {required this.onAppointmentTap, required this.onEditTap});

  @override
  State<_ProviderDashboardTab> createState() => _ProviderDashboardTabState();
}

class _ProviderDashboardTabState extends State<_ProviderDashboardTab> {
  String _searchQuery = "";
  String _filterStatus = "all";

  @override
  Widget build(BuildContext context) {
    final service = FirebaseService();
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<List<Appointment>>(
      stream: service.getAppointmentsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allAppointments = snapshot.data ?? [];

        final int pendingCount =
            allAppointments.where((a) => a.status == 'pending').length;
        final int confirmedCount =
            allAppointments.where((a) => a.status == 'confirmed').length;
        final int todayCount = allAppointments
            .where((a) => DateUtils.isSameDay(a.date, DateTime.now()))
            .length;

        List<Appointment> filteredList = allAppointments.where((appt) {
          final matchesSearch = appt.clientName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              (appt.phoneNumber?.contains(_searchQuery) ?? false);

          bool matchesFilter = true;
          if (_filterStatus == 'today') {
            matchesFilter = DateUtils.isSameDay(appt.date, DateTime.now());
          } else if (_filterStatus != 'all') {
            matchesFilter = appt.status == _filterStatus;
          }

          return matchesSearch && matchesFilter;
        }).toList();

        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _StatCard(
                      label: l10n.filterAll,
                      count: allAppointments.length,
                      color: Colors.purple,
                      icon: Icons.list,
                      isActive: _filterStatus == 'all',
                      onTap: () => setState(() => _filterStatus = 'all')),
                  const SizedBox(width: 12),
                  _StatCard(
                      label: l10n.statusPending,
                      count: pendingCount,
                      color: Colors.orange,
                      icon: Icons.hourglass_top,
                      isActive: _filterStatus == 'pending',
                      onTap: () => setState(() => _filterStatus = 'pending')),
                  const SizedBox(width: 12),
                  _StatCard(
                      label: l10n.today,
                      count: todayCount,
                      color: Colors.blue,
                      icon: Icons.calendar_today,
                      isActive: _filterStatus == 'today',
                      onTap: () => setState(() => _filterStatus = 'today')),
                  const SizedBox(width: 12),
                  _StatCard(
                      label: l10n.statusConfirmed,
                      count: confirmedCount,
                      color: Colors.green,
                      icon: Icons.check_circle,
                      isActive: _filterStatus == 'confirmed',
                      onTap: () => setState(() => _filterStatus = 'confirmed')),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                style: TextStyle(color: cs.onSurface),
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: l10n.searchPlaceholder,
                  hintStyle:
                      TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
                  prefixIcon: Icon(Icons.search,
                      color: cs.onSurface.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: cs.surfaceContainerHigh,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filteredList.isEmpty
                  ? _EmptyState(isSearch: _searchQuery.isNotEmpty, l10n: l10n)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) => _AppointmentCard(
                        appointment: filteredList[index],
                        isProviderMode: true,
                        l10n: l10n,
                        onTap: () =>
                            widget.onAppointmentTap(filteredList[index]),
                        onEditTap: () => widget.onEditTap(filteredList[index]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ClientHistoryTab extends StatelessWidget {
  final Function(Appointment) onAppointmentTap;
  final VoidCallback onBookTap;
  const _ClientHistoryTab(
      {required this.onAppointmentTap, required this.onBookTap});

  @override
  Widget build(BuildContext context) {
    final FirebaseService service = FirebaseService();
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<Appointment>>(
      stream: service.getMyAppointmentsAsClientStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final appointments = snapshot.data ?? [];

        if (appointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_note_rounded,
                    size: 60, color: Colors.white10),
                const SizedBox(height: 16),
                Text(l10n.msgNoAppointments,
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: onBookTap,
                  child: Text(l10n.bookAppointment,
                      style: const TextStyle(color: Colors.tealAccent)),
                )
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
          itemCount: appointments.length,
          itemBuilder: (context, index) => _AppointmentCard(
            appointment: appointments[index],
            isProviderMode: false,
            l10n: l10n,
            onTap: () => onAppointmentTap(appointments[index]),
            onEditTap: () {},
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: PhobesGlassCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 16,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count.toString(),
                  style: GoogleFonts.outfit(
                    color: cs.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: isActive
                        ? cs.onSurface
                        : cs.onSurface.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearch;
  final AppLocalizations l10n;
  const _EmptyState({this.isSearch = false, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isSearch ? Icons.search_off : Icons.inbox,
              size: 50, color: Colors.white10),
          const SizedBox(height: 10),
          Text(isSearch ? "Sonuç bulunamadı" : l10n.msgNoAppointments,
              style: const TextStyle(color: Colors.white24)),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final bool isProviderMode;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback onEditTap;

  const _AppointmentCard({
    required this.appointment,
    required this.isProviderMode,
    required this.l10n,
    required this.onTap,
    required this.onEditTap,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'confirmed':
        return l10n.statusConfirmed.toUpperCase();
      case 'cancelled':
        return l10n.statusCancelled.toUpperCase();
      case 'completed':
        return l10n.statusCompleted.toUpperCase();
      default:
        return l10n.statusPending.toUpperCase();
    }
  }

  Future<void> _makeCall(String number) async {
    final Uri launchUri = Uri(scheme: 'tel', path: number);
    await launchUrl(launchUri);
  }

  void _updateStatus(BuildContext context, String newStatus) {
    FirebaseService()
        .updateAppointment(appointment.copyWith(status: newStatus));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          "${l10n.msgStatusUpdated}: ${_getStatusText(context, newStatus)}"),
      backgroundColor: _getStatusColor(newStatus),
      duration: const Duration(seconds: 1),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(appointment.status);
    final statusText = _getStatusText(context, appointment.status);
    final dateStr =
        DateFormat('d MMM', l10n.localeName).format(appointment.date);
    final timeStr = DateFormat('HH:mm').format(appointment.date);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PhobesCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        dateStr.toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: cs.onSurface.withValues(alpha: 0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeStr,
                        style: GoogleFonts.outfit(
                          color: cs.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.title,
                        style: GoogleFonts.outfit(
                          color: cs.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            isProviderMode
                                ? Icons.person_outline_rounded
                                : Icons.storefront_rounded,
                            size: 14,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isProviderMode
                                  ? appointment.clientName
                                  : l10n.labelProvider,
                              style: GoogleFonts.outfit(
                                color: cs.onSurface.withValues(alpha: 0.5),
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    appointment.status == 'pending'
                        ? Icons.hourglass_top_rounded
                        : (appointment.status == 'confirmed'
                            ? Icons.check_rounded
                            : Icons.circle),
                    size: 16,
                    color: statusColor,
                  ),
                )
              ],
            ),
            if (isProviderMode) ...[
              const SizedBox(height: 12),
              Divider(color: cs.outline.withValues(alpha: 0.1), height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (appointment.phoneNumber != null)
                    PhobesIconButton(
                      icon: Icons.phone_rounded,
                      color: Colors.green,
                      backgroundColor: Colors.green.withValues(alpha: 0.1),
                      onTap: () => _makeCall(appointment.phoneNumber!),
                    )
                  else
                    const SizedBox(),
                  Row(
                    children: [
                      PhobesIconButton(
                        icon: Icons.edit_rounded,
                        color: Colors.blue,
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        onTap: onEditTap,
                      ),
                      const SizedBox(width: 8),
                      if (appointment.status == 'pending') ...[
                        PhobesIconButton(
                          icon: Icons.close_rounded,
                          color: Colors.redAccent,
                          backgroundColor:
                              Colors.redAccent.withValues(alpha: 0.1),
                          onTap: () => _updateStatus(context, 'cancelled'),
                        ),
                        const SizedBox(width: 8),
                        PhobesIconButton(
                          icon: Icons.check_circle_rounded,
                          color: Colors.green,
                          backgroundColor: Colors.green.withValues(alpha: 0.1),
                          onTap: () => _updateStatus(context, 'confirmed'),
                        ),
                      ] else
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded,
                              color: cs.onSurface.withValues(alpha: 0.4)),
                          color: cs.surfaceContainerHigh,
                          onSelected: (value) => _updateStatus(context, value),
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'completed',
                              child: Text(
                                l10n.statusCompleted,
                                style: GoogleFonts.outfit(color: cs.onSurface),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'cancelled',
                              child: Text(
                                l10n.statusCancelled,
                                style: GoogleFonts.outfit(color: cs.onSurface),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'pending',
                              child: Text(
                                l10n.statusPending,
                                style: GoogleFonts.outfit(color: cs.onSurface),
                              ),
                            ),
                          ],
                        ),
                    ],
                  )
                ],
              )
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    statusText,
                    style: GoogleFonts.outfit(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}
