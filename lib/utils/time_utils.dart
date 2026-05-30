import 'package:intl/intl.dart';
import 'package:phobes/models/task_model.dart';

class TimeUtils {
  /// Checks if a proposed time range overlaps with any existing tasks
  static Task? getOverlappingTask(DateTime start, DateTime end, List<Task> dailyTasks) {
    for (final task in dailyTasks) {
      if (task.isCompleted) continue;

      if (start.isBefore(task.endTime) && end.isAfter(task.startTime)) {
        return task;
      }
    }
    return null;
  }

  /// Calculates free time slots for a given day, excluding existing tasks.
  /// Assumes working hours between 08:00 and 23:00.
  static List<String> getFreeSlots(DateTime date, List<Task> tasks) {

    final dailyTasks = tasks.where((t) =>
      !t.isCompleted &&
      t.startTime.year == date.year &&
      t.startTime.month == date.month &&
      t.startTime.day == date.day,
    ).toList();

    dailyTasks.sort((a, b) => a.startTime.compareTo(b.startTime));

    final List<String> freeSlots = [];
    DateTime currentTime = DateTime(date.year, date.month, date.day, 8);
    final endOfDay = DateTime(date.year, date.month, date.day, 23);

    for (final task in dailyTasks) {
      if (task.startTime.isAfter(currentTime) && task.startTime.difference(currentTime).inMinutes >= 30) {

        freeSlots.add("${DateFormat('HH:mm').format(currentTime)}-${DateFormat('HH:mm').format(task.startTime)}");
      }
      if (task.endTime.isAfter(currentTime)) {
        currentTime = task.endTime;
      }
    }

    if (currentTime.isBefore(endOfDay) && endOfDay.difference(currentTime).inMinutes >= 30) {
      freeSlots.add("${DateFormat('HH:mm').format(currentTime)}-${DateFormat('HH:mm').format(endOfDay)}");
    }

    if (freeSlots.isEmpty) {
      return ['Tamamen dolusunuz'];
    }

    return freeSlots;
  }
}
