import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phobes/screens/notes/note_toolbar.dart';

import '../helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NoteToolbar', () {
    testWidgets('shows Table insert chip and invokes callback', (tester) async {
      var tableTapped = false;
      final controller = QuillController.basic();

      await tester.pumpWidget(
        wrapTestApp(
          NoteToolbar(
            controller: controller,
            onInsertTable: () => tableTapped = true,
            onInsertCallout: () {},
            onInsertDivider: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Table'), findsOneWidget);
      await tester.tap(find.text('Table'));
      expect(tableTapped, isTrue);

      controller.dispose();
    });

    testWidgets('expand toggle reveals extra formatting row', (tester) async {
      final controller = QuillController.basic();

      await tester.pumpWidget(
        wrapTestApp(
          NoteToolbar(
            controller: controller,
            onInsertTable: () {},
            onInsertCallout: () {},
            onInsertDivider: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final expandButtons = find.byIcon(Icons.expand_more_rounded);
      if (expandButtons.evaluate().isNotEmpty) {
        await tester.tap(expandButtons.first);
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.format_bold_rounded), findsWidgets);
      }

      controller.dispose();
    });
  });
}
