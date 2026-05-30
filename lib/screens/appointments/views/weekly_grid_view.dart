import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/appointment_model.dart';
import 'timeline_view.dart';

class WeeklyGridView extends StatelessWidget {
  final DateTime focusedDate;
  final List<Appointment> appointments;
  final Function(Appointment) onAppointmentTap;
  final Function(DateTime) onEmptySlotTap;
  final Function(DateTime) onDayTap;
  final String locale;

  const WeeklyGridView({
    super.key,
    required this.focusedDate,
    required this.appointments,
    required this.onAppointmentTap,
    required this.onEmptySlotTap,
    required this.onDayTap,
    this.locale = 'tr',
  });

  List<DateTime> get _weekDays {
    final monday =
        focusedDate.subtract(Duration(days: focusedDate.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final week = _weekDays;
    final now = DateTime.now();

    return Column(
      children: [
        // Gün başlıkları
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: week.map((day) {
              final isToday = day.year == now.year &&
                  day.month == now.month &&
                  day.day == now.day;
              final isSelected = day.year == focusedDate.year &&
                  day.month == focusedDate.month &&
                  day.day == focusedDate.day;
              final dayAppts = _appointmentsForDay(day);

              return Expanded(
                child: GestureDetector(
                  onTap: () => onDayTap(day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 4,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.primary.withOpacity(0.12)
                          : isToday
                              ? cs.primary.withOpacity(0.05)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: isToday
                          ? Border.all(
                              color: cs.primary.withOpacity(0.3),
                            )
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('E', locale).format(day).toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isToday
                                ? cs.primary
                                : cs.onSurface.withOpacity(0.4),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          day.day.toString(),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? cs.primary
                                : isToday
                                    ? cs.primary
                                    : cs.onSurface,
                          ),
                        ),
                        if (isToday && !isSelected) ...[
                          const SizedBox(height: 3),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                        if (dayAppts.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: dayAppts.take(3).map((a) {
                              return Container(
                                width: 5,
                                height: 5,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  color: Color(a.color),
                                  shape: BoxShape.circle,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        Divider(color: cs.onSurface.withOpacity(0.06), height: 16),

        // Seçili günün randevuları
        Expanded(
          child: _buildDayAppointments(context, cs),
        ),
      ],
    );
  }

  List<Appointment> _appointmentsForDay(DateTime day) {
    return appointments
        .where((a) => TimelineView.isSameCalendarDay(a.date, day))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Widget _buildDayAppointments(BuildContext context, ColorScheme cs) {
    final dayAppts = _appointmentsForDay(focusedDate);

    if (dayAppts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 48,
              color: cs.onSurface.withOpacity(0.12),
            ),
            const SizedBox(height: 12),
            Text(
              DateFormat('d MMMM EEEE', locale).format(focusedDate),
              style: GoogleFonts.outfit(
                color: cs.onSurface.withOpacity(0.3),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: dayAppts.length,
      itemBuilder: (context, index) {
        final appt = dayAppts[index];
        return _WeeklyAppointmentCard(
          appointment: appt,
          onTap: () => onAppointmentTap(appt),
        );
      },
    );
  }
}

class _WeeklyAppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onTap;

  const _WeeklyAppointmentCard({
    required this.appointment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = Color(appointment.color);
    final timeStr = DateFormat('HH:mm').format(appointment.date);
    final endStr = DateFormat('HH:mm').format(appointment.endTime);
    final isCancelled = appointment.status == 'cancelled';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(isCancelled ? 0.03 : 0.08),
                  color.withOpacity(isCancelled ? 0.01 : 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withOpacity(isCancelled ? 0.08 : 0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCancelled ? cs.onSurface.withOpacity(0.15) : color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.title,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isCancelled
                              ? cs.onSurface.withOpacity(0.35)
                              : cs.onSurface,
                          decoration:
                              isCancelled ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: cs.onSurface.withOpacity(0.35),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$timeStr – $endStr',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: cs.onSurface.withOpacity(0.4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.person_outline_rounded,
                            size: 13,
                            color: cs.onSurface.withOpacity(0.35),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              appointment.clientName,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: cs.onSurface.withOpacity(0.4),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (appointment.price > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${appointment.price.toStringAsFixed(0)} ${appointment.currency}',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
