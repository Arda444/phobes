import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../models/medication_model.dart';
import '../../services/firebase_service.dart';
import '../../core/page_transitions.dart';
import '../../core/phobes_detail_panel.dart';
import '../../core/phobes_theme.dart';
import '../../widgets/phobes_widgets.dart';
import '../../widgets/phobes_form_wrapper.dart';
import '../../core/module_info_catalog.dart';
import '../../widgets/phobes_module_header.dart';
import 'medication_add_edit_screen.dart';
import '../../l10n/app_localizations.dart';
import 'medication_detail_screen.dart';

class MedicationsScreen extends StatefulWidget {
  final VoidCallback? onClose;
  const MedicationsScreen({super.key, this.onClose});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen>
    with SingleTickerProviderStateMixin {
  final _firebaseService = FirebaseService();
  bool _showInactive = false;
  late TabController _tabController;

  List<Medication> _meds = const [];
  bool _isLoading = true;
  Object? _streamError;
  StreamSubscription<List<Medication>>? _medsSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _medsSub = _firebaseService.getMedicationsStream().listen(
      (data) {
        if (!mounted) return;
        setState(() {
          _meds = data;
          _isLoading = false;
          _streamError = null;
        });
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _streamError = e;
          _isLoading = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _medsSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  bool _isDoseTaken(Medication med, String time) {
    final history = med.takenHistory[_todayKey];
    return history != null && history.contains(time);
  }

  int _getWeeklyAdherence(Medication med) {
    int total = 0;
    int taken = 0;
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(day);
      if (day.isBefore(med.startDate)) continue;
      if (med.endDate != null && day.isAfter(med.endDate!)) continue;
      total += med.times.length;
      final hist = med.takenHistory[key];
      if (hist != null) taken += hist.length;
    }
    if (total == 0) return 100;
    return ((taken / total) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    PhobesModuleHeader(
                      title: l10n.medicationsTitle,
                      icon: Icons.medication_rounded,
                      onClose: () {
                        if (widget.onClose != null) {
                          widget.onClose!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      onAdd: () => _openAddMedForm(),
                      addTooltip: l10n.medAddTooltip,
                      info: ModuleInfoCatalog.forMedications(l10n),
                      tabController: _tabController,
                      tabs: [
                        PhobesModuleTab(
                            l10n.upcomingToday, Icons.today_rounded),
                        PhobesModuleTab(
                            l10n.allMedications, Icons.medication_rounded),
                      ],
                    ),
                  ],
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTodayTab(isDark),
                      _buildAllMedsTab(isDark),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Opens the add/edit form responsively:
  /// wide screen → right side panel, mobile → bottom sheet.
  void _openAddMedForm([Medication? existing]) {
    final l10n = AppLocalizations.of(context)!;
    PhobesFormWrapper.show(
      context,
      title: existing == null ? l10n.medNewTitle : l10n.medEditTitle,
      form: MedicationAddEditScreen(medication: existing),
    );
  }

  Widget _buildTodayTab(bool isDark) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Builder(
      builder: (nestedContext) {
        if (_streamError != null) {
          return ModuleNestedScroll.centered(
            context: nestedContext,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.errorGeneric(_streamError.toString()),
                style: GoogleFonts.outfit(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (_isLoading) {
          return ModuleNestedScroll.centered(
            context: nestedContext,
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            ),
          );
        }

        final allMeds = _meds;
        final activeMeds = allMeds.where((m) => m.isActive).toList();

        if (activeMeds.isEmpty) {
          return ModuleNestedScroll.centered(
            context: nestedContext,
            child: _buildEmptyState(isDark),
          );
        }

        final List<_DoseItem> doseItems = [];
        for (final med in activeMeds) {
          for (final time in med.times) {
            doseItems.add(_DoseItem(medication: med, time: time));
          }
        }
        doseItems.sort((a, b) => a.time.compareTo(b.time));

        final todayTotal = doseItems.length;
        final todayTaken =
            doseItems.where((d) => _isDoseTaken(d.medication, d.time)).length;
        final adherencePercent =
            todayTotal > 0 ? (todayTaken / todayTotal * 100).round() : 0;

        final isWide = MediaQuery.of(context).size.width >= 900;
        final doseDelegate = SliverChildBuilderDelegate(
          (context, index) {
            final item = doseItems[index];
            final taken = _isDoseTaken(item.medication, item.time);
            return FadeInRight(
              delay: Duration(milliseconds: index * 60),
              child:
                  _buildDoseCard(item, taken, isDark, isGrid: isWide),
            );
          },
          childCount: doseItems.length,
        );

        return CustomScrollView(
          slivers: ModuleNestedScroll.slivers(
            nestedContext,
            [
            SliverToBoxAdapter(
              child: FadeInDown(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: PhobesGlassCard(
                    padding: const EdgeInsets.all(20),
                    borderRadius: 20,
                    child: Row(
                      children: [
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: Stack(
                                children: [
                                  Center(
                                    child: SizedBox(
                                      width: 60,
                                      height: 60,
                                      child: CircularProgressIndicator(
                                        value: adherencePercent / 100,
                                        backgroundColor: cs.onSurface.withOpacity(0.1),
                                        valueColor: const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF4CAF50),
                                        ),
                                        strokeWidth: 6,
                                        strokeCap: StrokeCap.round,
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      '$adherencePercent%',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: cs.onSurface,
                                      ),
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
                                    l10n.dailyAdherence,
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.doseTakenCount(todayTaken, todayTotal),
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: isDark ? Colors.white54 : Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    child: Text(
                      l10n.todayDoses,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white38 : Colors.black38,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                if (isWide)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverLayoutBuilder(
                      builder: (context, sliverConstraints) {
                        final w = sliverConstraints.crossAxisExtent;
                        final cols = w >= 1500
                            ? 4
                            : w >= 1100
                                ? 3
                                : w >= 700
                                    ? 2
                                    : 1;
                        return SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            mainAxisExtent: 112,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 8,
                          ),
                          delegate: doseDelegate,
                        );
                      },
                    ),
                  )
                else
                  SliverList(delegate: doseDelegate),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDoseCard(_DoseItem item, bool taken, bool isDark,
      {bool isGrid = false}) {
    final med = item.medication;
    final color = Color(med.color);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: isGrid ? 0 : 20, vertical: isGrid ? 0 : 6),
      child: PhobesCard(
        onTap: () {
          PhobesDetailPanel.open(
            context,
            MedicationDetailScreen(medication: med),
          );
        },
        padding: const EdgeInsets.all(16),
        enableGlow: !taken,
        glowColor: color.withOpacity(0.3),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                item.time,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(med.icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med.name,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                      decoration: taken ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (med.dosage.isNotEmpty)
                    Text(
                      med.dosage,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.4),
                      ),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (taken) {
                  _firebaseService.unmarkMedicationTaken(
                    med.id!,
                    _todayKey,
                    item.time,
                  );
                } else {
                  _firebaseService.markMedicationTaken(
                    med.id!,
                    _todayKey,
                    item.time,
                  );
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: taken ? PhobesTheme.successGradient : null,
                  color: taken ? null : cs.onSurface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: taken
                      ? null
                      : Border.all(
                          color: cs.outline.withOpacity(0.15), width: 1.5),
                  boxShadow: taken
                      ? [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: taken
                    ? const Center(
                        child: Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.circle_outlined,
                          color: cs.onSurface.withOpacity(0.3),
                          size: 18,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllMedsTab(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Builder(
      builder: (nestedContext) {
        if (_streamError != null) {
          return ModuleNestedScroll.centered(
            context: nestedContext,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.errorGeneric(_streamError.toString()),
                style: GoogleFonts.outfit(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (_isLoading) {
          return ModuleNestedScroll.centered(
            context: nestedContext,
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            ),
          );
        }

        final allMeds = _meds;
        final meds =
            _showInactive ? allMeds : allMeds.where((m) => m.isActive).toList();

        if (meds.isEmpty) {
          return ModuleNestedScroll.centered(
            context: nestedContext,
            child: _buildEmptyState(isDark),
          );
        }

        final isWide = MediaQuery.of(context).size.width >= 900;
        final delegate = SliverChildBuilderDelegate(
          (context, index) {
            final med = meds[index];
            return FadeInUp(
              delay: Duration(milliseconds: index * 60),
              child: _buildMedCard(med, isDark, isGrid: isWide),
            );
          },
          childCount: meds.length,
        );

        return CustomScrollView(
          slivers: ModuleNestedScroll.slivers(
            nestedContext,
            [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text(
                      l10n.medicationCountBadge(meds.length),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                    const Spacer(),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _showInactive = !_showInactive),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _showInactive
                                  ? const Color(0xFF4CAF50).withOpacity(0.15)
                                  : isDark
                                      ? Colors.white.withOpacity(0.06)
                                      : Colors.black.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _showInactive
                                  ? l10n.showingInactiveMeds
                                  : l10n.showInactiveMeds,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: _showInactive
                                    ? const Color(0xFF4CAF50)
                                    : isDark
                                        ? Colors.white38
                                        : Colors.black38,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isWide)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    sliver: SliverLayoutBuilder(
                      builder: (context, sliverConstraints) {
                        final w = sliverConstraints.crossAxisExtent;
                        final cols = w >= 1500
                            ? 4
                            : w >= 1100
                                ? 3
                                : w >= 700
                                    ? 2
                                    : 1;
                        return SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            mainAxisExtent: 180,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 10,
                          ),
                          delegate: delegate,
                        );
                      },
                    ),
                  )
                else
                  SliverList(delegate: delegate),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMedCard(Medication med, bool isDark, {bool isGrid = false}) {
    final l10n = AppLocalizations.of(context)!;
    final color = Color(med.color);
    final cs = Theme.of(context).colorScheme;
    final adherence = _getWeeklyAdherence(med);

    final card = GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showMedActions(med);
      },
      child: PhobesCard(
        onTap: () => PhobesDetailPanel.open(
          context,
          MedicationDetailScreen(medication: med),
        ),
        margin: isGrid ? EdgeInsets.zero : null,
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(med.icon, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        '${med.times.length} · ${med.dosage}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: cs.onSurface.withOpacity(0.5),
                        ),
                      ),
                      if (med.genericName != null &&
                          med.genericName!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            med.genericName!,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: cs.onSurface.withOpacity(0.35),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '%$adherence',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: adherence > 80
                            ? Colors.green
                            : (adherence > 50 ? Colors.orange : Colors.red),
                      ),
                    ),
                    Text(
                      l10n.medicationWeeklyShort,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: cs.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (med.stockTracking) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_rounded,
                        size: 14,
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.remainingStock(med.stock),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  if (med.stock <= med.stockThreshold)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 12,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.criticalLevel,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: adherence / 100,
                backgroundColor: cs.onSurface.withOpacity(0.05),
                valueColor: AlwaysStoppedAnimation<Color>(
                  adherence > 80
                      ? Colors.green
                      : (adherence > 50 ? Colors.orange : Colors.red),
                ),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );

    if (isGrid) return card;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: card,
    );
  }

  void _showMedActions(Medication med) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(
                  med.isActive
                      ? Icons.pause_circle_outline_rounded
                      : Icons.play_circle_outline_rounded,
                  color: Colors.orange,
                ),
                title: Text(
                  med.isActive ? l10n.medDeactivate : l10n.medActivate,
                  style: GoogleFonts.outfit(),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _firebaseService
                      .updateMedication(med.copyWith(isActive: !med.isActive));
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.edit_rounded, color: Color(0xFF4CAF50)),
                title: Text(l10n.btnEdit, style: GoogleFonts.outfit()),
                onTap: () {
                  Navigator.pop(ctx);
                  PhobesPageRoute.pushResponsive(
                    context,
                    MedicationAddEditScreen(medication: med),
                  );
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: Text(l10n.btnDelete,
                    style: GoogleFonts.outfit(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteConfirm(med);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirm(Medication med) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            l10n.deleteMedicationTitle,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Text(
            l10n.deleteMedicationConfirmDesc(med.name),
            style: GoogleFonts.outfit(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel, style: GoogleFonts.outfit()),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _firebaseService.deleteMedication(med.id!);
              },
              child: Text(l10n.delete,
                  style: GoogleFonts.outfit(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return PhobesEmptyState(
      icon: Icons.medication_rounded,
      title: l10n.noMedicationsYet,
      description: l10n.startTrackingMeds,
      buttonText: l10n.addMedication,
      buttonIcon: Icons.add_rounded,
      onButtonTap: () => _openAddMedForm(),
    );
  }
}

class _DoseItem {
  final Medication medication;
  final String time;
  _DoseItem({required this.medication, required this.time});
}
