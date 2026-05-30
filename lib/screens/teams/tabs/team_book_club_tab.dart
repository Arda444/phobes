import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/book_club_model.dart';
import '../../../models/team_model.dart';
import '../../../services/book_club_service.dart';
import '../../../widgets/phobes_widgets.dart';
import '../../books/book_search_screen.dart';
import '../../../l10n/app_localizations.dart';

class TeamBookClubTab extends StatefulWidget {
  final Team team;
  const TeamBookClubTab({super.key, required this.team});

  @override
  State<TeamBookClubTab> createState() => _TeamBookClubTabState();
}

class _TeamBookClubTabState extends State<TeamBookClubTab> {
  final BookClubService _clubService = BookClubService();
  late final Stream<BookClub?> _activeClubStream;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _activeClubStream =
        _clubService.getActiveClubStream(widget.team.id).asBroadcastStream();
  }

  bool get _isAdmin =>
      widget.team.ownerId == _uid ||
      widget.team.adminIds.contains(_uid);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<BookClub?>(
      stream: _activeClubStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Center(child: PhobesLoadingIndicator(color: cs.primary));
        }

        final club = snapshot.data;

        if (club == null) {
          return _buildNoClub(cs);
        }

        return _buildActiveClub(club, cs);
      },
    );
  }

  // ─── No active club ───────────────────────────────────────────────────────

  Widget _buildNoClub(ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: FadeInUp(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const PhobesGlassCard(
                padding: EdgeInsets.all(28),
                borderRadius: 40,
                child: Text('📚', style: TextStyle(fontSize: 48)),
              ),
              const SizedBox(height: 24),
              Text(l10n.teamBookClubEmptyTitle,
                  style: GoogleFonts.outfit(
                      fontSize: 20, fontWeight: FontWeight.bold,
                      color: cs.onSurface)),
              const SizedBox(height: 8),
              Text(
                l10n.teamBookClubEmptyDescription,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 13, color: cs.onSurface.withOpacity(0.4)),
              ),
              if (_isAdmin) ...[
                const SizedBox(height: 28),
                PhobesButton(
                  text: l10n.teamBookClubStart,
                  icon: Icons.groups_rounded,
                  onPressed: () => _showCreateClubSheet(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Active club ──────────────────────────────────────────────────────────

  Widget _buildActiveClub(BookClub club, ColorScheme cs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              // Header card
              _buildClubHeader(club, cs, isDark),
              const SizedBox(height: 16),

              if (!club.hasBook) ...[
                _buildPickBookCard(club, cs),
              ] else ...[
                // Member progress
                _buildMemberProgress(club, cs),
                const SizedBox(height: 16),
                // My progress update
                if (_uid != null) _buildMyProgressCard(club, cs, isDark),
                const SizedBox(height: 16),
                // Target date
                _buildTargetCard(club, cs),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClubHeader(BookClub club, ColorScheme cs, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF8B5E3C).withOpacity(0.15),
            cs.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Book cover or placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: club.bookCoverUrl != null
                ? CachedNetworkImage(
                    imageUrl: club.bookCoverUrl!,
                    width: 60, height: 88, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _bookPlaceholder(club.bookTitle ?? ''),
                  )
                : _bookPlaceholder(club.bookTitle ?? ''),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(club.name,
                    style: GoogleFonts.outfit(
                        fontSize: 11, color: cs.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text(
                  club.bookTitle ?? l10n.teamBookNotSelected,
                  style: GoogleFonts.outfit(
                      fontSize: 16, fontWeight: FontWeight.bold,
                      color: cs.onSurface),
                  maxLines: 2,
                ),
                if (club.bookAuthors.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(club.bookAuthors.join(', '),
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: cs.onSurface.withOpacity(0.45)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                if (club.hasBook && club.bookPageCount > 0) ...[
                  const SizedBox(height: 6),
                  // Overall club progress
                  Row(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: club.avgProgress,
                          minHeight: 5,
                          backgroundColor: const Color(0xFF8B5E3C).withOpacity(0.1),
                          color: const Color(0xFF8B5E3C),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(club.avgProgress * 100).toInt()}%',
                      style: GoogleFonts.outfit(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: const Color(0xFF8B5E3C)),
                    ),
                  ]),
                ],
              ],
            ),
          ),
          if (_isAdmin)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded,
                  color: cs.onSurface.withOpacity(0.4), size: 20),
              onSelected: (val) {
                if (val == 'change') _showBookSearch(context, club);
                if (val == 'end') _confirmEndClub(context, club, cs);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: 'change', child: Text(l10n.teamBookChange)),
                PopupMenuItem(value: 'end', child: Text(l10n.teamBookClubEnd)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPickBookCard(BookClub club, ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PhobesCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.menu_book_rounded,
                size: 40, color: cs.onSurface.withOpacity(0.2)),
            const SizedBox(height: 12),
            Text(l10n.teamBookPickPrompt,
                style: GoogleFonts.outfit(
                    fontSize: 15, fontWeight: FontWeight.bold,
                    color: cs.onSurface)),
            const SizedBox(height: 16),
            if (_isAdmin)
              PhobesButton(
                text: l10n.teamBookSelect,
                icon: Icons.search_rounded,
                onPressed: () => _showBookSearch(context, club),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberProgress(BookClub club, ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    final sorted = club.memberProgress.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PhobesCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.teamMemberProgressTitle,
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700, fontSize: 13,
                    color: cs.onSurface.withOpacity(0.5), letterSpacing: 0.8)),
            const SizedBox(height: 16),
            ...sorted.asMap().entries.map((e) {
              final uid = e.value.key;
              final pages = e.value.value;
              final pct = club.progressForMember(uid);
              final name = club.memberNames[uid] ?? l10n.teamMemberDefaultName;
              final isMe = uid == _uid;
              final rank = e.key + 1;

              return FadeInLeft(
                delay: Duration(milliseconds: e.key * 60),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      // Rank
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: rank == 1
                              ? const Color(0xFFFBBF24).withOpacity(0.15)
                              : cs.onSurface.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '$rank',
                            style: TextStyle(
                              fontSize: rank <= 3 ? 12 : 10,
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isMe ? l10n.teamMemberYou(name) : name,
                                  style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
                                      color: cs.onSurface),
                                ),
                                Text(
                                  l10n.teamBookPagesProgress(
                                      pages, club.bookPageCount),
                                  style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: cs.onSurface.withOpacity(0.45)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 6,
                                backgroundColor: cs.onSurface.withOpacity(0.06),
                                color: isMe
                                    ? cs.primary
                                    : const Color(0xFF8B5E3C).withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(pct * 100).toInt()}%',
                        style: GoogleFonts.outfit(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: isMe ? cs.primary : cs.onSurface.withOpacity(0.4)),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMyProgressCard(BookClub club, ColorScheme cs, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final myPages = club.memberProgress[_uid] ?? 0;
    final ctrl = TextEditingController(text: myPages.toString());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PhobesCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.teamUpdateMyProgress,
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700, fontSize: 13,
                    color: cs.onSurface.withOpacity(0.5), letterSpacing: 0.8)),
            const SizedBox(height: 12),
            if (club.bookPageCount > 0)
              Slider(
                value: myPages.toDouble(),
                max: club.bookPageCount.toDouble(),
                activeColor: cs.primary,
                onChanged: (v) {
                  ctrl.text = v.toInt().toString();
                },
                onChangeEnd: (v) => _clubService.updateMyProgress(
                  teamId: widget.team.id,
                  clubId: club.id!,
                  currentPage: v.toInt(),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.outfit(color: cs.onSurface),
                    decoration: InputDecoration(
                      labelText: l10n.teamCurrentPageLabel,
                      suffixText: '/ ${club.bookPageCount}',
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    onSubmitted: (v) {
                      final p = (int.tryParse(v) ?? 0)
                          .clamp(0, club.bookPageCount);
                      _clubService.updateMyProgress(
                        teamId: widget.team.id,
                        clubId: club.id!,
                        currentPage: p,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetCard(BookClub club, ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PhobesCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.calendar_today_rounded,
                  color: Color(0xFF3B82F6), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.teamTargetFinish,
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: cs.onSurface.withOpacity(0.45))),
                  Text(
                    club.targetFinishDate != null
                        ? '${club.targetFinishDate!.day}.${club.targetFinishDate!.month}.${club.targetFinishDate!.year}'
                        : l10n.teamNotSet,
                    style: GoogleFonts.outfit(
                        fontSize: 15, fontWeight: FontWeight.bold,
                        color: cs.onSurface),
                  ),
                  if (club.daysLeft > 0)
                    Text(l10n.teamDaysLeft(club.daysLeft),
                        style: GoogleFonts.outfit(
                            fontSize: 11, color: const Color(0xFF3B82F6))),
                  if (club.daysLeft == 0)
                    Text(l10n.teamLastDayToday,
                        style: GoogleFonts.outfit(
                            fontSize: 11, color: const Color(0xFFEF4444))),
                ],
              ),
            ),
            if (_isAdmin)
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: club.targetFinishDate ??
                        DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    await _clubService.setTargetFinishDate(
                      teamId: widget.team.id,
                      clubId: club.id!,
                      date: picked,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF3B82F6).withOpacity(0.2)),
                  ),
                  child: Text(l10n.teamSelect,
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: const Color(0xFF3B82F6),
                          fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  void _showCreateClubSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final ctrl = TextEditingController(
        text: '${widget.team.name} ${l10n.teamTabBookClub}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(l10n.teamBookClubStart,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold, fontSize: 18, color: cs.onSurface)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                style: GoogleFonts.outfit(color: cs.onSurface),
                decoration: InputDecoration(
                  labelText: l10n.teamClubNameLabel,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              PhobesButton(
                text: l10n.teamCreateClub,
                icon: Icons.groups_rounded,
                width: double.infinity,
                onPressed: () async {
                  if (ctrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  await _clubService.createClub(
                    teamId: widget.team.id,
                    name: ctrl.text.trim(),
                    memberIds: widget.team.memberIds,
                    memberNames: {},
                  );
                  ctrl.dispose();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookSearch(BuildContext context, BookClub club) {
    final l10n = AppLocalizations.of(context)!;
    BookSearchScreen.open(
      context,
      onBookPicked: (book) async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 21)),
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
          helpText: l10n.teamTargetFinishDateHelp,
        );
        await _clubService.setCurrentBook(
          teamId: widget.team.id,
          clubId: club.id!,
          book: book,
          targetFinishDate: date,
        );
      },
    );
  }

  Future<void> _confirmEndClub(
      BuildContext context, BookClub club, ColorScheme cs) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.teamBookClubEnd,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(l10n.teamEndClubConfirm,
            style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel, style: GoogleFonts.outfit()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.teamFinish,
                style: GoogleFonts.outfit(
                    color: cs.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _clubService.deactivateClub(
        teamId: widget.team.id,
        clubId: club.id!,
      );
    }
  }

  Widget _bookPlaceholder(String title) {
    const colors = [Color(0xFF6366F1), Color(0xFF3B82F6), Color(0xFF8B5E3C)];
    final c = colors[title.hashCode.abs() % colors.length];
    return Container(
      width: 60, height: 88,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c, c.withOpacity(0.7)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.menu_book_rounded, color: Colors.white54, size: 28),
    );
  }
}

