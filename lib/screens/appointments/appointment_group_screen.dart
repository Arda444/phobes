import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/appointment_group_model.dart';
import '../../services/appointment_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/phobes_widgets.dart';

class AppointmentGroupScreen extends StatefulWidget {
  final VoidCallback? onClose;
  const AppointmentGroupScreen({super.key, this.onClose});

  @override
  State<AppointmentGroupScreen> createState() => _AppointmentGroupScreenState();
}

class _AppointmentGroupScreenState extends State<AppointmentGroupScreen> {
  final AppointmentService _service = AppointmentService();
  late final Stream<List<AppointmentGroup>> _servicesStream;

  @override
  void initState() {
    super.initState();
    _servicesStream = _service.getMyServicesStream().asBroadcastStream();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
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
                    child: Text(
                      l10n.manageServices,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  PhobesIconButton(
                    icon: Icons.add_rounded,
                    color: Colors.black,
                    backgroundColor: Colors.tealAccent,
                    onTap: () => _showEditor(context, null),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<AppointmentGroup>>(
                stream: _servicesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: PhobesLoadingIndicator());
                  }
                  final services = snapshot.data ?? [];
                  if (services.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.design_services_rounded,
                            size: 56,
                            color: cs.onSurface.withOpacity(0.1),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.msgNoServices,
                            style: GoogleFonts.outfit(
                              color: cs.onSurface.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    itemCount: services.length,
                    itemBuilder: (context, i) {
                      return _ServiceCard(
                        service: services[i],
                        l10n: l10n,
                        onEdit: () => _showEditor(context, services[i]),
                        onDelete: () => _delete(services[i]),
                        onCopyCode: () => _copy(services[i].groupCode),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditor(BuildContext context, AppointmentGroup? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ServiceEditorSheet(
        existing: existing,
        service: _service,
        onSaved: () => Navigator.pop(ctx),
      ),
    );
  }

  Future<void> _delete(AppointmentGroup svc) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.btnDelete),
        content: Text('${svc.title}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.btnCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.btnDelete,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (ok == true && svc.id != null) await _service.deleteService(svc.id!);
  }

  void _copy(String code) {
    if (code.isEmpty) return;
    Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.msgCodeCopied),
          behavior: SnackBarBehavior.floating,
          width: 200,
        ),
      );
    }
  }
}

