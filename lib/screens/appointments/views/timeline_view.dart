import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/appointment_model.dart';

class TimelineView extends StatelessWidget {
  final DateTime selectedDate;
  final List<Appointment> appointments;
  final int startHour;
  final int endHour;
  final Function(Appointment) onAppointmentTap;
  final Function(DateTime) onEmptySlotTap;

  const TimelineView({
    super.key,
    required this.selectedDate,
    required this.appointments,
    this.startHour = 7,
    this.endHour = 21,
    required this.onAppointmentTap,
    required this.onEmptySlotTap,
  });

  int get _effectiveStartHour {
    var minH = startHour;
    for (final a in appointments) {
      if (a.date.hour < minH) minH = a.date.hour;
    }
    return minH.clamp(0, 23);
  }

  int get _effectiveEndHour {
    var maxH = endHour;
    for (final a in appointments) {
      final endH = a.endTime.hour + (a.endTime.minute > 0 ? 1 : 0);
      if (endH > maxH) maxH = endH;
    }
    return maxH.clamp(_effectiveStartHour + 1, 24);
  }

  static bool isSameCalendarDay(DateTime a, DateTime b) {
    final da = DateUtils.dateOnly(a.toLocal());
    final db = DateUtils.dateOnly(b.toLocal());
    return da == db;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hourStart = _effectiveStartHour;
    final hourEnd = _effectiveEndHour;
    final totalHours = hourEnd - hourStart;

    return LayoutBuilder(
      builder: (context, constraints) {
        const double hourHeight = 72.0;
        final double totalHeight = totalHours * hourHeight;

        return SingleChildScrollView(
          primary: false,
          padding: const EdgeInsets.fromLTRB(0, 8, 16, 80),
          child: SizedBox(
            height: totalHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Saat etiketleri
                SizedBox(
                  width: 52,
                  child: Column(
                    children: List.generate(totalHours, (i) {
                      final hour = hourStart + i;
                      return SizedBox(
                        height: hourHeight,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Transform.translate(
                            offset: const Offset(0, -7),
                            child: Text(
                              '${hour.toString().padLeft(2, '0')}:00',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: cs.onSurface.withOpacity(0.35),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // Timeline gövdesi
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Grid çizgileri
                      ...List.generate(totalHours, (i) {
                        return Positioned(
                          top: i * hourHeight,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 0.5,
                            color: cs.onSurface.withOpacity(0.06),
                          ),
                        );
                      }),

                      // Boş slot'lar (tıklanabilir)
                      ...List.generate(totalHours * 2, (i) {
                        final hour = hourStart + (i ~/ 2);
                        final minute = (i % 2) * 30;
                        final slotTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          hour,
                          minute,
                        );
                        final hasAppointment = appointments.any((a) {
                          return slotTime.isAfter(
                                a.date.subtract(const Duration(minutes: 1)),
                              ) &&
                              slotTime.isBefore(a.endTime);
                        });
                        if (hasAppointment) return const SizedBox.shrink();

                        final top = (hour - hourStart) * hourHeight +
                            (minute / 60.0) * hourHeight;
                        return Positioned(
                          top: top,
                          left: 0,
                          right: 0,
                          height: hourHeight / 2,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () => onEmptySlotTap(slotTime),
                            child: const SizedBox.expand(),
                          ),
                        );
                      }),

                      // Randevu kartları
                      ...appointments.map((appt) {
                        return _buildAppointmentBlock(
                          context,
                          appt,
                          hourHeight,
                          hourStart,
                          cs,
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentBlock(
    BuildContext context,
    Appointment appt,
    double hourHeight,
    int hourStart,
    ColorScheme cs,
  ) {
    final top =
        (appt.date.hour - hourStart + appt.date.minute / 60.0) * hourHeight;
    final height = (appt.durationMinutes / 60.0) * hourHeight;
    final color = Color(appt.color);
    final timeStr = DateFormat('HH:mm').format(appt.date);
    final endStr = DateFormat('HH:mm').format(appt.endTime);

    final isCancelled = appt.status == 'cancelled';

    return Positioned(
      top: top.clamp(0, double.infinity),
      left: 4,
      right: 4,
      height: height.clamp(36, double.infinity),
      child: GestureDetector(
        onTap: () => onAppointmentTap(appt),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isCancelled
                  ? [
                      cs.onSurface.withOpacity(0.05),
                      cs.onSurface.withOpacity(0.03),
                    ]
                  : [
                      color.withOpacity(0.18),
                      color.withOpacity(0.08),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                color: isCancelled ? cs.onSurface.withOpacity(0.2) : color,
                width: 3,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      appt.title,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
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
                  ),
                  _buildStatusDot(appt.status, cs),
                ],
              ),
              if (height > 50) ...[
                const SizedBox(height: 2),
                Text(
                  '$timeStr – $endStr • ${appt.clientName}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: isCancelled
                        ? cs.onSurface.withOpacity(0.25)
                        : cs.onSurface.withOpacity(0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (height > 70 && appt.price > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '${appt.price.toStringAsFixed(0)} ${appt.currency}',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDot(String status, ColorScheme cs) {
    Color dotColor;
    switch (status) {
      case 'confirmed':
        dotColor = const Color(0xFF10B981);
        break;
      case 'completed':
        dotColor = cs.onSurface.withOpacity(0.4);
        break;
      case 'cancelled':
        dotColor = cs.error;
        break;
      default:
        dotColor = const Color(0xFFF59E0B);
    }
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
      ),
    );
  }
}
