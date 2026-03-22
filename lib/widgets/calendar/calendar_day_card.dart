import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../core/phobes_theme.dart';
import '../../models/appointment_model.dart';
import '../../models/task_model.dart';
import '../../models/note_model.dart';

class CalendarDayCard extends StatelessWidget {
  final DateTime day;
  final List<dynamic> events;
  final List<Note> notes;
  final bool isSelected;
  final VoidCallback onTap;
  final Duration? animationDelay;

  const CalendarDayCard({
    super.key,
    required this.day,
    required this.events,
    required this.notes,
    required this.onTap,
    this.isSelected = false,
    this.animationDelay,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(day, DateTime.now());
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final taskCount = events.length;

    return Expanded(
      child: FadeInUp(
        duration: PhobesTheme.animNormal,
        delay: animationDelay ?? Duration.zero,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: isToday
                  ? PhobesTheme.todayGradient
                  : PhobesTheme.cardGradient(isDark),
              borderRadius: BorderRadius.circular(PhobesTheme.borderRadiusL),
              border: Border.all(
                color: isToday
                    ? Colors.orangeAccent.withValues(alpha: 0.6)
                    : (isSelected
                        ? cs.primary
                        : cs.outline.withValues(alpha: isDark ? 0.15 : 0.1)),
                width: isSelected || isToday ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.25),
                        blurRadius: 15,
                        spreadRadius: -2,
                      )
                    ]
                  : PhobesTheme.getCardShadow(isDark),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(PhobesTheme.borderRadiusL),
              child: Stack(
                children: [
                  if (!isToday && taskCount > 0)
                    Positioned(
                      top: -10,
                      right: -10,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              (taskCount > 3 ? Colors.orange : cs.primary)
                                  .withValues(alpha: isDark ? 0.2 : 0.3),
                              (taskCount > 3 ? Colors.orange : cs.primary)
                                  .withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat(
                                      'EEE',
                                      Localizations.localeOf(context)
                                          .toString())
                                  .format(day)
                                  .toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isToday
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : cs.onSurface.withValues(alpha: 0.4),
                                letterSpacing: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: isToday
                                  ? BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                    )
                                  : null,
                              alignment: Alignment.center,
                              child: Text(
                                '${day.day}',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isToday ? Colors.white : cs.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final screenWidth =
                                      MediaQuery.of(context).size.width;
                                  final scale = screenWidth > 1200
                                      ? 1.4
                                      : (screenWidth > 800 ? 1.2 : 1.0);

                                  final double chipHeight = 22.0 * scale;
                                  int maxRows =
                                      (constraints.maxHeight / chipHeight)
                                          .floor();
                                  if (maxRows < 1) maxRows = 1;

                                  int itemsPerRow =
                                      constraints.maxWidth > (150 * scale)
                                          ? 2
                                          : 1;
                                  int maxItems = maxRows * itemsPerRow;

                                  int displayCount = events.length;
                                  int remainingCount = 0;

                                  int itemsToRender = events.length +
                                      (notes.isNotEmpty ? 1 : 0);

                                  if (itemsToRender > maxItems) {
                                    int availableRows = maxRows -
                                        1; // 1 row for +X at the bottom
                                    if (availableRows < 0) availableRows = 0;

                                    int availableForEvents =
                                        (availableRows * itemsPerRow) -
                                            (notes.isNotEmpty ? 1 : 0);
                                    if (availableForEvents < 0) {
                                      availableForEvents = 0;
                                    }
                                    displayCount = availableForEvents;
                                    remainingCount =
                                        events.length - displayCount;
                                  }

                                  final double safeWidth = itemsPerRow == 2
                                      ? (constraints.maxWidth - (6 * scale)) / 2
                                      : constraints.maxWidth;

                                  return Column(
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Wrap(
                                        spacing: 4 * scale,
                                        runSpacing: 0,
                                        children: [
                                          ...events.take(displayCount).map(
                                              (e) => SizedBox(
                                                  width: safeWidth,
                                                  child: _buildUnifiedChip(
                                                      context,
                                                      e,
                                                      isDark,
                                                      isToday))),
                                          if (notes.isNotEmpty &&
                                              itemsPerRow * maxRows > 1)
                                            SizedBox(
                                                width: safeWidth,
                                                child: _buildNoteIndicator(
                                                    context,
                                                    notes.length,
                                                    isDark,
                                                    isToday)),
                                        ],
                                      ),
                                      const Spacer(),
                                      if (remainingCount > 0)
                                        Padding(
                                          padding: EdgeInsets.only(
                                              bottom: 2 * scale),
                                          child: Text(
                                            '+$remainingCount',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.outfit(
                                              fontSize: 10 * scale,
                                              fontWeight: FontWeight.bold,
                                              color: isToday
                                                  ? Colors.white
                                                      .withValues(alpha: 0.9)
                                                  : cs.onSurface
                                                      .withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnifiedChip(
      BuildContext context, dynamic e, bool isDark, bool isToday) {
    String title = "";
    Color color = Colors.grey;
    bool isCompleted = false;

    if (e is Task) {
      title = e.title;
      color = Color(e.color);
      isCompleted = e.isCompleted;
    } else if (e is Appointment) {
      title = e.title;
      color = Colors.purpleAccent;
      isCompleted = e.status == 'completed';
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth > 1200 ? 1.4 : (screenWidth > 800 ? 1.2 : 1.0);

    return Container(
      margin: EdgeInsets.only(top: 2 * scale),
      padding: EdgeInsets.symmetric(horizontal: 3 * scale, vertical: 2 * scale),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: isToday
            ? Colors.white.withValues(alpha: 0.25)
            : (isCompleted
                ? color.withValues(alpha: 0.1)
                : color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(4 * scale),
        border: !isCompleted
            ? Border.all(
                color: isToday
                    ? Colors.white.withValues(alpha: 0.5)
                    : color.withValues(alpha: 0.3),
                width: 0.5)
            : null,
      ),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 8 * scale,
          fontWeight: isCompleted ? FontWeight.normal : FontWeight.w600,
          color: isToday
              ? Colors.white
              : (isCompleted
                  ? (isDark ? Colors.white24 : Colors.black26)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.black87)),
          decoration: isCompleted ? TextDecoration.lineThrough : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildNoteIndicator(
      BuildContext context, int count, bool isDark, bool isToday) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth > 1200 ? 1.4 : (screenWidth > 800 ? 1.2 : 1.0);

    return Container(
      margin: EdgeInsets.only(top: 2 * scale),
      padding: EdgeInsets.symmetric(horizontal: 3 * scale, vertical: 2 * scale),
      decoration: BoxDecoration(
        color: isToday
            ? Colors.white.withValues(alpha: 0.25)
            : Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4 * scale),
      ),
      child: Text(
        count > 1 ? '$count Not' : 'Not',
        style: GoogleFonts.outfit(
          fontSize: 8 * scale,
          fontWeight: FontWeight.bold,
          color: isToday ? Colors.white : Colors.amber,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}
