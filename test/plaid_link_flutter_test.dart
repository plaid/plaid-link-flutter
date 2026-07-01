import 'dart:async';

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

  String? createdToken;
  bool? openedFullScreen;

  @override
  Stream<LinkSuccess> get onSuccess => successController.stream;

  @override
  Stream<LinkExit> get onExit => exitController.stream;

  @override
  Stream<LinkEvent> get onEvent => eventController.stream;

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

  Future<void> dispose() async {
    await successController.close();
    await exitController.close();
    await eventController.close();
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
