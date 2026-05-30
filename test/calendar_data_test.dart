import 'package:flutter_test/flutter_test.dart';
import 'package:phobes/screens/calendar/calendar_controller.dart';

void main() {
  group('CalendarData', () {
    test('copyWith replaces only specified lists', () {
      const initial = CalendarData();
      final updated = initial.copyWith(
        tasks: [],
        notes: [],
      );
      expect(updated.tasks, isEmpty);
      expect(updated.notes, isEmpty);
      expect(updated.medications, isEmpty);
    });
  });

  group('isDateInCalendarRange', () {
    final start = DateTime(2026, 5, 10);
    final end = DateTime(2026, 5, 20);

    test('includes boundary days', () {
      expect(isDateInCalendarRange(start, start, end), isTrue);
      expect(isDateInCalendarRange(end, start, end), isTrue);
    });

    test('excludes day before start', () {
      expect(
        isDateInCalendarRange(
          DateTime(2026, 5, 9),
          start,
          end,
        ),
        isFalse,
      );
    });

    test('excludes day after end', () {
      expect(
        isDateInCalendarRange(
          DateTime(2026, 5, 21),
          start,
          end,
        ),
        isFalse,
      );
    });

    test('ignores time-of-day', () {
      expect(
        isDateInCalendarRange(
          DateTime(2026, 5, 15, 23, 59),
          start,
          end,
        ),
        isTrue,
      );
    });
  });
}
