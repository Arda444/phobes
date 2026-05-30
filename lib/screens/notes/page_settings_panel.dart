import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/page_sizes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/note_model.dart';

/// Sayfa boyutu, yön ve kenar boşluğu ayarlarını yönetir.
/// Callback ile üst widget'a değişiklikleri bildirir.
class PageSettingsPanel extends StatefulWidget {
  final String pageSize;
  final String pageOrientation;
  final PageMargins pageMargins;
  final void Function(String pageSize, String pageOrientation, PageMargins margins) onChanged;

  const PageSettingsPanel({
    super.key,
    required this.pageSize,
    required this.pageOrientation,
    required this.pageMargins,
    required this.onChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required String pageSize,
    required String pageOrientation,
    required PageMargins pageMargins,
    required void Function(String, String, PageMargins) onChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PageSettingsPanel(
        pageSize: pageSize,
        pageOrientation: pageOrientation,
        pageMargins: pageMargins,
        onChanged: onChanged,
      ),
    );
  }

  @override
  State<PageSettingsPanel> createState() => _PageSettingsPanelState();
}

class _PageSettingsPanelState extends State<PageSettingsPanel> {
  late String _pageSize;
  late String _orientation;
  late PageMargins _margins;

  late TextEditingController _topCtrl;
  late TextEditingController _rightCtrl;
  late TextEditingController _bottomCtrl;
  late TextEditingController _leftCtrl;

  bool _showCustomMargins = false;

  @override
  void initState() {
    super.initState();
    _pageSize    = widget.pageSize;
    _orientation = widget.pageOrientation;
    _margins     = widget.pageMargins;
    _showCustomMargins = _margins.presetName == 'custom';
    _initControllers();
  }

  void _initControllers() {
    _topCtrl    = TextEditingController(text: _margins.top.toStringAsFixed(0));
    _rightCtrl  = TextEditingController(text: _margins.right.toStringAsFixed(0));
    _bottomCtrl = TextEditingController(text: _margins.bottom.toStringAsFixed(0));
    _leftCtrl   = TextEditingController(text: _margins.left.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _topCtrl.dispose();
    _rightCtrl.dispose();
    _bottomCtrl.dispose();
    _leftCtrl.dispose();
    super.dispose();
  }

  void _notify() => widget.onChanged(_pageSize, _orientation, _margins);

  void _applyPreset(PageMargins m) {
    setState(() {
      _margins = m;
      _showCustomMargins = false;
      _topCtrl.text    = m.top.toStringAsFixed(0);
      _rightCtrl.text  = m.right.toStringAsFixed(0);
      _bottomCtrl.text = m.bottom.toStringAsFixed(0);
      _leftCtrl.text   = m.left.toStringAsFixed(0);
    });
    _notify();
  }

  void _applyCustom() {
    final t = double.tryParse(_topCtrl.text)    ?? _margins.top;
    final r = double.tryParse(_rightCtrl.text)  ?? _margins.right;
    final b = double.tryParse(_bottomCtrl.text) ?? _margins.bottom;
    final l = double.tryParse(_leftCtrl.text)   ?? _margins.left;
    setState(() => _margins = PageMargins(top: t, right: r, bottom: b, left: l));
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? cs.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [

            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: cs.outline.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Icon(Icons.description_outlined, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(l10n.notePageSettings,
                    style: GoogleFonts.outfit(
                        fontSize: 17, fontWeight: FontWeight.w700,),),
              ],
            ),
            const SizedBox(height: 24),

            _sectionLabel(context, l10n.notePageSizeLabel),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: NotePageSize.all.map((p) {
                final selected = _pageSize == p.key;
                return ChoiceChip(
                  label: Text(p.label,
                      style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,),),
                  selected: selected,
                  selectedColor: cs.primary,
                  labelStyle: TextStyle(
                      color: selected ? Colors.white : cs.onSurface.withOpacity(0.7),),
                  onSelected: (_) {
                    setState(() => _pageSize = p.key);
                    _notify();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            _sectionLabel(context, l10n.notePageOrientation),
            const SizedBox(height: 10),
            Row(
              children: [
                _OrientationButton(
                  label: l10n.pagePortrait,
                  icon: Icons.crop_portrait_rounded,
                  selected: _orientation == 'portrait',
                  onTap: () {
                    setState(() => _orientation = 'portrait');
                    _notify();
                  },
                  cs: cs,
                ),
                const SizedBox(width: 12),
                _OrientationButton(
                  label: l10n.pageLandscape,
                  icon: Icons.crop_landscape_rounded,
                  selected: _orientation == 'landscape',
                  onTap: () {
                    setState(() => _orientation = 'landscape');
                    _notify();
                  },
                  cs: cs,
                ),
              ],
            ),
            const SizedBox(height: 24),

            _sectionLabel(context, l10n.notePageMargins),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                _marginPreset(l10n.marginNormal, PageMargins.normal()),
                _marginPreset(l10n.marginNarrow, PageMargins.narrow()),
                _marginPreset(l10n.wide, PageMargins.wide()),
                _marginPreset(l10n.marginMirror, PageMargins.mirror()),
                _customChip(cs, l10n),
              ],
            ),

            if (_showCustomMargins) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _mmField(l10n.marginTop,  _topCtrl,    cs)),
                  const SizedBox(width: 8),
                  Expanded(child: _mmField(l10n.marginBottom,  _bottomCtrl, cs)),
                  const SizedBox(width: 8),
                  Expanded(child: _mmField(l10n.marginLeft,  _leftCtrl,   cs)),
                  const SizedBox(width: 8),
                  Expanded(child: _mmField(l10n.marginRight,  _rightCtrl,  cs)),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: _applyCustom,
                  child: Text(l10n.apply, style: GoogleFonts.outfit()),
                ),
              ),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Text(text,
        style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: cs.onSurface.withOpacity(0.45),),);
  }

  Widget _marginPreset(String label, PageMargins preset) {
    final cs = Theme.of(context).colorScheme;
    final selected = !_showCustomMargins && _margins.presetName == preset.presetName;
    return ChoiceChip(
      label: Text(label,
          style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,),),
      selected: selected,
      selectedColor: cs.primary,
      labelStyle: TextStyle(
          color: selected ? Colors.white : cs.onSurface.withOpacity(0.7),),
      onSelected: (_) => _applyPreset(preset),
    );
  }

  Widget _customChip(ColorScheme cs, AppLocalizations l10n) {
    return ChoiceChip(
      label: Text(l10n.custom,
          style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: _showCustomMargins ? FontWeight.w700 : FontWeight.w500,),),
      selected: _showCustomMargins,
      selectedColor: cs.primary,
      labelStyle: TextStyle(
          color: _showCustomMargins ? Colors.white : cs.onSurface.withOpacity(0.7),),
      onSelected: (_) => setState(() => _showCustomMargins = !_showCustomMargins),
    );
  }

  Widget _mmField(String label, TextEditingController ctrl, ColorScheme cs) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(fontSize: 13),
      decoration: InputDecoration(
        labelText: '$label (mm)',
        labelStyle: GoogleFonts.outfit(fontSize: 11),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        isDense: true,
      ),
    );
  }
}

class _OrientationButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _OrientationButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : cs.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18,
                color: selected ? Colors.white : cs.onSurface.withOpacity(0.6),),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Colors.white : cs.onSurface.withOpacity(0.7),),),
          ],
        ),
      ),
    );
  }
}
