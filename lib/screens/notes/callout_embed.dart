import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/phobes_form_wrapper.dart';
import 'embed_utils.dart';

// ─────────────────────────────── Types ───────────────────────────────────────

enum CalloutType {
  tip('tip', '💡', 0xFF00BFA5, 'İpucu', 'Faydalı bir bilgi veya öneri'),
  info('info', 'ℹ️', 0xFF4285F4, 'Bilgi', 'Önemli bir açıklama'),
  warning('warning', '⚠️', 0xFFFF9800, 'Uyarı', 'Dikkat edilmesi gereken bir durum'),
  danger('danger', '🚨', 0xFFE53935, 'Dikkat', 'Kritik bir uyarı veya hata');

  final String key;
  final String emoji;
  final int color;
  final String label;
  final String description;
  const CalloutType(
      this.key, this.emoji, this.color, this.label, this.description);

  static CalloutType fromKey(String k) => CalloutType.values
      .firstWhere((t) => t.key == k, orElse: () => CalloutType.info);

  String localizedLabel(AppLocalizations l) {
    switch (this) {
      case CalloutType.tip:
        return l.noteCalloutTip;
      case CalloutType.info:
        return l.noteCalloutInfo;
      case CalloutType.warning:
        return l.noteCalloutWarning;
      case CalloutType.danger:
        return l.noteCalloutDanger;
    }
  }
}

// ─────────────────────────────── Data ────────────────────────────────────────

class CalloutData {
  final String type;
  final String text;

  const CalloutData({required this.type, required this.text});

  Map<String, dynamic> toJson() => {'type': type, 'text': text};

  factory CalloutData.fromJson(Map<String, dynamic> json) =>
      CalloutData(type: json['type'] ?? 'info', text: json['text'] ?? '');

  CalloutData copyWith({String? type, String? text}) =>
      CalloutData(type: type ?? this.type, text: text ?? this.text);
}

// ─────────────────────────────── Embed ───────────────────────────────────────

class CalloutBlockEmbed extends CustomBlockEmbed {
  const CalloutBlockEmbed(String value) : super(calloutType, value);
  static const String calloutType = 'callout';

  static CalloutBlockEmbed fromData(CalloutData data) =>
      CalloutBlockEmbed(jsonEncode(data.toJson()));

  CalloutData get calloutData => CalloutData.fromJson(jsonDecode(data));
}

class CalloutEmbedBuilder extends EmbedBuilder {
  @override
  String get key => CalloutBlockEmbed.calloutType;

  @override
  bool get expanded => true;

  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle textStyle) {
    try {
      final callout = CalloutData.fromJson(jsonDecode(node.value.data));
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: _CalloutWidget(
          data: callout,
          readOnly: readOnly,
          onUpdate: (updated) {
            if (readOnly) return;
            final result =
                getCustomEmbedNode(controller, controller.selection.start);
            if (result == null) return;
            controller.replaceText(
                result.offset, 1, CalloutBlockEmbed.fromData(updated), null);
          },
        ),
      );
    } catch (_) {
      return embedError(context);
    }
  }
}

// ────────────────────────────── Widget ───────────────────────────────────────

class _CalloutWidget extends StatefulWidget {
  final CalloutData data;
  final bool readOnly;
  final ValueChanged<CalloutData> onUpdate;

  const _CalloutWidget({
    required this.data,
    required this.readOnly,
    required this.onUpdate,
  });

  @override
  State<_CalloutWidget> createState() => _CalloutWidgetState();
}

class _CalloutWidgetState extends State<_CalloutWidget> {
  late TextEditingController _ctrl;
  late CalloutData _data;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
    _ctrl = TextEditingController(text: _data.text);
  }

  @override
  void didUpdateWidget(_CalloutWidget old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) {
      _data = widget.data;
      if (_ctrl.text != _data.text) _ctrl.text = _data.text;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ct = CalloutType.fromKey(_data.type);
    final accent = Color(ct.color);

    return Container(
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Accent stripe ───────────────────────────────────────────────
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12)),
              ),
            ),

            // ── Content ─────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(ct.emoji,
                                style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 5),
                            Text(
                              ct.localizedLabel(l10n).toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: accent,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (!widget.readOnly)
                        _TypePicker(
                          current: _data.type,
                          onSelected: (type) {
                            setState(() => _data = _data.copyWith(type: type));
                            widget.onUpdate(_data);
                          },
                        ),
                    ]),
                    const SizedBox(height: 8),

                    // Text body
                    widget.readOnly
                        ? Text(
                            _data.text,
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              color: const Color(0xFF1A1A1A).withOpacity(0.82),
                              height: 1.5,
                            ),
                          )
                        : TextField(
                            controller: _ctrl,
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              color:
                                  const Color(0xFF1A1A1A).withOpacity(0.82),
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)!
                                  .noteCalloutPlaceholder,
                              hintStyle: GoogleFonts.outfit(
                                fontSize: 13.5,
                                color: const Color(0xFF1A1A1A)
                                    .withOpacity(0.28),
                                height: 1.5,
                              ),
                              border: InputBorder.none,
                              filled: false,
                              isCollapsed: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            maxLines: null,
                            onChanged: (v) {
                              _data = _data.copyWith(text: v);
                              widget.onUpdate(_data);
                            },
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── Type picker ─────────────────────────────────────────

class _TypePicker extends StatelessWidget {
  final String current;
  final ValueChanged<String> onSelected;

  const _TypePicker({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      tooltip: l10n.noteCalloutAdd,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      icon: Icon(
        Icons.swap_horiz_rounded,
        size: 16,
        color: const Color(0xFF1A1A1A).withOpacity(0.3),
      ),
      onSelected: onSelected,
      itemBuilder: (_) => CalloutType.values
          .map((t) => PopupMenuItem<String>(
                value: t.key,
                child: Row(children: [
                  Text(t.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.localizedLabel(l10n),
                        style: GoogleFonts.outfit(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(t.description,
                        style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: const Color(0xFF1A1A1A).withOpacity(0.45))),
                  ]),
                  if (t.key == current) ...[
                    const Spacer(),
                    Icon(Icons.check_rounded,
                        size: 14, color: Color(t.color)),
                  ],
                ]),
              ))
          .toList(),
    );
  }
}

// ───────────────────── Insert panel / sheet ──────────────────────────────────

Future<CalloutData?> showInsertCalloutDialog(BuildContext context) {
  return PhobesFormWrapper.show<CalloutData>(
    context,
    title: AppLocalizations.of(context)!.noteCalloutAdd,
    panelWidth: 400,
    form: const _InsertCalloutForm(),
  );
}

class _InsertCalloutForm extends StatelessWidget {
  const _InsertCalloutForm();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.noteCalloutAdd,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: cs.onSurface.withOpacity(0.45),
            ),
          ),
          const SizedBox(height: 16),
          ...CalloutType.values.map((t) {
            final color = Color(t.color);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: () => Navigator.pop(
                  context,
                  CalloutData(type: t.key, text: ''),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color: color.withOpacity(0.06),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Text(t.emoji, style: const TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.localizedLabel(l10n),
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t.description,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: cs.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: color.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: BorderSide(color: cs.outline.withOpacity(0.3)),
              ),
              child: Text(
                l10n.cancel,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
