import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaid_link_flutter/plaid_link_flutter.dart';
import 'package:plaid_link_flutter/plaid_link_flutter_method_channel.dart';
import 'package:plaid_link_flutter/plaid_link_flutter_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakePlaidLinkFlutterPlatform
    with MockPlatformInterfaceMixin
    implements PlaidLinkFlutterPlatform {
  final StreamController<LinkSuccess> successController =
      StreamController<LinkSuccess>.broadcast();
  final StreamController<LinkExit> exitController =
      StreamController<LinkExit>.broadcast();
  final StreamController<LinkEvent> eventController =
      StreamController<LinkEvent>.broadcast();
  final StreamController<void> loadController =
      StreamController<void>.broadcast();
  final Map<int, StreamController<LinkSuccess>> embeddedSuccessControllers =
      <int, StreamController<LinkSuccess>>{};
  final Map<int, StreamController<LinkExit>> embeddedExitControllers =
      <int, StreamController<LinkExit>>{};
  final Map<int, StreamController<LinkEvent>> embeddedEventControllers =
      <int, StreamController<LinkEvent>>{};
  final Map<int, StreamController<void>> embeddedLoadControllers =
      <int, StreamController<void>>{};

  String? createdToken;
  String? createdLayerToken;
  String? createdHeadlessToken;
  bool? openedFullScreen;
  bool openedLayer = false;
  bool startedHeadless = false;
  SubmissionData? submittedData;
  FinanceKitConfiguration? financeKitConfiguration;
  bool failCreateLinkSession = false;
  bool failCreateLayerSession = false;
  bool failCreateHeadlessSession = false;

  @override
  Stream<LinkSuccess> get onSuccess => successController.stream;

  @override
  Stream<LinkExit> get onExit => exitController.stream;

  @override
  Stream<LinkEvent> get onEvent => eventController.stream;

  @override
  Stream<void> get onLoad => loadController.stream;

  @override
  Stream<LinkSuccess> embeddedSuccessEvents(int viewId) {
    return embeddedSuccessControllers
        .putIfAbsent(viewId, () => StreamController<LinkSuccess>.broadcast())
        .stream;
  }

  @override
  Stream<LinkExit> embeddedExitEvents(int viewId) {
    return embeddedExitControllers
        .putIfAbsent(viewId, () => StreamController<LinkExit>.broadcast())
        .stream;
  }

  @override
  Stream<LinkEvent> embeddedLinkEvents(int viewId) {
    return embeddedEventControllers
        .putIfAbsent(viewId, () => StreamController<LinkEvent>.broadcast())
        .stream;
  }

  @override
  Stream<void> embeddedLoadEvents(int viewId) {
    return embeddedLoadControllers
        .putIfAbsent(viewId, () => StreamController<void>.broadcast())
        .stream;
  }

  @override
  Future<String?> getSdkVersion() async => '7.0.1';

  @override
  Future<void> createPlaidLinkSession(String token) async {
    if (failCreateLinkSession) {
      throw PlatformException(code: 'CREATE_FAILED', message: 'create failed');
    }
    createdToken = token;
  }

  @override
  Future<void> openLinkSession(bool fullScreen) async {
    openedFullScreen = fullScreen;
  }

  @override
  Future<void> createPlaidLayerSession(String token) async {
    if (failCreateLayerSession) {
      throw PlatformException(code: 'CREATE_FAILED', message: 'create failed');
    }
    createdLayerToken = token;
  }

  @override
  Future<void> openLayerSession() async {
    openedLayer = true;
  }

  @override
  Future<void> submitLayerData(SubmissionData data) async {
    submittedData = data;
  }

  @override
  Future<void> createPlaidHeadlessSession(String token) async {
    if (failCreateHeadlessSession) {
      throw PlatformException(code: 'CREATE_FAILED', message: 'create failed');
    }
    createdHeadlessToken = token;
  }

  @override
  Future<void> startHeadlessSession() async {
    startedHeadless = true;
  }

  @override
  Future<void> syncFinanceKit(FinanceKitConfiguration config) async {
    financeKitConfiguration = config;
  }

  Future<void> dispose() async {
    await successController.close();
    await exitController.close();
    await eventController.close();
    await loadController.close();
    for (final controller in embeddedSuccessControllers.values) {
      await controller.close();
    }
    for (final controller in embeddedExitControllers.values) {
      await controller.close();
    }
    for (final controller in embeddedEventControllers.values) {
      await controller.close();
    }
    for (final controller in embeddedLoadControllers.values) {
      await controller.close();
    }
  }
}

