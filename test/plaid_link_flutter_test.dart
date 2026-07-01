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

  @override
  Stream<LinkSuccess> get onSuccess => successController.stream;

  @override
  Stream<LinkExit> get onExit => exitController.stream;

  @override
  Stream<LinkEvent> get onEvent => eventController.stream;

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
    createdToken = token;
  }

  @override
  Future<void> openLinkSession(bool fullScreen) async {
    openedFullScreen = fullScreen;
  }

  @override
  Future<void> createPlaidLayerSession(String token) async {
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
    metadata: LinkEventMetadata(
      linkSessionId: 'session-id',
      timestamp: '2026-07-01T00:00:00Z',
      viewName: 'OPEN',
    ),
  );
}
