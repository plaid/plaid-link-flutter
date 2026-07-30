import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaid_link_flutter/plaid_link_flutter.dart';
import 'package:plaid_link_flutter/plaid_link_flutter_platform_interface.dart';

import 'package:plaid_link_flutter_example/main.dart';

class FakePlaidLinkFlutterPlatform extends PlaidLinkFlutterPlatform {
  final StreamController<(int, LinkSuccess)> _successController =
      StreamController<(int, LinkSuccess)>.broadcast();
  final StreamController<(int, LinkExit)> _exitController =
      StreamController<(int, LinkExit)>.broadcast();
  final StreamController<(int, LinkEvent)> _eventController =
      StreamController<(int, LinkEvent)>.broadcast();
  final StreamController<int> _loadController =
      StreamController<int>.broadcast();

  int? lastSessionId;
  int? lastLayerSessionId;
  int? lastHeadlessSessionId;
  bool failCreation = false;
  bool? openedFullScreen;
  bool openedLayerSession = false;
  bool startedHeadlessSession = false;

  @override
  Future<String?> getSdkVersion() async => '7.0.5';

  @override
  Stream<LinkSuccess> onSuccessForSession(int sessionId) => _successController
      .stream
      .where((event) => event.$1 == sessionId)
      .map((event) => event.$2);

  @override
  Stream<LinkExit> onExitForSession(int sessionId) => _exitController.stream
      .where((event) => event.$1 == sessionId)
      .map((event) => event.$2);

  @override
  Stream<LinkEvent> onEventForSession(int sessionId) => _eventController.stream
      .where((event) => event.$1 == sessionId)
      .map((event) => event.$2);

  @override
  Stream<void> onLoadForSession(int sessionId) =>
      _loadController.stream.where((id) => id == sessionId).map((_) {});

  @override
  Future<void> createPlaidLinkSession(String token, int sessionId) async {
    lastSessionId = sessionId;
    if (failCreation) {
      throw PlatformException(
        code: 'CREATE_FAILED',
        message: 'Failed to create session',
      );
    }
  }

  @override
  Future<void> openLinkSession(bool fullScreen) async {
    openedFullScreen = fullScreen;
  }

  @override
  Future<void> createPlaidLayerSession(String token, int sessionId) async {
    lastLayerSessionId = sessionId;
  }

  @override
  Future<void> openLayerSession() async {
    openedLayerSession = true;
  }

  @override
  Future<void> createPlaidHeadlessSession(String token, int sessionId) async {
    lastHeadlessSessionId = sessionId;
  }

  @override
  Future<void> startHeadlessSession() async {
    startedHeadlessSession = true;
  }

  void emitLoad() => _loadController.add(lastSessionId!);

  void emitLayerEvent(LinkEventName eventName) {
    _eventController.add((
      lastLayerSessionId!,
      LinkEvent(
        eventName: eventName,
        metadata: const LinkEventMetadata(
          linkSessionId: 'layer-session-id',
          viewName: LinkViewName.connected,
        ),
      ),
    ));
  }

  void emitHeadlessLoad() => _loadController.add(lastHeadlessSessionId!);

