import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../models/medication_model.dart';
import '../../services/firebase_service.dart';
import '../../core/page_transitions.dart';
import '../../widgets/phobes_widgets.dart';
import 'medication_add_edit_screen.dart';
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
  Widget? _internalView;

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

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: _internalView != null
          ? null
          : PhobesPremiumAppBar(
              title: 'İlaçlarım',
              onBackPressed: () {
          if (widget.onClose != null) {
            widget.onClose!();
          } else {
            Navigator.pop(context);
          }
        },
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? cs.surfaceContainerHighest.withValues(alpha: 0.4)
                        : cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cs.outline.withValues(alpha: 0.05)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelStyle: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: cs.onSurface.withValues(alpha: 0.45),
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.today_rounded, size: 16),
                            SizedBox(width: 6),
                            Text('Bugün'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.medication_rounded, size: 16),
                            SizedBox(width: 6),
                            Text('Tüm İlaçlar'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildTodayTab(isDark),
              _buildAllMedsTab(isDark),
            ],
          ),
          if (_internalView != null)
            Positioned.fill(
              child: Container(
                color: isDark ? const Color(0xFF050505) : cs.surface,
                child: _internalView,
              ),
            ),
          if (_internalView == null)
            Positioned(
              bottom: 100,
              right: 20,
              child: FadeInUp(
                duration: const Duration(milliseconds: 500),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4CAF50),
                        const Color(0xFF4CAF50).withValues(alpha: 0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FloatingActionButton.extended(
                    heroTag: 'med_fab',
                    onPressed: () => _showInternalView(
                        MedicationAddEditScreen(onClose: _closeInternalView)),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    label: Text(
                      'İlaç Ekle',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showInternalView(Widget view) {
    setState(() => _internalView = view);
  }

  void _closeInternalView() {
    setState(() => _internalView = null);
  }


  Widget _buildTodayTab(bool isDark) {
    final cs = Theme.of(context).colorScheme;
    return StreamBuilder<List<Medication>>(
      stream: _firebaseService.getMedicationsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text("Hata: ${snapshot.error}",
                  style: GoogleFonts.outfit(color: Colors.red)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
        }

        final allMeds = snapshot.data ?? [];
        final activeMeds = allMeds.where((m) => m.isActive).toList();

        if (activeMeds.isEmpty) {
          return _buildEmptyState(isDark);
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

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: FadeInDown(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                                    backgroundColor:
                                        cs.onSurface.withValues(alpha: 0.1),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Color(0xFF4CAF50)),
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
                              Text('Günlük Uyum',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  )),
                              const SizedBox(height: 4),
                              Text('$todayTaken / $todayTotal doz alındı',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black45,
                                  )),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Text('Bugünün Dozları',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : Colors.black38,
                      letterSpacing: 1,
                    )),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = doseItems[index];
                  final taken = _isDoseTaken(item.medication, item.time);
                  return FadeInRight(
                    delay: Duration(milliseconds: index * 60),
                    child: _buildDoseCard(item, taken, isDark),
                  );
                },
                childCount: doseItems.length,
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        );
      },
    );
  }

  Widget _buildDoseCard(_DoseItem item, bool taken, bool isDark) {
    final med = item.medication;
    final color = Color(med.color);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: PhobesCard(
        onTap: () {
          // Card tap → navigate to detail
          _showInternalView(MedicationDetailScreen(
            medication: med,
            onClose: _closeInternalView,
          ));
        },
        padding: const EdgeInsets.all(16),
        enableGlow: !taken,
        glowColor: color.withValues(alpha: 0.3),
        child: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
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
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                ],
              ),
            ),
            // Only checkbox toggles taken status
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (taken) {
                  _firebaseService.unmarkMedicationTaken(
                      med.id!, _todayKey, item.time);
                } else {
                  _firebaseService.markMedicationTaken(
                      med.id!, _todayKey, item.time);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: taken ? color : cs.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: taken
                      ? null
                      : Border.all(color: cs.outline.withValues(alpha: 0.15), width: 1.5),
                ),
                child: taken
                    ? const Center(
                        child: Icon(Icons.check_rounded,
                            color: Colors.white, size: 20))
                    : Center(
                        child: Icon(Icons.circle_outlined,
                            color: cs.onSurface.withValues(alpha: 0.15), size: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllMedsTab(bool isDark) {
    return StreamBuilder<List<Medication>>(
      stream: _firebaseService.getMedicationsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text("Hata: ${snapshot.error}",
                  style: GoogleFonts.outfit(color: Colors.red)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
        }

        final allMeds = snapshot.data ?? [];
        final meds =
            _showInactive ? allMeds : allMeds.where((m) => m.isActive).toList();

        if (meds.isEmpty) return _buildEmptyState(isDark);

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text('${meds.length} İlaç',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black45,
                        )),
                    const Spacer(),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showInactive = !_showInactive),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _showInactive
                              ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                              : isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _showInactive
                              ? 'Pasifler Gösteriliyor'
                              : 'Pasifleri Göster',
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
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final med = meds[index];
                  return FadeInUp(
                    delay: Duration(milliseconds: index * 60),
                    child: _buildMedCard(med, isDark),
                  );
                },
                childCount: meds.length,
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        );
      },
    );
  }

  Widget _buildMedCard(Medication med, bool isDark) {
    final color = Color(med.color);
    final cs = Theme.of(context).colorScheme;
    final adherence = _getWeeklyAdherence(med);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showMedActions(med);
        },
        child: PhobesCard(
          onTap: () => _showInternalView(MedicationDetailScreen(
            medication: med,
            onClose: _closeInternalView,
          )),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
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
                          '${med.times.length} Doz - ${med.dosage}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        if (med.genericName != null && med.genericName!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              med.genericName!,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: cs.onSurface.withValues(alpha: 0.35),
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
                        'Haftalık',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  )
                ],
              ),
              if (med.stockTracking) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.inventory_2_rounded,
                            size: 14,
                            color: cs.onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text(
                          'Kalan Stok: ${med.stock}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    if (med.stock <= med.stockThreshold)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                size: 12, color: Colors.red),
                            const SizedBox(width: 4),
                            Text(
                              'Kritik Seviye',
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
                  backgroundColor: cs.onSurface.withValues(alpha: 0.05),
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
      ),
    );
  }

  void _showMedActions(Medication med) {
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
                    color: Colors.orange),
                title: Text(med.isActive ? 'Pasife Al' : 'Aktif Yap',
                    style: GoogleFonts.outfit()),
                onTap: () {
                  Navigator.pop(ctx);
                  _firebaseService
                      .updateMedication(med.copyWith(isActive: !med.isActive));
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.edit_rounded, color: Color(0xFF4CAF50)),
                title: Text('Düzenle', style: GoogleFonts.outfit()),
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
                title:
                    Text('Sil', style: GoogleFonts.outfit(color: Colors.red)),
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
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('İlacı Sil?',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Text(
            '"${med.name}" silinecek. Bu işlem geri alınamaz.',
            style: GoogleFonts.outfit(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('İptal', style: GoogleFonts.outfit()),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _firebaseService.deleteMedication(med.id!);
              },
              child: Text('Sil', style: GoogleFonts.outfit(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: FadeInUp(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PhobesGlassCard(
              padding: EdgeInsets.all(28),
              borderRadius: 40,
              child: Text('💊', style: TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz ilaç eklenmemiş',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'İlaçlarınızı takip etmeye başlayın',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoseItem {
  final Medication medication;
  final String time;
  _DoseItem({required this.medication, required this.time});
}
