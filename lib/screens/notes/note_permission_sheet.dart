import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../models/team_model.dart';
import '../../services/firebase_service.dart';

class NotePermissionSheet extends StatefulWidget {
  final String noteId;
  final String currentViewPerm;
  final String currentEditPerm;
  final List<String> currentAllowedUsers;
  final Team? team;

  const NotePermissionSheet({
    super.key,
    required this.noteId,
    required this.currentViewPerm,
    required this.currentEditPerm,
    required this.currentAllowedUsers,
    this.team,
  });

  @override
  State<NotePermissionSheet> createState() => _NotePermissionSheetState();
}

class _NotePermissionSheetState extends State<NotePermissionSheet> {
  late String _viewPerm;
  late String _editPerm;
  late List<String> _allowedUsers;
  bool _saving = false;
  List<Map<String, dynamic>> _teamMembers = [];

  @override
  void initState() {
    super.initState();
    _viewPerm = widget.currentViewPerm;
    _editPerm = widget.currentEditPerm;
    _allowedUsers = List.from(widget.currentAllowedUsers);
    if (widget.team != null) _loadMembers();
  }

  Future<void> _loadMembers() async {
    if (widget.team == null) return;
    final members = await FirebaseService().getUsersByIds(
      widget.team!.memberIds,
      teamId: widget.team!.id,
    );
    if (mounted) setState(() => _teamMembers = members);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.shield_rounded, color: cs.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n?.notePermissions ?? 'Permissions',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          _buildPermSection(
            title: l10n?.noteViewPermission ?? 'View Permission',
            icon: Icons.visibility_rounded,
            current: _viewPerm,
            onChanged: (v) => setState(() => _viewPerm = v),
            cs: cs,
            isDark: isDark,
            l10n: l10n,
          ),

          const SizedBox(height: 12),

          _buildPermSection(
            title: l10n?.noteEditPermission ?? 'Edit Permission',
            icon: Icons.edit_rounded,
            current: _editPerm,
            onChanged: (v) => setState(() => _editPerm = v),
            cs: cs,
            isDark: isDark,
            l10n: l10n,
          ),

          if ((_viewPerm == 'specific_users' || _editPerm == 'specific_users') &&
              _teamMembers.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildMemberList(cs, isDark),
          ],

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: cs.onPrimary,),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  l10n?.save ?? 'Save',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermSection({
    required String title,
    required IconData icon,
    required String current,
    required ValueChanged<String> onChanged,
    required ColorScheme cs,
    required bool isDark,
    AppLocalizations? l10n,
  }) {
    final options = [
      ('owner', l10n?.notePermOwner ?? 'Only Me', Icons.person_rounded),
      if (widget.team != null) ...[
        ('admins', l10n?.notePermAdmins ?? 'Admins Only', Icons.admin_panel_settings_rounded),
        ('team', l10n?.notePermTeam ?? 'Entire Team', Icons.groups_rounded),
        ('specific_users', l10n?.notePermSpecific ?? 'Specific Users', Icons.person_add_rounded),
      ],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: cs.onSurface.withOpacity(0.5)),
              const SizedBox(width: 8),
              Text(title,
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withOpacity(0.7),),),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: options.map((opt) {
              final (value, label, optIcon) = opt;
              final selected = current == value;
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onChanged(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? cs.primary.withOpacity(isDark ? 0.2 : 0.1)
                        : cs.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? cs.primary.withOpacity(0.5) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(optIcon,
                          size: 16,
                          color: selected ? cs.primary : cs.onSurface.withOpacity(0.5),),
                      const SizedBox(width: 6),
                      Text(label,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected ? cs.primary : cs.onSurface.withOpacity(0.7),
                          ),),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberList(ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.notePermissionSelectMembers,
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withOpacity(0.7),),),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _teamMembers.length,
              itemBuilder: (ctx, i) {
                final m = _teamMembers[i];
                final uid = m['id'] as String;
                final name = '${m['name'] ?? ''} ${m['surname'] ?? ''}'.trim();
                final selected = _allowedUsers.contains(uid);

                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: cs.primary.withOpacity(0.1),
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: GoogleFonts.outfit(
                            fontSize: 14, fontWeight: FontWeight.bold, color: cs.primary,),),
                  ),
                  title: Text(name, style: GoogleFonts.outfit(fontSize: 13)),
                  trailing: Checkbox(
                    value: selected,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _allowedUsers.add(uid);
                        } else {
                          _allowedUsers.remove(uid);
                        }
                      });
                    },
                    activeColor: cs.primary,
                  ),
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _allowedUsers.remove(uid);
                      } else {
                        _allowedUsers.add(uid);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      if (widget.noteId.isNotEmpty) {
        await FirebaseService().updateNotePermissions(
          widget.noteId,
          viewPermission: _viewPerm,
          editPermission: _editPerm,
          allowedUserIds: _allowedUsers,
        );
      }
      if (mounted) {
        Navigator.pop(context, {
          'viewPerm': _viewPerm,
          'editPerm': _editPerm,
          'allowedUsers': List<String>.from(_allowedUsers),
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }
}