class _ServiceCard extends StatelessWidget {
  final AppointmentGroup service;
  final AppLocalizations l10n;
  final VoidCallback onEdit, onDelete, onCopyCode;
  const _ServiceCard({
    required this.service,
    required this.l10n,
    required this.onEdit,
    required this.onDelete,
    required this.onCopyCode,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = Color(service.color);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: PhobesCard(
        onTap: onEdit,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.design_services_rounded,
                      color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              service.title,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          if (!service.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: cs.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(l10n.apptInactiveBadge,
                                  style: GoogleFonts.outfit(
                                      fontSize: 9,
                                      color: cs.error,
                                      fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      Text(service.businessName,
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: cs.onSurface.withOpacity(0.4))),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') {
                      onEdit();
                    }
                    if (v == 'delete') {
                      onDelete();
                    }
                    if (v == 'copy') {
                      onCopyCode();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                        value: 'copy',
                        child: Row(children: [
                          const Icon(Icons.copy_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(l10n.btnCopy)
                        ])),
                    PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          const Icon(Icons.edit_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(l10n.btnEdit)
                        ])),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded, size: 18, color: cs.error),
                          const SizedBox(width: 8),
                          Text(l10n.btnDelete,
                              style: TextStyle(color: cs.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(Icons.access_time_rounded,
                    l10n.apptMinutes(service.durationMinutes), cs),
                const SizedBox(width: 8),
                if (service.price > 0)
                  _InfoChip(
                      Icons.payments_rounded,
                      '${service.price.toStringAsFixed(0)} ${service.currency}',
                      cs),
                const Spacer(),
                Tooltip(
                  message: l10n.btnCopy,
                  child: GestureDetector(
                    onTap: onCopyCode,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cs.primary.withOpacity(0.15)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.key_rounded, size: 12, color: cs.primary),
                          const SizedBox(width: 4),
                          Text(service.groupCode,
                              style: GoogleFonts.firaCode(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: cs.primary)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme cs;
  const _InfoChip(this.icon, this.text, this.cs);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: cs.surfaceVariant, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: cs.onSurface.withOpacity(0.4)),
            const SizedBox(width: 4),
            Text(text,
                style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: cs.onSurface.withOpacity(0.5),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
}

class _ServiceEditorSheet extends StatefulWidget {
  final AppointmentGroup? existing;
  final AppointmentService service;
  final VoidCallback onSaved;
  const _ServiceEditorSheet(
      {this.existing, required this.service, required this.onSaved});
  @override
  State<_ServiceEditorSheet> createState() => _ServiceEditorSheetState();
}

class _ServiceEditorSheetState extends State<_ServiceEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl,
      _businessCtrl,
      _phoneCtrl,
      _addressCtrl,
      _priceCtrl;
  late int _duration, _buffer, _startHour, _endHour, _cancelHours, _color;
  late List<int> _workingDays;
  late bool _isActive;
  bool _saving = false;
  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _titleCtrl = TextEditingController(text: s?.title ?? '');
    _businessCtrl = TextEditingController(text: s?.businessName ?? '');
    _phoneCtrl = TextEditingController(text: s?.businessPhone ?? '');
    _addressCtrl = TextEditingController(text: s?.businessAddress ?? '');
    _priceCtrl = TextEditingController(
        text: s != null && s.price > 0 ? s.price.toStringAsFixed(0) : '');
    _duration = s?.durationMinutes ?? 30;
    _buffer = s?.bufferMinutes ?? 0;
    _startHour = s?.startHour ?? 9;
    _endHour = s?.endHour ?? 18;
    _cancelHours = s?.minCancellationHours ?? 24;
    _workingDays = List<int>.from(s?.workingDays ?? [1, 2, 3, 4, 5]);
    _color = s?.color ?? AppointmentGroup.serviceColors.first;
    _isActive = s?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _businessCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final group = AppointmentGroup(
      id: widget.existing?.id,
      ownerId: widget.service.currentUserId ?? '',
      title: _titleCtrl.text.trim(),
      businessName: _businessCtrl.text.trim(),
      businessPhone:
          _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      businessAddress:
          _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text) ?? 0.0,
      durationMinutes: _duration,
      bufferMinutes: _buffer,
      minCancellationHours: _cancelHours,
      startDate: widget.existing?.startDate ?? now,
      endDate: widget.existing?.endDate ?? now.add(const Duration(days: 365)),
      startHour: _startHour,
      endHour: _endHour,
      groupCode: widget.existing?.groupCode ?? AppointmentGroup.generateCode(),
      workingDays: _workingDays,
      breaks: widget.existing?.breaks ?? [],
      color: _color,
      isActive: _isActive,
    );
    if (_isEditing) {
      await widget.service.updateService(group);
    } else {
      await widget.service.createService(group);
    }
    if (mounted) {
      setState(() => _saving = false);
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
            color: cs.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24))),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: cs.onSurface.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                children: [
                  Text(
                    _isEditing ? l10n.btnEdit : l10n.manageServices,
                    style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface),
                  ),
                  const Spacer(),
                  PhobesButton(
                      text: l10n.btnSave, isLoading: _saving, onPressed: _save),
                ],
              ),
              const SizedBox(height: 20),
              PhobesTextFormField(
                controller: _titleCtrl,
                labelText: l10n.serviceTitle,
                prefixIcon: Icons.design_services_rounded,
                validator: (v) =>
                    v == null || v.isEmpty ? l10n.fillAllFieldsPrompt : null,
              ),
              const SizedBox(height: 14),
              PhobesTextFormField(
                controller: _businessCtrl,
                labelText: l10n.businessName,
                prefixIcon: Icons.storefront_rounded,
                validator: (v) =>
                    v == null || v.isEmpty ? l10n.fillAllFieldsPrompt : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                      child: PhobesTextFormField(
                          controller: _phoneCtrl,
                          labelText: l10n.phone,
                          prefixIcon: Icons.phone_rounded)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: PhobesTextFormField(
                          controller: _priceCtrl,
                          labelText: l10n.price,
                          prefixIcon: Icons.payments_rounded,
                          keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 14),
              PhobesTextFormField(
                  controller: _addressCtrl,
                  labelText: l10n.address,
                  prefixIcon: Icons.location_on_rounded),
              const SizedBox(height: 20),
              Text(l10n.apptServiceColor,
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withOpacity(0.6))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: AppointmentGroup.serviceColors.map((c) {
                  final sel = _color == c;
                  return GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: sel
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                    color: Color(c).withOpacity(0.5),
                                    blurRadius: 10)
                              ]
                            : null,
                      ),
                      child: sel
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _duration,
                      onChanged: (v) => setState(() => _duration = v ?? 30),
                      decoration: InputDecoration(labelText: l10n.duration),
                      items: [15, 30, 45, 60, 90, 120]
                          .map((d) => DropdownMenuItem(
                              value: d, child: Text(l10n.apptMinutes(d))))
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _buffer,
                      onChanged: (v) => setState(() => _buffer = v ?? 0),
                      decoration: InputDecoration(labelText: l10n.apptBuffer),
                      items: [0, 5, 10, 15, 30]
                          .map((d) => DropdownMenuItem(
                              value: d, child: Text(l10n.apptMinutes(d))))
                          .toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _startHour,
                      onChanged: (v) => setState(() => _startHour = v ?? 9),
                      decoration:
                          InputDecoration(labelText: l10n.apptWorkHours),
                      items: List.generate(
                          24,
                          (i) => DropdownMenuItem(
                              value: i,
                              child:
                                  Text('${i.toString().padLeft(2, '0')}:00'))),
                    ),
                  ),
                  const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('–')),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _endHour,
                      onChanged: (v) => setState(() => _endHour = v ?? 18),
                      decoration: const InputDecoration(labelText: ''),
                      items: List.generate(
                          24,
                          (i) => DropdownMenuItem(
                              value: i,
                              child:
                                  Text('${i.toString().padLeft(2, '0')}:00'))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                children: [
                  (1, l10n.dayMon),
                  (2, l10n.dayTue),
                  (3, l10n.dayWed),
                  (4, l10n.dayThu),
                  (5, l10n.dayFri),
                  (6, l10n.daySat),
                  (7, l10n.daySun),
                ].map((d) {
                  return FilterChip(
                    label: Text(d.$2),
                    selected: _workingDays.contains(d.$1),
                    onSelected: (v) => setState(() {
                      if (v) {
                        _workingDays.add(d.$1);
                      } else {
                        _workingDays.remove(d.$1);
                      }
                    }),
                    selectedColor: cs.primary.withOpacity(0.15),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                  title: Text(l10n.apptServiceActive),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v)),
            ],
          ),
        ),
      ),
    );
  }
}
