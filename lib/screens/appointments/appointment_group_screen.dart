import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/firebase_service.dart';
import '../../models/appointment_group_model.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/phobes_widgets.dart';
import '../../core/phobes_theme.dart';

class AppointmentGroupScreen extends StatefulWidget {
  final VoidCallback? onClose;
  const AppointmentGroupScreen({super.key, this.onClose});

  @override
  State<AppointmentGroupScreen> createState() => _AppointmentGroupScreenState();
}

class _AppointmentGroupScreenState extends State<AppointmentGroupScreen> {
  final FirebaseService _service = FirebaseService();
  bool _isFormVisible = false;
  String? _editingGroupId;
  String? _existingCode;

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: "30");
  final _bufferCtrl = TextEditingController(text: "0");

  final _bizNameCtrl = TextEditingController();
  final _bizPhoneCtrl = TextEditingController();
  final _bizWebCtrl = TextEditingController();
  final _bizAddressCtrl = TextEditingController();
  final _bizMapCtrl = TextEditingController();

  int _cancellationHours = 24;
  TimeOfDay _startHour = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endHour = const TimeOfDay(hour: 17, minute: 0);
  DateTimeRange _dateRange = DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now().add(const Duration(days: 365)));
  List<int> _selectedDays = [1, 2, 3, 4, 5];
  List<Map<String, int>> _breaks = [];

  void _resetForm() {
    setState(() {
      _isFormVisible = false;
      _editingGroupId = null;
      _existingCode = null;
      _titleCtrl.clear();
      _descCtrl.clear();
      _priceCtrl.clear();
      _bizNameCtrl.clear();
      _bizPhoneCtrl.clear();
      _bizWebCtrl.clear();
      _bizAddressCtrl.clear();
      _bizMapCtrl.clear();
      _durationCtrl.text = "30";
      _bufferCtrl.text = "0";
      _cancellationHours = 24;
      _breaks = [];
      _selectedDays = [1, 2, 3, 4, 5];
    });
  }

  void _startEdit(AppointmentGroup group) {
    setState(() {
      _isFormVisible = true;
      _editingGroupId = group.id;
      _existingCode = group.groupCode;
      _titleCtrl.text = group.title;
      _descCtrl.text = group.description;
      _priceCtrl.text = group.price.toString();
      _durationCtrl.text = group.durationMinutes.toString();
      _bufferCtrl.text = group.bufferMinutes.toString();
      _bizNameCtrl.text = group.businessName;
      _bizPhoneCtrl.text = group.businessPhone ?? "";
      _bizWebCtrl.text = group.businessWebsite ?? "";
      _bizAddressCtrl.text = group.businessAddress ?? "";
      _bizMapCtrl.text = group.mapUrl ?? "";
      _cancellationHours = group.minCancellationHours;
      _startHour = TimeOfDay(hour: group.startHour, minute: 0);
      _endHour = TimeOfDay(hour: group.endHour, minute: 0);
      _dateRange = DateTimeRange(start: group.startDate, end: group.endDate);
      _selectedDays = List.from(group.workingDays);
      _breaks = List.from(group.breaks);
    });
  }

  void _saveGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final group = AppointmentGroup(
      id: _editingGroupId,
      ownerId: _service.currentUserId!,
      title: _titleCtrl.text,
      description: _descCtrl.text,
      businessName: _bizNameCtrl.text,
      businessPhone: _bizPhoneCtrl.text,
      businessWebsite: _bizWebCtrl.text,
      businessAddress: _bizAddressCtrl.text,
      mapUrl: _bizMapCtrl.text,
      price: double.tryParse(_priceCtrl.text) ?? 0.0,
      durationMinutes: int.tryParse(_durationCtrl.text) ?? 30,
      bufferMinutes: int.tryParse(_bufferCtrl.text) ?? 0,
      minCancellationHours: _cancellationHours,
      startDate: _dateRange.start,
      endDate: _dateRange.end,
      startHour: _startHour.hour,
      endHour: _endHour.hour,
      groupCode: _existingCode ?? AppointmentGroup.generateCode(),
      workingDays: _selectedDays,
      breaks: _breaks,
    );

    if (_editingGroupId == null) {
      await _service.createAppointmentGroup(group);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                AppLocalizations.of(context)!.teamCreated(group.groupCode))));
      }
    } else {
      await _service.updateAppointmentGroup(group);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.infoUpdated)));
      }
    }
    _resetForm();
  }

  Future<void> _deleteGroup(String groupId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: Colors.grey.shade900,
              title: Text(l10n.delete,
                  style: const TextStyle(color: Colors.white)),
              content: Text(l10n.deleteNoteWarning,
                  style: const TextStyle(color: Colors.white70)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n.cancel)),
                ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n.delete)),
              ],
            ));

    if (confirm == true) {
      await _service.deleteAppointmentGroup(groupId);
    }
  }

  void _addBreak() async {
    final TimeOfDay? start = await showTimePicker(
        context: context, initialTime: const TimeOfDay(hour: 12, minute: 0));
    if (start == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    final TimeOfDay? end = await showTimePicker(
        context: context, initialTime: const TimeOfDay(hour: 13, minute: 0));
    if (end == null) {
      return;
    }

    setState(() {
      _breaks.add({
        'startH': start.hour,
        'startM': start.minute,
        'endH': end.hour,
        'endM': end.minute
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmoled = PhobesTheme.amoledMode.value;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isAmoled && isDark ? Colors.black : cs.surface,
      appBar: PhobesPremiumAppBar(
        title: _isFormVisible
            ? (_editingGroupId == null ? l10n.create : l10n.edit)
            : l10n.manageServices,
        onBackPressed: _isFormVisible
            ? _resetForm
            : () {
                if (widget.onClose != null) {
                  widget.onClose!();
                } else {
                  Navigator.pop(context);
                }
              },
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child:
              _isFormVisible ? _buildCreateForm(l10n) : _buildGroupList(l10n),
        ),
      ),
      floatingActionButton: _isFormVisible
          ? null
          : FloatingActionButton.extended(
              backgroundColor: cs.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(l10n.create,
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () => setState(() {
                _isFormVisible = true;
                _editingGroupId = null;
                _existingCode = null;
              }),
            ),
    );
  }

  Widget _buildGroupList(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    return StreamBuilder<List<AppointmentGroup>>(
      stream: _service.getMyAppointmentGroups(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: PhobesLoadingIndicator());
        }
        final groups = snapshot.data!;

        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month_outlined,
                    size: 60, color: cs.onSurface.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                Text(l10n.msgNoServices,
                    style: GoogleFonts.outfit(
                        color: cs.onSurface.withValues(alpha: 0.4))),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final g = groups[index];

            return PhobesCard(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(g.title,
                            style: GoogleFonts.outfit(
                                color: cs.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      ),
                      Row(
                        children: [
                          PhobesIconButton(
                            icon: Icons.edit_rounded,
                            color: Colors.blue,
                            onTap: () => _startEdit(g),
                          ),
                          const SizedBox(width: 8),
                          PhobesIconButton(
                            icon: Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                            onTap: () => _deleteGroup(g.id!),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(g.businessName,
                      style: GoogleFonts.outfit(
                          color: cs.primary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                      "${g.durationMinutes} ${l10n.duration} • ${g.price} ${g.currency}",
                      style: GoogleFonts.outfit(
                          color: cs.onSurface.withValues(alpha: 0.4),
                          fontSize: 13)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(g.groupCode,
                            style: GoogleFonts.outfit(
                                color: cs.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2)),
                      ),
                      const Spacer(),
                      PhobesIconButton(
                        icon: Icons.copy_rounded,
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: g.groupCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.msgCodeCopied)));
                        },
                      ),
                      const SizedBox(width: 8),
                      PhobesIconButton(
                        icon: Icons.share_rounded,
                        color: cs.primary,
                        onTap: () async {
                          try {
                            await SharePlus.instance.share(ShareParams(
                                text:
                                    "${l10n.bookNewAppointment}: ${g.groupCode}\n${g.businessName} - ${g.title}"));
                          } catch (e) {
                            debugPrint("Paylaşım Hatası: $e");
                          }
                        },
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCreateForm(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(l10n.labelProvider, cs),
            _buildTextField(
                _bizNameCtrl, l10n.businessName, Icons.store_rounded,
                required: true, l10n: l10n, cs: cs),
            const SizedBox(height: 12),
            _buildTextField(_bizPhoneCtrl, "Telefon", Icons.phone_rounded,
                l10n: l10n, cs: cs),
            const SizedBox(height: 12),
            _buildTextField(_bizWebCtrl, "Web", Icons.language_rounded,
                l10n: l10n, cs: cs),
            const SizedBox(height: 12),
            _buildTextField(
                _bizAddressCtrl, l10n.address, Icons.location_on_rounded,
                maxLines: 2, l10n: l10n, cs: cs),
            const SizedBox(height: 12),
            _buildTextField(_bizMapCtrl, "Map Link", Icons.map_rounded,
                l10n: l10n, cs: cs),
            const SizedBox(height: 32),
            _buildSectionTitle(l10n.sectionDetails, cs),
            _buildTextField(_titleCtrl, l10n.serviceTitle, Icons.stars_rounded,
                required: true, l10n: l10n, cs: cs),
            const SizedBox(height: 12),
            _buildTextField(
                _descCtrl, l10n.description, Icons.description_rounded,
                maxLines: 3, l10n: l10n, cs: cs),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _buildTextField(
                        _priceCtrl, l10n.price, Icons.attach_money_rounded,
                        type: TextInputType.number, l10n: l10n, cs: cs)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildTextField(
                        _durationCtrl, l10n.duration, Icons.timer_rounded,
                        type: TextInputType.number,
                        required: true,
                        l10n: l10n,
                        cs: cs)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildTextField(
                        _bufferCtrl, "Ara (dk)", Icons.pause_rounded,
                        type: TextInputType.number, l10n: l10n, cs: cs)),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: ValueKey(_cancellationHours),
              initialValue: _cancellationHours,
              dropdownColor: cs.surfaceContainerHigh,
              style: GoogleFonts.outfit(color: cs.onSurface),
              decoration: InputDecoration(
                  labelText: l10n.cancellationPolicy,
                  labelStyle: GoogleFonts.outfit(
                      color: cs.onSurface.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: cs.onSurface.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none)),
              items: const [0, 1, 6, 12, 24, 48]
                  .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e == 0 ? "Her zaman" : "$e saat önce",
                          style: GoogleFonts.outfit(color: cs.onSurface))))
                  .toList(),
              onChanged: (v) => setState(() => _cancellationHours = v!),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle(l10n.sectionTiming, cs),
            PhobesCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text("Mesai Saatleri",
                        style: GoogleFonts.outfit(
                            color: cs.onSurface, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        "${_startHour.format(context)} - ${_endHour.format(context)}",
                        style: GoogleFonts.outfit(
                            color: cs.primary, fontWeight: FontWeight.w600)),
                    trailing: PhobesIconButton(
                      icon: Icons.edit_rounded,
                      onTap: () async {
                        final start = await showTimePicker(
                            context: context, initialTime: _startHour);
                        if (start != null) {
                          setState(() => _startHour = start);
                        }
                        if (!mounted) {
                          return;
                        }
                        final end = await showTimePicker(
                            context: context, initialTime: _endHour);
                        if (end != null) {
                          setState(() => _endHour = end);
                        }
                      },
                    ),
                  ),
                  const Divider(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(7, (index) {
                      final day = index + 1;
                      final isSelected = _selectedDays.contains(day);
                      final days = [
                        l10n.dayMon,
                        l10n.dayTue,
                        l10n.dayWed,
                        l10n.dayThu,
                        l10n.dayFri,
                        l10n.daySat,
                        l10n.daySun
                      ];
                      return FilterChip(
                        label: Text(days[index]),
                        selected: isSelected,
                        onSelected: (v) => setState(() => v
                            ? _selectedDays.add(day)
                            : _selectedDays.remove(day)),
                        backgroundColor: cs.onSurface.withValues(alpha: 0.05),
                        selectedColor: cs.primary,
                        checkmarkColor: Colors.white,
                        labelStyle: GoogleFonts.outfit(
                            fontSize: 12,
                            color: isSelected ? Colors.white : cs.onSurface),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  PhobesButton(
                    text: "Mola Ekle",
                    icon: Icons.coffee_rounded,
                    width: double.infinity,
                    onPressed: _addBreak,
                  ),
                  ..._breaks.map((b) => Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                            "Mola: ${b['startH']}:${b['startM'].toString().padLeft(2, '0')} - ${b['endH']}:${b['endM'].toString().padLeft(2, '0')}",
                            style: GoogleFonts.outfit(
                                color: Colors.orangeAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ))
                ],
              ),
            ),
            const SizedBox(height: 40),
            PhobesButton(
              text: l10n.save,
              width: double.infinity,
              onPressed: _saveGroup,
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme cs) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 4),
        child: Text(title,
            style: GoogleFonts.outfit(
                color: cs.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2)));
  }

  Widget _buildTextField(
      TextEditingController ctrl, String label, IconData icon,
      {TextInputType? type,
      int maxLines = 1,
      bool required = false,
      required AppLocalizations l10n,
      required ColorScheme cs}) {
    return PhobesTextFormField(
      controller: ctrl,
      labelText: label,
      prefixIcon: icon,
      maxLines: maxLines,
      keyboardType: type,
      validator:
          required ? (v) => v!.isEmpty ? l10n.requiredField : null : null,
    );
  }
}
