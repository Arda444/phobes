import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../models/medication_model.dart';
import '../../services/firebase_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/phobes_widgets.dart';

class MedicationAddEditScreen extends StatefulWidget {
  final Medication? medication;
  final VoidCallback? onClose;
  const MedicationAddEditScreen({super.key, this.medication, this.onClose});

  @override
  State<MedicationAddEditScreen> createState() =>
      _MedicationAddEditScreenState();
}

class _MedicationAddEditScreenState extends State<MedicationAddEditScreen> {
  final _firebaseService = FirebaseService();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  String _frequency = 'daily';
  List<String> _times = ['08:00'];
  int _selectedColor = 0xFF4CAF50;
  String _selectedIcon = '💊';
  bool _isActive = true;
  bool _reminderEnabled = true;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isSaving = false;
  bool _stockTracking = false;
  final _stockController = TextEditingController(text: '0');
  final _thresholdController = TextEditingController(text: '5');

  bool get _isEditing => widget.medication != null;

  static const _icons = [
    '💊',
    '💉',
    '🩹',
    '🧴',
    '🩺',
    '💧',
    '🌿',
    '🧬',
    '❤️',
    '🫁',
    '🧠',
    '👁️',
    '🦷',
    '🦴',
    '🩸',
    '🫀',
  ];

  static const _colors = [
    0xFF4CAF50,
    0xFF2196F3,
    0xFFFF9800,
    0xFFE91E63,
    0xFF9C27B0,
    0xFF00BCD4,
    0xFFFF5722,
    0xFF607D8B,
  ];

  static const _frequencies = {
    'daily': 'Günlük',
    'weekly': 'Haftalık',
    'asNeeded': 'Gerektiğinde',
  };

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final m = widget.medication!;
      _nameController.text = m.name;
      _dosageController.text = m.dosage;
      _notesController.text = m.notes;
      _frequency = m.frequency;
      _times = List.from(m.times);
      _selectedColor = m.color;
      _selectedIcon = m.icon;
      _isActive = m.isActive;
      _reminderEnabled = m.reminderEnabled;
      _startDate = m.startDate;
      _startDate = m.startDate;
      _endDate = m.endDate;
      _stockTracking = m.stockTracking;
      _stockController.text = m.stock.toString();
      _thresholdController.text = m.stockThreshold.toString();
      
