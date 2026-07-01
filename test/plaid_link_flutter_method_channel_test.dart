import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaid_link_flutter/plaid_link_flutter.dart';
import 'package:plaid_link_flutter/plaid_link_flutter_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelPlaidLinkFlutter();
  const channel = MethodChannel('plaid_link_flutter');
  const eventChannel = EventChannel('plaid_link_flutter/events');
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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(eventChannel, null);
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

  test('createPlaidLayerSession invokes native method', () async {
    await platform.createPlaidLayerSession('link-sandbox-layer-token');

    expect(calls.single.method, 'createPlaidLayerSession');
    expect(calls.single.arguments, {'token': 'link-sandbox-layer-token'});
  });

  test('openLayerSession invokes native method', () async {
    await platform.openLayerSession();

    expect(calls.single.method, 'openLayerSession');
    expect(calls.single.arguments, isNull);
  });

  test(
    'submitLayerData invokes native method with RN-shaped arguments',
    () async {
      await platform.submitLayerData(
        const SubmissionData(
          phoneNumber: '+15551234567',
          dateOfBirth: '1990-01-31',
          params: {'flow': 'layer'},
        ),
      );

      expect(calls.single.method, 'submitLayerData');
      expect(calls.single.arguments, {
        'phoneNumber': '+15551234567',
        'dateOfBirth': '1990-01-31',
        'params': {'flow': 'layer'},
      });
    },
  );

  test('createPlaidHeadlessSession invokes native method', () async {
    await platform.createPlaidHeadlessSession('link-sandbox-headless-token');

    expect(calls.single.method, 'createPlaidHeadlessSession');
    expect(calls.single.arguments, {'token': 'link-sandbox-headless-token'});
  });

  test('startHeadlessSession invokes native method', () async {
    await platform.startHeadlessSession();

    expect(calls.single.method, 'startHeadlessSession');
    expect(calls.single.arguments, isNull);
  });

  test(
    'syncFinanceKit invokes native method with RN-shaped arguments',
    () async {
      await platform.syncFinanceKit(
        const FinanceKitConfiguration(
          token: 'link-sandbox-token',
          requestAuthorizationIfNeeded: false,
          syncBehavior: FinanceKitSyncBehavior.simulated,
        ),
      );

      expect(calls.single.method, 'syncFinanceKit');
      expect(calls.single.arguments, {
        'token': 'link-sandbox-token',
        'requestAuthorizationIfNeeded': false,
        'syncBehavior': 1,
      });
    },
  );

  test(
    'syncFinanceKit throws FinanceKitException from platform errors',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
            throw PlatformException(
              code: 'INVALID_TOKEN',
              message: 'Invalid token',
            );
          });

      await expectLater(
        platform.syncFinanceKit(
          const FinanceKitConfiguration(token: 'link-sandbox-token'),
        ),
        throwsA(
          isA<FinanceKitException>()
              .having(
                (error) => error.type,
                'type',
                FinanceKitErrorType.invalidToken,
              )
              .having((error) => error.message, 'message', 'Invalid token'),
        ),
      );
    },
  );

  test('embedded streams filter events by viewId', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          eventChannel,
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              events.success({
                'type': 'embeddedSuccess',
                'viewId': 41,
                'payload': successPayload('wrong-view-token'),
              });
              events.success({
                'type': 'embeddedSuccess',
                'viewId': 42,
                'payload': successPayload('public-token'),
              });
              events.success({
                'type': 'embeddedLoad',
                'viewId': 42,
                'payload': <String, Object?>{},
              });
            },
          ),
        );

    await expectLater(
      platform.embeddedSuccessEvents(42),
      emits(
        isA<LinkSuccess>().having(
          (success) => success.publicToken,
          'publicToken',
          'public-token',
        ),
      ),
    );
  });
}

Map<String, Object?> successPayload(String publicToken) {
  return {
    'publicToken': publicToken,
    'metadata': {
      'linkSessionId': 'session-id',
      'institution': {'id': 'ins_1', 'name': 'Plaid Bank'},
      'accounts': <Object?>[],
      'metadataJson': '{}',
    },
  };
}
