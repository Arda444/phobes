import 'package:flutter_test/flutter_test.dart';
import 'package:phobes/screens/auth/widgets/auth_header.dart';

import '../helpers/test_app.dart';

void main() {
  group('AuthHeader', () {
    testWidgets('login mode shows app title', (tester) async {
      await tester.pumpWidget(
        wrapTestApp(const AuthHeader(isLogin: true)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Phobes'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('register mode shows app title', (tester) async {
      await tester.pumpWidget(
        wrapTestApp(const AuthHeader(isLogin: false)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Phobes'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
    });
  });
}
