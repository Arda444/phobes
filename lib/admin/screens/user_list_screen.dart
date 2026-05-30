import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/admin_ui_system.dart';
import '../admin_service.dart';
import '../../l10n/app_localizations.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _filterStatus = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.adminUserDatabase,
                        style: AdminUISystem.titleStyle
                            .copyWith(color: cs.onSurface),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.adminUserDatabaseSubtitle,
                        style: AdminUISystem.subtitleStyle(context),
                      ),
                    ],
                  ),
                ),
                Flexible(child: _buildFilterChips(context, isDark, cs)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildSearchBar(isDark, cs),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var docs = snap.data?.docs ?? [];

                if (_filterStatus == 'banned') {
                  docs = docs.where((d) => d.data()['banned'] == true).toList();
                } else if (_filterStatus == 'active') {
                  docs = docs.where((d) => d.data()['banned'] != true).toList();
                }

                if (_search.isNotEmpty) {
                  docs = docs.where((d) {
                    final data = d.data();
                    final email =
                        (data['email'] as String? ?? '').toLowerCase();
                    final name = (data['displayName'] as String? ??
                            data['name'] as String? ??
                            '')
                        .toLowerCase();
                    final uid = d.id.toLowerCase();
                    return email.contains(_search) ||
                        name.contains(_search) ||
                        uid.contains(_search);
                  }).toList();
                }

                if (docs.isEmpty) return _buildEmptyState(isDark, cs);

                return LayoutBuilder(
                  builder: (context, constraints) {
                    const double spacing = 22;
                    final int crossCount = constraints.maxWidth > 1400
                        ? 5
                        : (constraints.maxWidth > 1100
                            ? 4
                            : (constraints.maxWidth > 700
                                ? 3
                                : (constraints.maxWidth > 500 ? 2 : 1)));
                    final double itemWidth = (constraints.maxWidth -
                            48 -
                            (spacing * (crossCount - 1))) /
                        crossCount;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: docs
                            .map(
                              (doc) => ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: itemWidth,
                                  minWidth: itemWidth,
                                  minHeight: 220,
                                ),
                                child: _UserGridCard(
                                    uid: doc.id, data: doc.data()),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, bool isDark, ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outline.withOpacity(0.1)),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          _StatusChip(
            label: l10n.filterAll,
            selected: _filterStatus == 'all',
            onTap: () => setState(() => _filterStatus = 'all'),
            color: AdminUISystem.kElectricBlue(context),
          ),
          _StatusChip(
            label: l10n.statusActive,
            selected: _filterStatus == 'active',
            onTap: () => setState(() => _filterStatus = 'active'),
            color: Colors.green.shade400,
          ),
          _StatusChip(
            label: l10n.statusBanned,
            selected: _filterStatus == 'banned',
            onTap: () => setState(() => _filterStatus = 'banned'),
            color: Colors.red.shade400,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.02)
            : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outline.withOpacity(0.12)),
      ),
      child: TextField(
        controller: _searchCtrl,
        style: GoogleFonts.outfit(
            fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface),
        onChanged: (v) => setState(() => _search = v.toLowerCase()),
        decoration: InputDecoration(
          hintText: l10n.adminSearchUsers,
          hintStyle: GoogleFonts.outfit(
              color: cs.onSurface.withOpacity(0.3), fontSize: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 18, right: 10),
            child: Icon(Icons.search_rounded, color: cs.primary, size: 22),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 50),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 20, color: cs.onSurface.withOpacity(0.4)),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _search = '');
                  },
                )
              : null,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.dashboard_customize_rounded,
                size: 52, color: cs.primary.withOpacity(0.2)),
          ),
          const SizedBox(height: 28),
          Text(
            l10n.adminNoUsersFound,
            style: GoogleFonts.outfit(
                fontSize: 20, fontWeight: FontWeight.w800, color: cs.onSurface),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.adminNoUsersFoundSubtitle,
            style: AdminUISystem.subtitleStyle(context),
          ),
        ],
      ),
    );
  }
}

class _UserGridCard extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> data;

  const _UserGridCard({required this.uid, required this.data});

  @override
  State<_UserGridCard> createState() => _UserGridCardState();
}

