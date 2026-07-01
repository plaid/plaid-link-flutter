import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:plaid_link_flutter/plaid_link_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getSdkVersion test', (tester) async {
    final version = await PlaidLink.sdkVersion;
    expect(version?.isNotEmpty, true);
  });
}