  Future<void> dispose() async {
    await _successController.close();
    await _exitController.close();
    await _eventController.close();
    await _loadController.close();
  }
}

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

  testWidgets('Link session waits for onLoad before enabling open', (
    tester,
  ) async {
    final initialPlatform = PlaidLinkFlutterPlatform.instance;
    final fakePlatform = FakePlaidLinkFlutterPlatform();
    PlaidLinkFlutterPlatform.instance = fakePlatform;
    addTearDown(() async {
      PlaidLinkFlutterPlatform.instance = initialPlatform;
      await fakePlatform.dispose();
    });

    await tester.pumpWidget(const MaterialApp(home: PlaidLinkSessionScreen()));
    await tester.pump();

    final button = find.widgetWithText(FilledButton, 'CREATE LINK SESSION');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    await tester.enterText(
      find.byType(TextField),
      'link-sandbox-example-token',
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);

    await tester.tap(button);
    await tester.pump();

    expect(find.text('INITIALIZING...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'INITIALIZING...'),
          )
          .onPressed,
      isNull,
    );

    await tester.pump();
    expect(find.text('INITIALIZING...'), findsOneWidget);

    fakePlatform.emitLoad();
    await tester.pump();

    final openButton = find.widgetWithText(
      FilledButton,
      'CONNECT BANK ACCOUNT',
    );
    expect(openButton, findsOneWidget);
    expect(tester.widget<FilledButton>(openButton).onPressed, isNotNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(openButton);
    await tester.pump();
    expect(fakePlatform.openedFullScreen, isFalse);
  });

  testWidgets('Link session creation failure restores the create action', (
    tester,
  ) async {
    final initialPlatform = PlaidLinkFlutterPlatform.instance;
    final fakePlatform = FakePlaidLinkFlutterPlatform()..failCreation = true;
    PlaidLinkFlutterPlatform.instance = fakePlatform;
    addTearDown(() async {
      PlaidLinkFlutterPlatform.instance = initialPlatform;
      await fakePlatform.dispose();
    });

    await tester.pumpWidget(const MaterialApp(home: PlaidLinkSessionScreen()));
    await tester.enterText(
      find.byType(TextField),
      'link-sandbox-example-token',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'CREATE LINK SESSION'));
    await tester.pump();

    expect(find.textContaining('Failed to create session'), findsOneWidget);
    final retryButton = find.widgetWithText(
      FilledButton,
      'CREATE LINK SESSION',
    );
    expect(retryButton, findsOneWidget);
    expect(tester.widget<FilledButton>(retryButton).onPressed, isNotNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
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

  testWidgets('Layer session waits for LAYER_READY before enabling open', (
    tester,
  ) async {
    final initialPlatform = PlaidLinkFlutterPlatform.instance;
    final fakePlatform = FakePlaidLinkFlutterPlatform();
    PlaidLinkFlutterPlatform.instance = fakePlatform;
    addTearDown(() async {
      PlaidLinkFlutterPlatform.instance = initialPlatform;
      await fakePlatform.dispose();
    });

    await tester.pumpWidget(const MaterialApp(home: PlaidLayerSessionScreen()));

    final createButton = find.widgetWithText(
      FilledButton,
      'CREATE LAYER SESSION',
    );
    await tester.enterText(
      find.byType(TextField).first,
      'link-sandbox-layer-token',
    );
    await tester.pump();
    await tester.tap(createButton);
    await tester.pump();

    final disabledOpenButton = find.widgetWithText(
      FilledButton,
      'OPEN LAYER SESSION',
    );
    expect(disabledOpenButton, findsOneWidget);
    expect(tester.widget<FilledButton>(disabledOpenButton).onPressed, isNull);
    expect(find.text('INITIALIZING...'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    final submitButton = find.widgetWithText(
      OutlinedButton,
      'SUBMIT LAYER DATA',
    );
    expect(tester.widget<OutlinedButton>(submitButton).onPressed, isNotNull);

    fakePlatform.emitLayerEvent(LinkEventName.open);
    await tester.pump();
    expect(tester.widget<FilledButton>(disabledOpenButton).onPressed, isNull);

    fakePlatform.emitLayerEvent(LinkEventName.layerReady);
    await tester.pump();

    final openButton = find.widgetWithText(FilledButton, 'OPEN LAYER SESSION');
    expect(openButton, findsOneWidget);
    expect(tester.widget<FilledButton>(openButton).onPressed, isNotNull);

    await tester.tap(openButton);
    await tester.pump();
    expect(fakePlatform.openedLayerSession, isTrue);
  });

  testWidgets('Headless screen renders expected controls', (tester) async {
    await tester.pumpWidget(const LinkKitExampleApp());
    await tester.pump();
    await tester.tap(find.text('Plaid Headless Session'));
    await tester.pumpAndSettle();

    expect(find.text('Plaid Headless Session Example'), findsOneWidget);
    expect(find.text('CREATE HEADLESS SESSION'), findsOneWidget);
  });

  testWidgets('Headless session waits for onLoad before enabling start', (
    tester,
  ) async {
    final initialPlatform = PlaidLinkFlutterPlatform.instance;
    final fakePlatform = FakePlaidLinkFlutterPlatform();
    PlaidLinkFlutterPlatform.instance = fakePlatform;
    addTearDown(() async {
      PlaidLinkFlutterPlatform.instance = initialPlatform;
      await fakePlatform.dispose();
    });

    await tester.pumpWidget(
      const MaterialApp(home: PlaidHeadlessSessionScreen()),
    );

    final createButton = find.widgetWithText(
      FilledButton,
      'CREATE HEADLESS SESSION',
    );
    expect(tester.widget<FilledButton>(createButton).onPressed, isNull);

    await tester.enterText(
      find.byType(TextField),
      'link-sandbox-headless-token',
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(createButton).onPressed, isNotNull);

    await tester.tap(createButton);
    await tester.pump();

    final loadingButton = find.widgetWithText(FilledButton, 'INITIALIZING...');
    expect(loadingButton, findsOneWidget);
    expect(tester.widget<FilledButton>(loadingButton).onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump();
    expect(find.text('INITIALIZING...'), findsOneWidget);

    fakePlatform.emitHeadlessLoad();
    await tester.pump();

    final startButton = find.widgetWithText(
      FilledButton,
      'START HEADLESS SESSION',
    );
    expect(startButton, findsOneWidget);
    expect(tester.widget<FilledButton>(startButton).onPressed, isNotNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(startButton);
    await tester.pump();
    expect(fakePlatform.startedHeadlessSession, isTrue);
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
