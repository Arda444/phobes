import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../models/medication_model.dart';
import '../../services/firebase_service.dart';
import '../../core/page_transitions.dart';
import '../../widgets/phobes_widgets.dart';
import 'medication_add_edit_screen.dart';

class MedicationDetailScreen extends StatefulWidget {
  final Medication medication;
  final VoidCallback? onClose;

  const MedicationDetailScreen({
    super.key,
    required this.medication,
    this.onClose,
  });

  @override
  State<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Medication _medication;

  @override
  void initState() {
    super.initState();
    _medication = widget.medication;
  }

  Future<void> _deleteMedication() async {
    final confirmed = await PhobesBottomSheet.confirm(
      context: context,
      title: "İlacı Sil",
      message: "Bu ilaç kalıcı olarak silinecek. Emin misiniz?",
      confirmText: "Sil",
      confirmColor: Colors.red,
    );

    if (confirmed == true && mounted) {
      if (_medication.id != null) {
        await _firebaseService.deleteMedication(_medication.id!);
      }
      if (!mounted) return;

      if (widget.onClose != null) {
        widget.onClose!();
      } else {
        Navigator.pop(context);
      }

      PhobesSnackbar.show(
        context,
        message: "İlaç silindi",
        type: PhobesSnackbarType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel("Kullanım Şekli"),
                  const SizedBox(height: 12),
                  _buildDetailCard(
                    icon: Icons.science_rounded,
                    title: "Dozaj",
                    value: _medication.dosage,
                    cs: cs,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailCard(
                    icon: Icons.repeat_rounded,
                    title: "Sıklık",
                    value: _getFrequencyText(_medication.frequency),
                    cs: cs,
                  ),
                  const SizedBox(height: 16),
                  _buildSectionLabel("Alım Saatleri"),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _medication.times.map((time) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color:
                              Color(_medication.color).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                Color(_medication.color).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 16, color: Color(_medication.color)),
                            const SizedBox(width: 8),
                            Text(
                              time,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(_medication.color),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  if (_medication.isActive) ...[
                    _buildSectionLabel("Bugünün Dozları"),
                    const SizedBox(height: 12),
                    _buildTodayDoses(cs),
                    const SizedBox(height: 24),
                  ],
                  if (_medication.notes.isNotEmpty) ...[
                    _buildSectionLabel("Notlar"),
                    const SizedBox(height: 12),
                    PhobesCard(
                      padding: const EdgeInsets.all(16),
                      margin: EdgeInsets.zero,
                      child: Text(
                        _medication.notes,
                        style: GoogleFonts.outfit(
                          color: cs.onSurface.withValues(alpha: 0.7),
                          height: 1.5,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_medication.stockTracking) ...[
                    _buildSectionLabel("Stok Durumu"),
                    const SizedBox(height: 12),
                    _buildStockCard(cs),
                    const SizedBox(height: 24),
                  ],
                  if (_medication.barcode != null || 
                      _medication.genericName != null || 
                      (_medication.atcCode != null && _medication.atcCode!.isNotEmpty)) ...[
                    _buildSectionLabel("Ürün Bilgileri"),
                    const SizedBox(height: 12),
                    PhobesCard(
                      padding: const EdgeInsets.all(16),
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          if (_medication.genericName != null && _medication.genericName!.isNotEmpty)
                             _buildInfoRow("Etken Madde", _medication.genericName!, cs),
                          if (_medication.atcCode != null && _medication.atcCode!.isNotEmpty)
                             _buildInfoRow("ATC Kodu", _medication.atcCode!, cs),
                          if (_medication.barcode != null && _medication.barcode!.isNotEmpty)
                             _buildInfoRow("Barkod", _medication.barcode!, cs),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_medication.categories.isNotEmpty) ...[
                    _buildSectionLabel("İlaç Sınıflandırması"),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: _medication.categories.map((cat) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: cs.secondaryContainer),
                          ),
                          child: Text(
                            cat,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: cs.onSecondaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_medication.prospectusUrl != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final url = Uri.parse(_medication.prospectusUrl!);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        },
                        icon: const Icon(Icons.description_rounded),
                        label: const Text("Prospektüsü Görüntüle (PDF)"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final medColor = Color(_medication.color);
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            medColor.withValues(alpha: 0.15),
            cs.surface,
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        border: Border(
          bottom: BorderSide(
            color: medColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PhobesIconButton(
                icon: Icons.arrow_back_rounded,
                backgroundColor: cs.surface.withValues(alpha: 0.5),
                onTap: () {
                  if (widget.onClose != null) {
                    widget.onClose!();
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
              Row(
                children: [
                  PhobesIconButton(
                    icon: Icons.edit_rounded,
                    backgroundColor: cs.surface.withValues(alpha: 0.5),
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      await navigator.push(PhobesPageRoute.slideUp(
                          MedicationAddEditScreen(medication: _medication)));
                      // Refresh data after editing
                      if (mounted) {
                        final updated = await _firebaseService.getMedicationById(_medication.id!);
                        if (updated != null && mounted) {
                          setState(() => _medication = updated);
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  PhobesIconButton(
                    icon: Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                    onTap: _deleteMedication,
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: medColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: medColor.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: _medication.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            _medication.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Text(_medication.icon,
                                style: const TextStyle(fontSize: 32)),
                          ),
                        )
                      : Text(_medication.icon,
                          style: const TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_medication.isActive)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "PASİF",
                          style: GoogleFonts.outfit(
                            color: Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Text(
                      _medication.name,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                        height: 1.1,
                      ),
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

  Widget _buildSectionLabel(String text) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.outfit(
        color: cs.onSurface.withValues(alpha: 0.4),
        fontWeight: FontWeight.bold,
        fontSize: 12,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required ColorScheme cs,
  }) {
    return PhobesCard(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(_medication.color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Color(_medication.color)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: cs.onSurface.withValues(alpha: 0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: cs.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStockCard(ColorScheme cs) {
    final isLow = _medication.stock <= _medication.stockThreshold;
    final color = isLow ? Colors.amber.shade700 : Colors.green.shade600;

    return PhobesCard(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Kalan Stok",
                style: GoogleFonts.outfit(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    if (isLow) ...[
                      Icon(Icons.warning_amber_rounded, size: 14, color: color),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      _medication.stock.toString(),
                      style: GoogleFonts.outfit(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_medication.stock / (_medication.stockThreshold * 3))
                  .clamp(0.0, 1.0),
              backgroundColor: cs.onSurface.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: cs.onSurface.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  bool _isDoseTaken(String time) {
    final history = _medication.takenHistory[_todayKey];
    return history != null && history.contains(time);
  }

  Widget _buildTodayDoses(ColorScheme cs) {
    final medColor = Color(_medication.color);
    final todayTaken = _medication.times.where((t) => _isDoseTaken(t)).length;
    final todayTotal = _medication.times.length;

    return PhobesCard(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$todayTaken / $todayTotal alındı',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
              if (todayTotal > 0)
                Text(
                  '%${(todayTaken / todayTotal * 100).round()}',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: todayTaken == todayTotal
                        ? Colors.green
                        : (todayTaken > 0 ? Colors.orange : cs.onSurface.withValues(alpha: 0.3)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ..._medication.times.map((time) {
            final taken = _isDoseTaken(time);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  if (_medication.id == null) return;
                  if (taken) {
                    _firebaseService.unmarkMedicationTaken(
                        _medication.id!, _todayKey, time);
                  } else {
                    _firebaseService.markMedicationTaken(
                        _medication.id!, _todayKey, time);
                  }
                  setState(() {
                    final history = Map<String, List<String>>.from(_medication.takenHistory);
                    final dayList = List<String>.from(history[_todayKey] ?? []);
                    if (taken) {
                      dayList.remove(time);
                    } else {
                      dayList.add(time);
                    }
                    history[_todayKey] = dayList;
                    _medication = _medication.copyWith(takenHistory: history);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: taken
                        ? medColor.withValues(alpha: 0.08)
                        : cs.onSurface.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: taken
                          ? medColor.withValues(alpha: 0.2)
                          : cs.onSurface.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 18, color: taken ? medColor : cs.onSurface.withValues(alpha: 0.4)),
                      const SizedBox(width: 10),
                      Text(
                        time,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: taken ? medColor : cs.onSurface,
                          decoration: taken ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const Spacer(),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: taken ? medColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: taken
                              ? null
                              : Border.all(color: cs.onSurface.withValues(alpha: 0.15)),
                        ),
                        child: taken
                            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getFrequencyText(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'Günlük';
      case 'weekly':
        return 'Haftalık';
      case 'asNeeded':
        return 'Gerektiğinde';
      default:
        return frequency;
    }
  }
}