class _UserGridCardState extends State<_UserGridCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final l10n = AppLocalizations.of(context)!;
    final name = widget.data['displayName'] as String? ??
        widget.data['name'] as String? ??
        l10n.adminUserGuest;
    final email = widget.data['email'] as String? ?? l10n.adminEmailNotSet;
    final role = widget.data['role'] as String? ?? l10n.adminRoleUser;
    final banned = widget.data['banned'] as bool? ?? false;
    final createdAt = widget.data['createdAt'] as Timestamp?;

    final roleColor = banned
        ? Colors.red.shade400
        : (role == 'Admin' || role == l10n.adminRoleAdmin
            ? AdminUISystem.kNeonPurple(context)
            : AdminUISystem.kElectricBlue(context));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuart,
        decoration: AdminUISystem.cardDecoration(context,
                borderColor: _isHovered ? roleColor.withOpacity(0.6) : null)
            .copyWith(
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                      color: roleColor.withOpacity(0.25),
                      blurRadius: 30,
                      offset: const Offset(0, 12)),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Ambient Glow
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 100,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isHovered ? 1.0 : 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: LinearGradient(
                      colors: [roleColor.withOpacity(0.12), Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildRoleBadge(role, banned, roleColor),
                      _buildActionMenu(context, widget.uid, banned, role, cs,
                          isDark, widget.data['lastIp'] as String?),
                    ],
                  ),
                  const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    transform: Matrix4.identity()
                      ..scale(_isHovered ? 1.08 : 1.0),
                    alignment: Alignment.center,
                    child: _buildAvatar(name, roleColor, isDark),
                  ),
                  const Spacer(),
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.alternate_email_rounded,
                          size: 12, color: cs.onSurface.withOpacity(0.3)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          email,
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: cs.onSurface.withOpacity(0.5),
                              fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Divider(height: 1, color: cs.outline.withOpacity(0.08)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        createdAt != null
                            ? DateFormat('dd.MM.yy').format(createdAt.toDate())
                            : 'Bilinmiyor',
                        style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface.withOpacity(0.4)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.onSurface.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${widget.uid.substring(0, 6).toUpperCase()}',
                          style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface.withOpacity(0.5)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, Color color, bool isDark) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.6) : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
            color: color.withOpacity(_isHovered ? 0.7 : 0.3), width: 2.5),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role, bool banned, Color color) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.6), blurRadius: 4)
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            banned
                ? l10n.statusBanned.toUpperCase()
                : (role == 'Admin' ? l10n.adminRoleAdmin : role).toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionMenu(BuildContext context, String uid, bool banned,
      String role, ColorScheme cs, bool isDark, String? lastIp) {
    final l10n = AppLocalizations.of(context)!;
    final isAdminRole =
        role == 'Admin' || role == l10n.adminRoleAdmin;
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.black.withOpacity(0.04),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.more_horiz_rounded,
            size: 20, color: cs.onSurface.withOpacity(0.6)),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 10,
      offset: const Offset(0, 44),
      onSelected: (val) async {
        if (val == 'ban') {
          await AdminService.updateUserStatus(uid, banned: !banned);
        } else if (val == 'role') {
          final makeAdmin = !isAdminRole;
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(makeAdmin ? 'Admin yap' : 'Admin kaldır'),
              content: Text(makeAdmin
                  ? 'Bu kullanıcıya admin yetkisi verilsin mi?'
                  : 'Admin yetkisi kaldırılsın mı?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('İptal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Onayla'),
                ),
              ],
            ),
          );
          if (ok != true) return;
          try {
            await AdminService.setAdminRole(uid, makeAdmin);
            if (!context.mounted) return;
            AdminUISystem.showSuccessSnackBar(
              context,
              makeAdmin
                  ? 'Admin yetkisi verildi. Kullanıcı yeniden giriş yapmalı.'
                  : 'Admin yetkisi kaldırıldı.',
            );
          } catch (e) {
            if (!context.mounted) return;
            AdminUISystem.showErrorSnackBar(context, '$e');
          }
        } else if (val == 'ipban' && lastIp != null && lastIp.isNotEmpty) {
          await AdminService.addIpBan(lastIp, 'Admin panel');
          if (!context.mounted) return;
          AdminUISystem.showSuccessSnackBar(context, 'IP engellendi: $lastIp');
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'ban',
          child: Row(
            children: [
              Icon(banned ? Icons.check_circle_rounded : Icons.gavel_rounded,
                  size: 20, color: banned ? Colors.green : Colors.red),
              const SizedBox(width: 14),
              Text(
                banned ? l10n.adminUnbanUser : l10n.adminBanUser,
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: cs.onSurface),
              ),
            ],
          ),
        ),
        if (lastIp != null && lastIp.isNotEmpty)
          PopupMenuItem(
            value: 'ipban',
            child: Row(
              children: [
                const Icon(Icons.wifi_off_rounded, size: 20, color: Colors.orange),
                const SizedBox(width: 14),
                Text('IP engelle ($lastIp)',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'role',
          child: Row(
            children: [
              Icon(
                isAdminRole
                    ? Icons.person_off_rounded
                    : Icons.admin_panel_settings_rounded,
                size: 20,
                color: AdminUISystem.kNeonPurple(context),
              ),
              const SizedBox(width: 14),
              Text(
                isAdminRole ? l10n.adminDemoteRole : l10n.adminPromoteRole,
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: cs.onSurface),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _StatusChip(
      {required this.label,
      required this.selected,
      required this.onTap,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.9) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6))
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            color: selected ? Colors.white : color.withOpacity(0.7),
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
