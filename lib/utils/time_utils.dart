import 'package:intl/intl.dart';
import 'package:phobes/models/task_model.dart';

class TimeUtils {
  /// Checks if a proposed time range overlaps with any existing tasks
  static Task? getOverlappingTask(DateTime start, DateTime end, List<Task> dailyTasks) {
    for (var task in dailyTasks) {
      if (task.isCompleted) continue; // Ignore completed tasks
      
      // Overlap condition: (StartA < EndB) and (EndA > StartB)
      if (start.isBefore(task.endTime) && end.isAfter(task.startTime)) {
        return task;
      }
    }
    return null;
  }

  /// Calculates free time slots for a given day, excluding existing tasks.
  /// Assumes working hours between 08:00 and 23:00.
  static List<String> getFreeSlots(DateTime date, List<Task> tasks) {
    // Only consider incomplete tasks for that specific day
    final dailyTasks = tasks.where((t) => 
      !t.isCompleted &&
      t.startTime.year == date.year &&
      t.startTime.month == date.month &&
      t.startTime.day == date.day
    ).toList();
    
    // Sort tasks by start time
    dailyTasks.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    List<String> freeSlots = [];
    DateTime currentTime = DateTime(date.year, date.month, date.day, 8, 0); // Start at 08:00
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 0); // End at 23:00

    for (var task in dailyTasks) {
      if (task.startTime.isAfter(currentTime) && task.startTime.difference(currentTime).inMinutes >= 30) {
        // We have a free slot of at least 30 minutes
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
      return ["Tamamen dolusunuz"];
    }

    return freeSlots;
  }
}