      if (m.barcode != null || m.imageUrl != null) {
        _currentSelectedMedicineData = {
          'name': m.name,
          'dosage': m.dosage,
          'barcode': m.barcode,
          'imageUrl': m.imageUrl,
          'prospectusUrl': m.prospectusUrl,
          'generic_name': m.genericName,
          'atcCode': m.atcCode,
          'categories': m.categories,
        };
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İlaç adı gerekli')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final userId = _firebaseService.currentUserId;
    if (userId == null) return;

    final med = Medication(
      id: widget.medication?.id,
      userId: userId,
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      frequency: _frequency,
      times: _times,
      startDate: _startDate,
      endDate: _endDate,
      color: _selectedColor,
      icon: _selectedIcon,
      notes: _notesController.text.trim(),
      isActive: _isActive,
      reminderEnabled: _reminderEnabled,
      takenHistory: widget.medication?.takenHistory ?? {},
      stockTracking: _stockTracking,
      stock: int.tryParse(_stockController.text) ?? 0,
      stockThreshold: int.tryParse(_thresholdController.text) ?? 5,
      imageUrl: _currentSelectedMedicineData?['imageUrl'],
      prospectusUrl: _currentSelectedMedicineData?['prospectusUrl'],
      barcode: _currentSelectedMedicineData?['barcode'],
      genericName: _currentSelectedMedicineData?['generic_name'],
      atcCode: _currentSelectedMedicineData?['atcCode'],
      categories: List<String>.from(_currentSelectedMedicineData?['categories'] ?? []),
    );

    try {
      if (_isEditing) {
        await _firebaseService.updateMedication(med);
      } else {
        await _firebaseService.addMedication(med);
      }

      final notificationService = NotificationService();
      if (_isActive && _reminderEnabled) {
        for (int i = 0; i < _times.length; i++) {
          final timeParts = _times[i].split(':');
          final scheduledTime = DateTime(
            _startDate.year,
            _startDate.month,
            _startDate.day,
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );

          await notificationService.scheduleAndSaveNotification(
            id: '${med.id ?? med.name}_$i',
            title: 'İlaç Zamanı: ${med.name}',
            body: '${med.dosage} almayı unutma.',
            scheduledTime: scheduledTime,
            type: 'medication',
            targetId: med.id,
            targetType: 'medication',
            icon: med.icon,
            color: 0xFF009688,
            channelId: 'medications',
            channelName: 'İlaçlarım',
            prefKey: 'notif_med_dose',
          );
        }
      } else {
        for (int i = 0; i < _times.length; i++) {
          await notificationService
              .cancelNotification('${med.id ?? med.name}_$i');
        }
      }

      if (mounted) {
        if (widget.onClose != null) {
          widget.onClose!();
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Color(_selectedColor);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF050505) : const Color(0xFFF8FAFC),
      appBar: PhobesPremiumAppBar(
        title: _isEditing ? 'İlacı Düzenle' : 'Yeni İlaç',
        onBackPressed: () {
          if (widget.onClose != null) {
            widget.onClose!();
          } else {
            Navigator.pop(context);
          }
        },
        trailing: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton(
                onPressed: _save,
                style: TextButton.styleFrom(
                  backgroundColor: color.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isEditing ? 'Güncelle' : 'Kaydet',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _showIconPicker,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: _currentSelectedMedicineData?['imageUrl'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  _currentSelectedMedicineData!['imageUrl'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Text(_selectedIcon,
                                      style: const TextStyle(fontSize: 32)),
                                ),
                              )
                            : Text(_selectedIcon,
                                style: const TextStyle(fontSize: 32)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSearchField(
                          _nameController,
                          'İlaç Adı',
                          Icons.medication_rounded,
                          isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FadeInDown(
              delay: const Duration(milliseconds: 50),
              child: _buildField(
                _dosageController,
                'Doz (örn: 500mg, 1 tablet)',
                Icons.science_rounded,
                isDark,
              ),
            ),
            // Clinical info card after search selection
            if (_currentSelectedMedicineData != null) ...[
              const SizedBox(height: 12),
              FadeInDown(
                delay: const Duration(milliseconds: 60),
                child: _buildSelectedMedicineInfoCard(isDark, color),
              ),
            ],
            const SizedBox(height: 20),
            FadeInDown(
              delay: const Duration(milliseconds: 100),
              child: _buildSection('Sıklık', isDark),
            ),
            const SizedBox(height: 8),
            FadeInDown(
              delay: const Duration(milliseconds: 120),
              child: Wrap(
                spacing: 8,
                children: _frequencies.entries.map((e) {
                  final isSelected = _frequency == e.key;
                  return GestureDetector(
                    onTap: () => setState(() => _frequency = e.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.15)
                            : isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? color.withValues(alpha: 0.4)
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        e.value,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? color
                              : isDark
                                  ? Colors.white54
                                  : Colors.black54,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            FadeInDown(
              delay: const Duration(milliseconds: 150),
              child: _buildSection('Alım Saatleri', isDark),
            ),
            const SizedBox(height: 8),
            FadeInDown(
              delay: const Duration(milliseconds: 170),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._times.asMap().entries.map((entry) {
                    return GestureDetector(
                      onTap: () => _pickTime(entry.key),
                      onLongPress: () {
                        if (_times.length > 1) {
                          setState(() => _times.removeAt(entry.key));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: color.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 16, color: color),
                            const SizedBox(width: 6),
                            Text(
                              entry.value,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  GestureDetector(
                    onTap: () {
                      setState(() => _times.add('12:00'));
                      _pickTime(_times.length - 1);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded,
                              size: 16,
                              color: isDark ? Colors.white54 : Colors.black45),
                          const SizedBox(width: 4),
                          Text('Saat Ekle',
                              style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black45)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FadeInDown(
              delay: const Duration(milliseconds: 200),
              child: _buildSection('Renk', isDark),
            ),
            const SizedBox(height: 8),
            FadeInDown(
              delay: const Duration(milliseconds: 220),
              child: Row(
                children: _colors.map((c) {
                  final isSelected = _selectedColor == c;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                    color: Color(c).withValues(alpha: 0.5),
                                    blurRadius: 10)
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                              size: 18, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            FadeInDown(
              delay: const Duration(milliseconds: 250),
              child: _buildSection('Tarihler', isDark),
            ),
            const SizedBox(height: 8),
            FadeInDown(
              delay: const Duration(milliseconds: 270),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDateTile(
                        'Başlangıç', _startDate, isDark, color, (d) {
                      setState(() => _startDate = d);
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateTile(
                      'Bitiş (Ops.)',
                      _endDate,
                      isDark,
                      color,
                      (d) => setState(() => _endDate = d),
                      clearable: true,
                      onClear: () => setState(() => _endDate = null),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FadeInDown(
              delay: const Duration(milliseconds: 300),
              child: _buildField(
                _notesController,
                'Notlar (isteğe bağlı)',
                Icons.notes_rounded,
                isDark,
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 20),
            FadeInDown(
              delay: const Duration(milliseconds: 350),
              child: _buildToggleTile(
                'Hatırlatıcı Bildirimi',
                'Her doz saatinde bildirim gönder',
                Icons.notifications_active_rounded,
                _reminderEnabled,
                (v) => setState(() => _reminderEnabled = v),
                isDark,
                color,
              ),
            ),
            const SizedBox(height: 8),
            FadeInDown(
              delay: const Duration(milliseconds: 400),
              child: _buildToggleTile(
                'Aktif',
                'Pasif ilaçlar günlük listede gösterilmez',
                Icons.power_settings_new_rounded,
                _isActive,
                (v) => setState(() => _isActive = v),
                isDark,
                color,
              ),
            ),
            const SizedBox(height: 16),
            FadeInDown(
              delay: const Duration(milliseconds: 450),
              child: _buildSection('Stok Takibi', isDark),
            ),
            const SizedBox(height: 8),
            FadeInDown(
              delay: const Duration(milliseconds: 470),
              child: _buildToggleTile(
                'Stok Takibini Etkinleştir',
                'Kalan ilaç miktarını otomatik takip et',
                Icons.inventory_2_rounded,
                _stockTracking,
                (v) => setState(() => _stockTracking = v),
                isDark,
                color,
              ),
            ),
            if (_stockTracking) ...[
              const SizedBox(height: 12),
              FadeInDown(
                duration: const Duration(milliseconds: 300),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        _stockController,
                        'Mevcut Stok',
                        Icons.numbers_rounded,
                        isDark,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        _thresholdController,
                        'Kritik Eşik',
                        Icons.warning_amber_rounded,
                        isDark,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40), // Additional spacer before content ends
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, bool isDark) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white38 : Colors.black38,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildSearchField(
      TextEditingController ctrl, String hint, IconData icon, bool isDark) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: TextField(
            controller: ctrl,
            onChanged: (val) async {
              if (val.length >= 2) {
                setState(() {
                  _isSearching = true;
                  _showSearchResults = true;
                });
                final results = await _firebaseService.searchMedicines(val);
                setState(() {
                  _searchResults = results;
                  _isSearching = false;
                });
              } else {
                setState(() {
                  _showSearchResults = false;
                  _isSearching = false;
                });
              }
            },
            style: GoogleFonts.outfit(
                color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(
                  color: isDark ? Colors.white24 : Colors.black26),
              prefixIcon: Icon(icon,
                  color: isDark ? Colors.white24 : Colors.black26, size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        if (_showSearchResults)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(vertical: 8),
            constraints: const BoxConstraints(maxHeight: 240),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _isSearching
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'İlaçlar aranıyor...',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _searchResults.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔍', style: TextStyle(fontSize: 24)),
                              const SizedBox(height: 12),
                              Text(
                                'İlaç bulunamadı',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Lütfen resmi verileri içe aktarın veya\nfarklı bir isim deneyin.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color:
                                      isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final med = _searchResults[index];
                            return Material(
                              color: Colors.transparent,
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                title: Text(
                                  med['name'] ?? '',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  med['generic_name'] ?? '',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    _nameController.text = med['name'] ?? '';
                                    _dosageController.text =
                                        med['dosage'] ?? med['dose'] ?? '';
                                    _showSearchResults = false;
                                    _currentSelectedMedicineData = med;
                                    _selectedIcon = "💊";
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
      ],
    );
  }

  List<Map<String, dynamic>> _searchResults = [];
  bool _showSearchResults = false;
  bool _isSearching = false;
  Map<String, dynamic>? _currentSelectedMedicineData;

  Widget _buildSelectedMedicineInfoCard(bool isDark, Color color) {
    final data = _currentSelectedMedicineData!;
    final genericName = data['generic_name'] as String? ?? '';
    final atcCode = data['atcCode'] as String? ?? '';
    final categories = (data['categories'] as List?)?.cast<String>() ?? [];
    final barcode = data['barcode'] as String? ?? '';

    if (genericName.isEmpty && atcCode.isEmpty && categories.isEmpty && barcode.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_rounded, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                'Veritabanından eşleştirildi',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _currentSelectedMedicineData = null),
                child: Icon(Icons.close_rounded, size: 16,
                    color: isDark ? Colors.white38 : Colors.black38),
              ),
            ],
          ),
          if (genericName.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Etken Madde', genericName, isDark),
          ],
          if (atcCode.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildInfoRow('ATC Kodu', atcCode, isDark),
          ],
          if (barcode.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildInfoRow('Barkod', barcode, isDark),
          ],
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: categories.take(3).map((cat) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  cat,
                  style: GoogleFonts.outfit(fontSize: 10, color: color, fontWeight: FontWeight.w500),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildField(
      TextEditingController ctrl, String hint, IconData icon, bool isDark,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style:
            GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(
              color: isDark ? Colors.white24 : Colors.black26),
          prefixIcon: Icon(icon,
              color: isDark ? Colors.white24 : Colors.black26, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDateTile(String label, DateTime? date, bool isDark, Color color,
      ValueChanged<DateTime> onPicked,
      {bool clearable = false, VoidCallback? onClear}) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(primary: color),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 16, color: isDark ? Colors.white38 : Colors.black38),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: isDark ? Colors.white38 : Colors.black38)),
                  Text(
                    date != null
                        ? '${date.day}.${date.month}.${date.year}'
                        : 'Seçilmedi',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            if (clearable && date != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close_rounded,
                    size: 16, color: isDark ? Colors.white24 : Colors.black26),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile(String title, String subtitle, IconData icon,
      bool value, ValueChanged<bool> onChanged, bool isDark, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 20,
              color: value
                  ? color
                  : isDark
                      ? Colors.white24
                      : Colors.black26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87)),
                Text(subtitle,
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black38)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: color,
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(int index) async {
    final parts = _times[index].split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: Color(_selectedColor)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _times[index] =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        _times.sort();
      });
    }
  }

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('İkon Seç',
                  style: GoogleFonts.outfit(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _icons.map((icon) {
                  final isSelected = _selectedIcon == icon;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedIcon = icon);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(_selectedColor).withValues(alpha: 0.15)
                            : isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: isSelected
                            ? Border.all(
                                color: Color(_selectedColor)
                                    .withValues(alpha: 0.5),
                                width: 2)
                            : null,
                      ),
                      child: Center(
                          child:
                              Text(icon, style: const TextStyle(fontSize: 24))),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
