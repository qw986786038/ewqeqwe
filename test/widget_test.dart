import 'package:flutter_test/flutter_test.dart';

import 'package:yidivination/main.dart';

void main() {
  testWidgets('App shows login page', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('账号密码登录'), findsOneWidget);
    expect(find.text('登录'), findsOneWidget);
  });
}
