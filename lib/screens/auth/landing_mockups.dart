import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../widgets/calendar/calendar_day_card.dart';
import '../../models/task_model.dart';
import '../../models/appointment_model.dart';
import '../../models/note_model.dart';
import '../../widgets/phobes_widgets.dart';

// ──────────────────────────────────────────────
// 1. CALENDAR WEEKLY VIEW MOCKUP
// ──────────────────────────────────────────────

class CodeCalendarMockup extends StatefulWidget {
  const CodeCalendarMockup({super.key});

  @override
  State<CodeCalendarMockup> createState() => _CodeCalendarMockupState();
}

class _CodeCalendarMockupState extends State<CodeCalendarMockup> {
  late DateTime _selectedDay;
  late List<DateTime> _weekDays;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _weekDays = _getWeekDays(_selectedDay);
  }

  List<DateTime> _getWeekDays(DateTime focused) {
    int dayOffset = focused.weekday - 1;
    DateTime monday = focused.subtract(Duration(days: dayOffset));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMockHeader(cs),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              // Helper to generate a row of cards
              Widget buildCardRow(List<DateTime> days, int startIndex) {
                return Row(
                  children: List.generate(days.length, (idx) {
                    final day = days[idx];
                    final globalIdx = startIndex + idx;
                    return CalendarDayCard(
                      day: day,
                      events: _getMockEvents(day),
                      notes: _getMockNotes(day),
                      isSelected: DateUtils.isSameDay(day, _selectedDay),
                      animationDelay: Duration(milliseconds: 100 * globalIdx),
                      onTap: () => setState(() => _selectedDay = day),
                    );
                  }),
                );
              }

              if (isMobile) {
                return Column(
                  children: [
                    SizedBox(
                      height: 150,
                      child: buildCardRow(_weekDays.sublist(0, 3), 0),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 150,
                      child: buildCardRow(_weekDays.sublist(3, 6), 3),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 150,
                      child: Row(
                        children: [
                          // 7th Day
                          CalendarDayCard(
                            day: _weekDays[6],
                            events: _getMockEvents(_weekDays[6]),
                            notes: _getMockNotes(_weekDays[6]),
                            isSelected:
                                DateUtils.isSameDay(_weekDays[6], _selectedDay),
                            animationDelay: const Duration(milliseconds: 600),
                            onTap: () =>
                                setState(() => _selectedDay = _weekDays[6]),
                          ),
                          // Empty placeholders to balance the layout width naturally
                          const Spacer(),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ],
                );
              }

              // Normal Desktop/Tablet View (1 Row)
              return SizedBox(
                height: 220,
                child: buildCardRow(_weekDays, 0),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip("3 Görev", Icons.task_alt_rounded, cs.primary, cs),
              const SizedBox(width: 8),
              _buildStatChip(
                  "1 Randevu", Icons.event_rounded, Colors.orange, cs),
              const SizedBox(width: 8),
              _buildStatChip("2 Not", Icons.note_rounded, Colors.amber, cs),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMockHeader(ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMMM yyyy', 'tr_TR').format(_selectedDay),
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Haftalık Görünüm",
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.4),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildSmallIconBtn(Icons.chevron_left_rounded, cs),
            const SizedBox(width: 8),
            _buildSmallIconBtn(Icons.chevron_right_rounded, cs),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallIconBtn(IconData icon, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: cs.primary),
    );
  }

  Widget _buildStatChip(
      String label, IconData icon, Color color, ColorScheme cs) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label,
                  style: GoogleFonts.outfit(
                      fontSize: 11, fontWeight: FontWeight.w600, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic> _getMockEvents(DateTime day) {
    if (day.weekday == 1) {
      return [
        Task(
          userId: 'mock',
          title: 'Plan',
          startTime: day.add(const Duration(hours: 9)),
          endTime: day.add(const Duration(hours: 10)),
          color: 0xFF4285F4,
        ),
        Appointment(
          userId: 'mock',
          title: 'Randevu',
          clientName: 'Phobes Nova',
          date: day.add(const Duration(hours: 14)),
          durationMinutes: 60,
        ),
      ];
    }
    if (day.weekday == 3) {
      return [
        Task(
          userId: 'mock',
          title: 'Spor',
          startTime: day.add(const Duration(hours: 18)),
          endTime: day.add(const Duration(hours: 19)),
          color: 0xFF34A853,
        ),
      ];
    }
    if (day.weekday == 5) {
      return [
        Task(
          userId: 'mock',
          title: 'Sunum',
          startTime: day.add(const Duration(hours: 10)),
          endTime: day.add(const Duration(hours: 12)),
          color: 0xFFEA4335,
        ),
      ];
    }
    return [];
  }

  List<Note> _getMockNotes(DateTime day) {
    if (day.weekday == 2) {
      return [
        Note(
          userId: 'mock',
          title: 'Not',
          content: 'Yeni özellikler için notlar',
          date: day,
        ),
      ];
    }
    return [];
  }
}

// ──────────────────────────────────────────────
// 2. TEAM DASHBOARD MOCKUP
// ──────────────────────────────────────────────

class CodeDashboardMockup extends StatelessWidget {
  const CodeDashboardMockup({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Ekip Panosu",
                  style: GoogleFonts.outfit(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              PhobesIconButton(
                icon: Icons.more_horiz_rounded,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildProjectProgressCard(cs),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildMiniStat(
                  Icons.people_rounded, "12", "Üye", Colors.cyanAccent, cs),
              const SizedBox(width: 8),
              _buildMiniStat(
                  Icons.folder_rounded, "8", "Proje", Colors.amberAccent, cs),
            ],
          ),
          const SizedBox(height: 20),
          _buildActivityChart(cs),
        ],
      ),
    );
  }

  Widget _buildProjectProgressCard(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.8),
            cs.primary.withValues(alpha: 0.4)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Genel İlerleme",
                    style: GoogleFonts.outfit(
                        color: Colors.white70, fontSize: 12)),
                Text("%78",
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              value: 0.78,
              strokeWidth: 6,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.tealAccent),
              strokeCap: StrokeCap.round,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
      IconData icon, String value, String label, Color color, ColorScheme cs) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.outfit(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4))),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityChart(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Haftalık Aktivite",
            style:
                GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
                12,
                (i) => Container(
                      width: 14,
                      height: (20 + (i % 4) * 10).toDouble(),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: i == 8 ? 1.0 : 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// 3. FINANCE / BUDGET MOCKUP
// ──────────────────────────────────────────────

class CodeFinanceMockup extends StatelessWidget {
  const CodeFinanceMockup({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: cs.primary.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: cs.primary.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: 5),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Bütçe Özeti",
                  style: GoogleFonts.outfit(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Icon(Icons.account_balance_wallet_rounded, color: cs.primary),
            ],
          ),
          const SizedBox(height: 24),
          _buildFinanceHeroCard(cs),
          const SizedBox(height: 20),
          _buildCategoryLimit(cs, "Market", 0.7, Colors.orangeAccent),
          const SizedBox(height: 12),
          _buildCategoryLimit(cs, "Teknoloji", 0.4, Colors.blueAccent),
          const SizedBox(height: 12),
          _buildCategoryLimit(cs, "Eğlence", 0.9, Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildFinanceHeroCard(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text("Kullanılabilir Bütçe",
              style: GoogleFonts.outfit(
                  fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
          const SizedBox(height: 4),
          Text("₺12.450,00",
              style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: cs.primary)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInSummary(Icons.arrow_upward_rounded, "Gelir", "₺15.000",
                  Colors.greenAccent),
              const SizedBox(width: 24),
              _buildInSummary(Icons.arrow_downward_rounded, "Gider", "₺2.550",
                  Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInSummary(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Row(children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
        Text(value,
            style:
                GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildCategoryLimit(
      ColorScheme cs, String label, double progress, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 13, fontWeight: FontWeight.w500)),
            Text("%${(progress * 100).toInt()}",
                style: GoogleFonts.outfit(
                    fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// 4. AI INTELLIGENCE MOCKUP
// ──────────────────────────────────────────────

class CodeIntelligenceMockup extends StatelessWidget {
  const CodeIntelligenceMockup({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.primary.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: cs.primary),
              const SizedBox(width: 8),
              Text("Phobes Nova",
                  style: GoogleFonts.outfit(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          _buildChatBubble(
              "Nova",
              "Gelecek haftaki takvimin oldukça yoğun görünüyor. Pazartesi sabahı için hazırladığım özeti incelemek ister misin?",
              cs,
              true),
          const SizedBox(height: 12),
          _buildChatBubble(
              "Siz",
              "Evet lütfen, özellikle toplantı çakışmalarına dikkat çek.",
              cs,
              false),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Icon(Icons.insights_rounded, color: Colors.orangeAccent),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(
                        "Verimlilik analizi: Düne göre %15 artış yakaladın!",
                        style: GoogleFonts.outfit(
                            fontSize: 12, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(
      String sender, String text, ColorScheme cs, bool isAi) {
    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isAi
              ? cs.primary.withValues(alpha: 0.1)
              : cs.primary.withValues(alpha: 0.8),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isAi ? 0 : 16),
            bottomRight: Radius.circular(isAi ? 16 : 0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sender,
                style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isAi ? cs.primary : Colors.white70)),
            const SizedBox(height: 4),
            Text(text,
                style: GoogleFonts.outfit(
                    fontSize: 13, color: isAi ? cs.onSurface : Colors.white)),
          ],
        ),
      ),
    );
  }
}
