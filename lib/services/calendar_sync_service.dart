import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/task_model.dart';

class CalendarSyncService {
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

  Future<List<Task>> fetchDeviceEvents() async {
    List<Task> externalTasks = [];
    try {
      var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
        permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
        if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
          return [];
        }
      }

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (!calendarsResult.isSuccess || calendarsResult.data == null) return [];

      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 365));
      final endDate = now.add(const Duration(days: 365));

      for (var calendar in calendarsResult.data!) {
        if (calendar.isReadOnly == true) continue;

        final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
          calendar.id,
          RetrieveEventsParams(startDate: startDate, endDate: endDate),
        );

        if (eventsResult.isSuccess && eventsResult.data != null) {
          for (var event in eventsResult.data!) {
            bool isMarkedDone = event.title != null &&
                (event.title!.startsWith("✓") ||
                    event.title!.contains("[BİTTİ]"));

            String displayTitle = event.title ?? "İsimsiz";
            if (displayTitle.startsWith("✓ ")) {
              displayTitle = displayTitle.substring(2);
            }

            externalTasks.add(Task(
              id: event.eventId,
              userId: "device",
              groupId:
                  calendar.id, // Takvim ID'sini 'groupId' alanında saklıyoruz
              title: displayTitle,
              description: event.description ?? "",
              startTime: event.start ?? now,
              endTime: event.end ?? now.add(const Duration(hours: 1)),
              isAllDay: event.allDay ?? false,
              color: 0xFF9E9E9E,
              tags: [calendar.name ?? "Dış Takvim"],
              status: isMarkedDone ? 'done' : 'todo',
              isCompleted: isMarkedDone,
              priority: 1,
            ));
          }
        }
      }
      return externalTasks;
    } catch (e) {
      debugPrint("Takvim okuma hatası: $e");
      return [];
    }
  }

  Future<bool> updateDeviceEvent(Task task) async {
    try {
      final String calendarId = task.groupId ?? "";
      final String eventId = task.id ?? "";

      if (calendarId.isEmpty || eventId.isEmpty) return false;

      final now = DateTime.now();
      final existingEvents = await _deviceCalendarPlugin.retrieveEvents(
          calendarId,
          RetrieveEventsParams(
              eventIds: [eventId],
              startDate: now.subtract(const Duration(days: 365)),
              endDate: now.add(const Duration(days: 365))));

      if (!existingEvents.isSuccess ||
          existingEvents.data == null ||
          existingEvents.data!.isEmpty) {
        debugPrint("Etkinlik cihazda bulunamadı (ID: $eventId)");
        return false;
      }

      Event eventToUpdate = existingEvents.data!.first;

      eventToUpdate.description = task.description;
      eventToUpdate.allDay = task.isAllDay;

      try {
        eventToUpdate.start = tz.TZDateTime.from(task.startTime, tz.local);
        eventToUpdate.end = tz.TZDateTime.from(task.endTime, tz.local);
      } catch (e) {
        eventToUpdate.start = tz.TZDateTime.from(task.startTime, tz.local);
        eventToUpdate.end = tz.TZDateTime.from(task.endTime, tz.local);
      }

      String rawTitle = task.title;


      if (task.isCompleted) {
        if (!rawTitle.startsWith("✓ ")) {
          eventToUpdate.title = "✓ $rawTitle";
        } else {
          eventToUpdate.title = rawTitle;
        }
      } else {
        if (rawTitle.startsWith("✓ ")) {
          eventToUpdate.title = rawTitle.substring(2);
        } else {
          eventToUpdate.title = rawTitle;
        }
      }

      final result =
          await _deviceCalendarPlugin.createOrUpdateEvent(eventToUpdate);
      return result?.isSuccess ?? false;
    } catch (e) {
      debugPrint("Güncelleme hatası: $e");
      return false;
    }
  }

  Future<bool> deleteDeviceEvent(String calendarId, String eventId) async {
    try {
      final result =
          await _deviceCalendarPlugin.deleteEvent(calendarId, eventId);
      return result.isSuccess;
    } catch (e) {
      debugPrint("Silme hatası: $e");
      return false;
    }
  }
}
