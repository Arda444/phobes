import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/book_model.dart';
import '../../services/book_service.dart';
import '../../widgets/phobes_widgets.dart';
import 'package:phobes/l10n/app_localizations.dart';
import 'book_goals_screen.dart';
import 'book_quotes_screen.dart';

class BookStatsScreen extends StatefulWidget {
  const BookStatsScreen({super.key});

  @override
  State<BookStatsScreen> createState() => _BookStatsScreenState();
}

class _BookStatsScreenState extends State<BookStatsScreen> {
  final BookService _bookService = BookService();
  Map<String, dynamic> _stats = {};
  List<Book> _recommendations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await _bookService.getReadingStats();
    final cats = List<String>.from(stats['preferredCategories'] ?? []);
    final authors = List<String>.from(stats['preferredAuthors'] ?? []);
    final recs = await _bookService.getRecommendations(
      preferredCategories: cats,
      preferredAuthors: authors,
    );
    if (mounted) {
      setState(() {
        _stats = stats;
        _recommendations = recs;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: UnconstrainedBox(
          child: PhobesIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
        ),
        title: Text(l10n.booksReadingStatsTitle,
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, color: cs.onSurface)),
        actions: [
          PhobesIconButton(
            icon: Icons.format_quote_rounded,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const BookQuotesScreen())),
          ),
          const SizedBox(width: 4),
          PhobesIconButton(
            icon: Icons.flag_rounded,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const BookGoalsScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? Center(child: PhobesLoadingIndicator(color: cs.primary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(maxWidth: isWide ? 720 : double.infinity),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCards(cs, l10n),
                        const SizedBox(height: 24),
                        _buildCategoryChart(cs, l10n),
                        const SizedBox(height: 24),
                        _buildReadingSpeed(cs, l10n),
                        const SizedBox(height: 24),
                        if (_recommendations.isNotEmpty)
                          _buildRecommendations(cs, l10n),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCards(ColorScheme cs, AppLocalizations l10n) {
    final total = _stats['totalBooks'] ?? 0;
    final read = _stats['readBooks'] ?? 0;
    final reading = _stats['readingBooks'] ?? 0;
    final toRead = _stats['toReadBooks'] ?? 0;
    final pages = _stats['totalPagesRead'] ?? 0;

    final cards = [
      ('📚', '$total', '${l10n.booksStatTotal} ${l10n.booksUnitBooks}', cs.primary),
      ('✅', '$read', l10n.booksStatusRead, const Color(0xFF22C55E)),
      ('📖', '$reading', l10n.booksStatusReading, const Color(0xFF3B82F6)),
      ('🔖', '$toRead', l10n.booksStatusToRead, const Color(0xFFF59E0B)),
      ('📄', '$pages', '${l10n.booksStatTotal} ${l10n.booksStatPages}', const Color(0xFF8B5CF6)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: cards.length > 6 ? 6 : cards.length,
      itemBuilder: (context, i) {
        if (i >= cards.length) return const SizedBox.shrink();
        final card = cards[i];
        return FadeInUp(
          delay: Duration(milliseconds: i * 60),
          child: PhobesCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(card.$1, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                Text(card.$2,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: card.$4,
                    )),
                Text(card.$3,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: cs.onSurface.withOpacity(0.45),
                    ),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChart(ColorScheme cs, AppLocalizations l10n) {
    final distribution =
        Map<String, int>.from(_stats['categoryDistribution'] ?? {});
    if (distribution.isEmpty) return const SizedBox.shrink();

    final total = distribution.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    const chartColors = [
      Color(0xFF6366F1), Color(0xFF3B82F6), Color(0xFF22C55E),
      Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFF8B5CF6),
      Color(0xFF06B6D4), Color(0xFFEC4899),
    ];

    final entries = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(6).toList();

    final sections = top.asMap().entries.map((e) {
      final color = chartColors[e.key % chartColors.length];
      final pct = e.value.value / total;
      return PieChartSectionData(
        value: e.value.value.toDouble(),
        title: '${(pct * 100).toInt()}%',
        color: color,
        radius: 60,
        titleStyle: GoogleFonts.outfit(
            fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return FadeInUp(
      child: PhobesCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.booksCategoryDistributionTitle,
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(0.5),
                    letterSpacing: 0.8)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 32,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: top.asMap().entries.map((e) {
                final color = chartColors[e.key % chartColors.length];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${e.value.key} (${e.value.value})',
                      style: GoogleFonts.outfit(
                          fontSize: 11, color: cs.onSurface.withOpacity(0.6)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingSpeed(ColorScheme cs, AppLocalizations l10n) {
    final avgPages = (_stats['avgPagesPerDay'] as double?) ?? 0.0;
    if (avgPages == 0) return const SizedBox.shrink();

    final pagesPerWeek = avgPages * 7;
    final booksPerMonth = avgPages * 30 / 300;

    return FadeInUp(
      child: PhobesCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.booksReadingSpeedTitle,
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(0.5),
                    letterSpacing: 0.8)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SpeedCard(
                    icon: '📖',
                    value: avgPages.toStringAsFixed(0),
                    label: l10n.booksPagesPerDay,
                    color: const Color(0xFF3B82F6),
                    cs: cs,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SpeedCard(
                    icon: '📅',
                    value: pagesPerWeek.toStringAsFixed(0),
                    label: l10n.booksPagesPerWeek,
                    color: const Color(0xFF8B5CF6),
                    cs: cs,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SpeedCard(
                    icon: '📚',
                    value: booksPerMonth.toStringAsFixed(1),
                    label: l10n.booksBooksPerMonth,
                    color: const Color(0xFF22C55E),
                    cs: cs,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.booksReadingSpeedFootnote,
              style: GoogleFonts.outfit(
                  fontSize: 10, color: cs.onSurface.withOpacity(0.3)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations(ColorScheme cs, AppLocalizations l10n) {
    return FadeInUp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.booksRecommendationsTitle,
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: cs.onSurface)),
          const SizedBox(height: 4),
          Text(l10n.booksRecommendationsSubtitleLong,
              style: GoogleFonts.outfit(
                  fontSize: 12, color: cs.onSurface.withOpacity(0.4))),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _recommendations.length,
              itemBuilder: (context, index) {
                final book = _recommendations[index];
                return FadeInRight(
                  delay: Duration(milliseconds: index * 50),
                  child: _RecommendationCard(book: book, cs: cs),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color color;
  final ColorScheme cs;

  const _SpeedCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 9, color: cs.onSurface.withOpacity(0.45)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final Book book;
  final ColorScheme cs;

  const _RecommendationCard({required this.book, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: book.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: book.coverUrl!,
                      width: 120, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _placeholder(book.title),
                    )
                  : _placeholder(book.title),
            ),
          ),
          const SizedBox(height: 6),
          Text(book.title,
              style: GoogleFonts.outfit(
                  fontSize: 10, fontWeight: FontWeight.w600, color: cs.onSurface),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if (book.authors.isNotEmpty)
            Text(book.authors.first,
                style: GoogleFonts.outfit(
                    fontSize: 9, color: cs.onSurface.withOpacity(0.4)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _placeholder(String title) {
    const colors = [Color(0xFF6366F1), Color(0xFF3B82F6), Color(0xFF22C55E)];
    final c = colors[title.hashCode.abs() % colors.length];
    return Container(
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.menu_book_rounded, color: Colors.white54, size: 32),
    );
  }
}
