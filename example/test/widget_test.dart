import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plaid_link_flutter_example/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plaid_link_flutter');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          if (methodCall.method == 'getSdkVersion') {
            return '7.0.5';
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('shows LinkKit example list', (tester) async {
    await tester.pumpWidget(const LinkKitExampleApp());
    await tester.pump();

    expect(find.text('LinkKit Examples'), findsOneWidget);
    expect(find.text('Plaid Link Session'), findsOneWidget);
    expect(find.text('Plaid Layer Session'), findsOneWidget);
    expect(find.text('Plaid Headless Session'), findsOneWidget);
    expect(find.text('Plaid Embedded Search'), findsOneWidget);
    expect(find.text('Sync FinanceKit'), findsOneWidget);
    expect(find.text('SDK: 7.0.5'), findsOneWidget);
  });

  testWidgets('Layer screen renders expected controls', (tester) async {
    await tester.pumpWidget(const LinkKitExampleApp());
    await tester.pump();
    await tester.tap(find.text('Plaid Layer Session'));
    await tester.pumpAndSettle();

    expect(find.text('Plaid Layer Session Example'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('Date of birth'), findsOneWidget);
    expect(find.text('Params'), findsOneWidget);
    expect(find.text('SUBMIT LAYER DATA'), findsOneWidget);
  });

  testWidgets('Headless screen renders expected controls', (tester) async {
    await tester.pumpWidget(const LinkKitExampleApp());
    await tester.pump();
    await tester.tap(find.text('Plaid Headless Session'));
    await tester.pumpAndSettle();

    expect(find.text('Plaid Headless Session Example'), findsOneWidget);
    expect(find.text('CREATE HEADLESS SESSION'), findsOneWidget);
  });

  testWidgets('Embedded and FinanceKit screens render expected controls', (
    tester,
  ) async {
    await tester.pumpWidget(const LinkKitExampleApp());
    await tester.pump();
    await tester.tap(find.text('Plaid Embedded Search'));
    await tester.pumpAndSettle();

    expect(find.text('Plaid Embedded Search Example'), findsOneWidget);
    expect(find.text('LOAD EMBEDDED SEARCH'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sync FinanceKit'));
    await tester.pumpAndSettle();

    expect(find.text('Sync FinanceKit Example'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);
    expect(find.text('Simulated'), findsOneWidget);
    expect(find.text('SYNC FINANCEKIT'), findsOneWidget);
  });

  testWidgets('ResultSheet close delegates without implicit session work', (
    tester,
  ) async {
    var closeCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResultSheet(
            title: 'Success',
            rows: const [ResultRow('Public token', 'public-sandbox-token')],
            events: const [],
            onClose: () => closeCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Close'));
    await tester.pump();

    expect(closeCount, 1);
  });
}
