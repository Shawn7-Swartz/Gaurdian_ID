import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_id/main.dart';

void main() {
  testWidgets('Splash opens wallet; Major / Minor UI toggles', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GuardianWalletApp(cameras: []));
    await tester.pumpAndSettle();

    expect(find.textContaining('Week 6'), findsOneWidget);
    expect(find.text('Enter wallet (Major)'), findsOneWidget);

    await tester.tap(find.text('Enter wallet (Major)'));
    await tester.pumpAndSettle();

    expect(find.text('Full Wallet Access'), findsOneWidget);
    expect(find.text('Restricted Wallet'), findsNothing);

    await tester.tap(find.text('Minor'));
    await tester.pumpAndSettle();

    expect(find.text('Restricted Wallet'), findsOneWidget);
  });

  testWidgets('Liveness screen opens from wallet', (WidgetTester tester) async {
    await tester.pumpWidget(const GuardianWalletApp(cameras: []));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enter wallet (Major)'));
    await tester.pumpAndSettle();

    expect(find.text('Liveness'), findsOneWidget);

    await tester.tap(find.text('Liveness'));
    await tester.pumpAndSettle();

    expect(find.text('Liveness Check'), findsOneWidget);
    expect(find.text('Start Liveness'), findsOneWidget);
  });

  testWidgets('Transaction and parent approval screens open', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GuardianWalletApp(cameras: []));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enter wallet (Major)'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Minor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pay'));
    await tester.pumpAndSettle();
    expect(find.text('Minor Transaction'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Major'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Approvals'));
    await tester.pumpAndSettle();
    expect(find.text('Parent Approvals'), findsOneWidget);
  });
}