void main() {
  final initialPlatform = PlaidLinkFlutterPlatform.instance;

  tearDown(() {
    PlaidLinkFlutterPlatform.instance = initialPlatform;
  });

  test('$MethodChannelPlaidLinkFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPlaidLinkFlutter>());
  });

  test('createPlaidLinkSession creates and opens a session', () async {
    final fakePlatform = FakePlaidLinkFlutterPlatform();
    PlaidLinkFlutterPlatform.instance = fakePlatform;

    final session = await createPlaidLinkSession(
      LinkTokenConfiguration(
        token: 'link-sandbox-token',
        onSuccess: (_) {},
        onExit: (_) {},
        onEvent: (_) {},
      ),
    );
    await session.open(true);

    expect(fakePlatform.createdToken, 'link-sandbox-token');
    expect(fakePlatform.openedFullScreen, isTrue);

    await fakePlatform.dispose();
  });

  test('onLoad fires from the load event, not from session creation', () async {
    final fakePlatform = FakePlaidLinkFlutterPlatform();
    PlaidLinkFlutterPlatform.instance = fakePlatform;
    var loadCount = 0;

    await createPlaidLinkSession(
      LinkTokenConfiguration(
        token: 'link-sandbox-token',
        onSuccess: (_) {},
        onExit: (_) {},
        onEvent: (_) {},
        onLoad: () => loadCount++,
      ),
    );

    // Creating the session must not resolve or fire onLoad on its own.
    expect(loadCount, 0);

    fakePlatform.loadController.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(loadCount, 1);

    await fakePlatform.dispose();
  });

  test('createPlaidLayerSession opens and submits layer data', () async {
    final fakePlatform = FakePlaidLinkFlutterPlatform();
    PlaidLinkFlutterPlatform.instance = fakePlatform;

    final session = await createPlaidLayerSession(
      LayerTokenConfiguration(
        token: 'link-sandbox-layer-token',
        onSuccess: (_) {},
      ),
    );
    await session.open();
    await session.submit(
      const SubmissionData(
        phoneNumber: '+15551234567',
        dateOfBirth: '1990-01-31',
        params: {'flow': 'layer'},
      ),
    );

    expect(fakePlatform.createdLayerToken, 'link-sandbox-layer-token');
    expect(fakePlatform.openedLayer, isTrue);
    expect(fakePlatform.submittedData?.phoneNumber, '+15551234567');
    expect(fakePlatform.submittedData?.params, {'flow': 'layer'});

    await fakePlatform.dispose();
  });

  test('createPlaidHeadlessSession creates and starts a session', () async {
    final fakePlatform = FakePlaidLinkFlutterPlatform();
    PlaidLinkFlutterPlatform.instance = fakePlatform;

    final session = await createPlaidHeadlessSession(
      LinkTokenConfiguration(
        token: 'link-sandbox-headless-token',
        onSuccess: (_) {},
        onExit: (_) {},
        onEvent: (_) {},
      ),
    );
    await session.start();

    expect(fakePlatform.createdHeadlessToken, 'link-sandbox-headless-token');
    expect(fakePlatform.startedHeadless, isTrue);

    await fakePlatform.dispose();
  });

  test('success cleans up session listeners for terminal events', () async {
    final fakePlatform = FakePlaidLinkFlutterPlatform();
    PlaidLinkFlutterPlatform.instance = fakePlatform;
    var successCount = 0;
    var eventCount = 0;

    await createPlaidLinkSession(
      LinkTokenConfiguration(
        token: 'link-sandbox-token',
        onSuccess: (_) => successCount++,
        onExit: (_) {},
        onEvent: (_) => eventCount++,
      ),
    );

    fakePlatform.successController.add(sampleSuccess());
    await Future<void>.delayed(Duration.zero);
    fakePlatform.successController.add(sampleSuccess());
    fakePlatform.eventController.add(sampleEvent());
    await Future<void>.delayed(Duration.zero);

    expect(successCount, 1);
    expect(eventCount, 0);

    await fakePlatform.dispose();
  });

  test('create failure cleans up registered listeners', () async {
    final fakePlatform = FakePlaidLinkFlutterPlatform();
    fakePlatform.failCreateLinkSession = true;
    PlaidLinkFlutterPlatform.instance = fakePlatform;
    var successCount = 0;
    var eventCount = 0;

    await expectLater(
      createPlaidLinkSession(
        LinkTokenConfiguration(
          token: 'link-sandbox-token',
          onSuccess: (_) => successCount++,
          onExit: (_) {},
          onEvent: (_) => eventCount++,
        ),
      ),
      throwsA(isA<PlatformException>()),
    );

    fakePlatform.successController.add(sampleSuccess());
    fakePlatform.eventController.add(sampleEvent());
    await Future<void>.delayed(Duration.zero);

    expect(successCount, 0);
    expect(eventCount, 0);

    await fakePlatform.dispose();
  });

  test('layer create failure cleans up registered listeners', () async {
    final fakePlatform = FakePlaidLinkFlutterPlatform();
    fakePlatform.failCreateLayerSession = true;
    PlaidLinkFlutterPlatform.instance = fakePlatform;
    var successCount = 0;

    await expectLater(
      createPlaidLayerSession(
        LayerTokenConfiguration(
          token: 'link-sandbox-layer-token',
          onSuccess: (_) => successCount++,
        ),
      ),
      throwsA(isA<PlatformException>()),
    );

    fakePlatform.successController.add(sampleSuccess());
    await Future<void>.delayed(Duration.zero);

    expect(successCount, 0);

    await fakePlatform.dispose();
  });

  test('headless create failure cleans up registered listeners', () async {
    final fakePlatform = FakePlaidLinkFlutterPlatform();
    fakePlatform.failCreateHeadlessSession = true;
    PlaidLinkFlutterPlatform.instance = fakePlatform;
    var successCount = 0;

    await expectLater(
      createPlaidHeadlessSession(
        LinkTokenConfiguration(
          token: 'link-sandbox-headless-token',
          onSuccess: (_) => successCount++,
          onExit: (_) {},
          onEvent: (_) {},
        ),
      ),
      throwsA(isA<PlatformException>()),
    );

    fakePlatform.successController.add(sampleSuccess());
    await Future<void>.delayed(Duration.zero);

    expect(successCount, 0);

    await fakePlatform.dispose();
  });

  test('creating a new session replaces previous session listeners', () async {
    final fakePlatform = FakePlaidLinkFlutterPlatform();
    PlaidLinkFlutterPlatform.instance = fakePlatform;
    var linkSuccessCount = 0;
    var headlessSuccessCount = 0;

    await createPlaidLinkSession(
      LinkTokenConfiguration(
        token: 'link-sandbox-token',
        onSuccess: (_) => linkSuccessCount++,
        onExit: (_) {},
        onEvent: (_) {},
      ),
    );
    await createPlaidHeadlessSession(
      LinkTokenConfiguration(
        token: 'link-sandbox-headless-token',
        onSuccess: (_) => headlessSuccessCount++,
        onExit: (_) {},
        onEvent: (_) {},
      ),
    );

    fakePlatform.successController.add(sampleSuccess());
    await Future<void>.delayed(Duration.zero);

    expect(linkSuccessCount, 0);
    expect(headlessSuccessCount, 1);

    await fakePlatform.dispose();
  });

  test('syncFinanceKit forwards configuration', () async {
    final fakePlatform = FakePlaidLinkFlutterPlatform();
    PlaidLinkFlutterPlatform.instance = fakePlatform;

    await syncFinanceKit(
      const FinanceKitConfiguration(
        token: 'link-sandbox-token',
        requestAuthorizationIfNeeded: false,
        syncBehavior: FinanceKitSyncBehavior.simulated,
      ),
    );

    expect(fakePlatform.financeKitConfiguration?.token, 'link-sandbox-token');
    expect(
      fakePlatform.financeKitConfiguration?.requestAuthorizationIfNeeded,
      isFalse,
    );
    expect(
      fakePlatform.financeKitConfiguration?.syncBehavior,
      FinanceKitSyncBehavior.simulated,
    );

    await fakePlatform.dispose();
  });

  test('SubmissionData and FinanceKit errors parse expected shapes', () {
    const data = SubmissionData(
      phoneNumber: '+15551234567',
      dateOfBirth: '1990-01-31',
      params: {'foo': 'bar'},
    );
    final exception = FinanceKitException.fromPlatformException(
      PlatformException(code: 'PERMISSION_ERROR', message: 'Denied'),
    );

    expect(data.toMap(), {
      'phoneNumber': '+15551234567',
      'dateOfBirth': '1990-01-31',
      'params': {'foo': 'bar'},
    });
    expect(exception.type, FinanceKitErrorType.permissionError);
    expect(exception.message, 'Denied');
  });

  test('FinanceKitException maps platform-support error codes', () {
    final android = FinanceKitException.fromPlatformException(
      PlatformException(code: 'UNSUPPORTED_ANDROID', message: 'iOS only'),
    );
    final iosVersion = FinanceKitException.fromPlatformException(
      PlatformException(code: 'UNSUPPORTED_IOS_VERSION', message: 'needs 17.4'),
    );

    expect(android.type, FinanceKitErrorType.unsupportedAndroid);
    expect(iosVersion.type, FinanceKitErrorType.unsupportedIosVersion);
  });

  test('PlaidLinkException maps known codes and preserves the raw code', () {
    final typed = PlaidLinkException.fromPlatformException(
      PlatformException(code: 'PLAID_NO_SESSION', message: 'not created'),
    );
    final unknown = PlaidLinkException.fromPlatformException(
      PlatformException(code: 'SOME_NEW_CODE', message: 'future'),
    );

    expect(typed.type, PlaidLinkErrorType.noSession);
    expect(typed.code, 'PLAID_NO_SESSION');
    expect(unknown.type, PlaidLinkErrorType.unknown);
    expect(unknown.code, 'SOME_NEW_CODE');
  });

  test('LinkSuccess parses RN-shaped payloads', () {
    final success = LinkSuccess.fromMap({
      'publicToken': 'public-token',
      'metadata': {
        'linkSessionId': 'session-id',
        'institution': {'id': 'ins_1', 'name': 'Plaid Bank'},
        'accounts': [
          {
            'id': 'account-id',
            'name': 'Checking',
            'mask': '0000',
            'type': 'depository',
            'subtype': 'checking',
            'verificationStatus': '',
          },
        ],
        'metadataJson': '{}',
      },
    });

    expect(success.publicToken, 'public-token');
    expect(success.metadata.institution?.name, 'Plaid Bank');
    expect(success.metadata.accounts.single.subtype, 'checking');
  });

  test('models tolerate missing and malformed optional payload fields', () {
    final success = LinkSuccess.fromMap({
      'publicToken': 'public-token',
      'metadata': {
        'linkSessionId': 'session-id',
        'institution': '',
        'accounts': 'not-a-list',
      },
    });
    final exit = LinkExit.fromMap({
      'error': '',
      'metadata': {'linkSessionId': null, 'requestId': null},
    });
    final event = LinkEvent.fromMap({
      'eventName': 'OPEN',
      'metadata': {
        'linkSessionId': 'session-id',
        'timestamp': null,
        'viewName': null,
      },
    });

    expect(success.metadata.institution, isNull);
    expect(success.metadata.accounts, isEmpty);
    expect(exit.error, isNull);
    expect(exit.metadata.linkSessionId, '');
    expect(exit.metadata.requestId, '');
    expect(event.metadata.timestamp, isNull);
    expect(event.metadata.viewName, '');
  });

  test('event metadata parses typed primitives', () {
    final event = LinkEvent.fromMap({
      'eventName': 'TRANSITION_VIEW',
      'metadata': {
        'linkSessionId': 'session-id',
        'viewName': 'CONNECTED',
        'timestamp': '2026-07-01T00:00:00Z',
        'isUpdateMode': 'true',
        'routingNumber': '110000000',
      },
    });

    expect(event.metadata.isUpdateMode, isTrue);
    expect(event.metadata.routingNumber, '110000000');
    expect(event.metadata.timestamp, DateTime.parse('2026-07-01T00:00:00Z'));
  });
}

LinkSuccess sampleSuccess() {
  return const LinkSuccess(
    publicToken: 'public-token',
    metadata: LinkSuccessMetadata(
      accounts: <LinkAccount>[],
      linkSessionId: 'session-id',
    ),
  );
}

LinkEvent sampleEvent() {
  return const LinkEvent(
    eventName: 'OPEN',
    metadata: LinkEventMetadata(linkSessionId: 'session-id', viewName: 'OPEN'),
  );
}
