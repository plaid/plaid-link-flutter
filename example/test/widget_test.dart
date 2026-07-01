import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plaid_link_flutter_example/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plaid_link_flutter');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          if (methodCall.method == 'getSdkVersion') {
            return '7.0.1';
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
    expect(find.text('SDK: 7.0.1'), findsOneWidget);
  });
}
