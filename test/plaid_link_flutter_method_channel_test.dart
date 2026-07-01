import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaid_link_flutter/plaid_link_flutter_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelPlaidLinkFlutter();
  const channel = MethodChannel('plaid_link_flutter');
  final calls = <MethodCall>[];

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          calls.add(methodCall);
          if (methodCall.method == 'getSdkVersion') {
            return '7.0.1';
          }
          return null;
        });
  });

  tearDown(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getSdkVersion', () async {
    expect(await platform.getSdkVersion(), '7.0.1');
  });

  test('createPlaidLinkSession invokes native method', () async {
    await platform.createPlaidLinkSession('link-sandbox-token');

    expect(calls.single.method, 'createPlaidLinkSession');
    expect(calls.single.arguments, {'token': 'link-sandbox-token'});
  });

  test('openLinkSession invokes native method', () async {
    await platform.openLinkSession(true);

    expect(calls.single.method, 'openLinkSession');
    expect(calls.single.arguments, {'fullScreen': true});
  });
}
