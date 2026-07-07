import 'dart:async';

import 'plaid_link_flutter_platform_interface.dart';
import 'src/types.dart';

export 'src/plaid_embedded_search_view.dart';
export 'src/types.dart';

typedef LinkSuccessListener = void Function(LinkSuccess success);
typedef LinkExitListener = void Function(LinkExit exit);
typedef LinkOnEventListener = void Function(LinkEvent event);
typedef LinkOnLoadListener = void Function();

class LinkTokenConfiguration {
  const LinkTokenConfiguration({
    required this.token,
    required this.onSuccess,
    required this.onExit,
    required this.onEvent,
    this.onLoad,
  });

  final String token;
  final LinkSuccessListener onSuccess;
  final LinkExitListener onExit;
  final LinkOnEventListener onEvent;
  final LinkOnLoadListener? onLoad;
}

class LayerTokenConfiguration {
  const LayerTokenConfiguration({
    required this.token,
    required this.onSuccess,
    this.onExit,
    this.onEvent,
  });

  final String token;
  final LinkSuccessListener onSuccess;
  final LinkExitListener? onExit;
  final LinkOnEventListener? onEvent;
}

class EmbeddedLinkTokenConfiguration {
  const EmbeddedLinkTokenConfiguration({
    required this.token,
    required this.onSuccess,
    this.onExit,
    this.onEvent,
  });

  final String token;
  final LinkSuccessListener onSuccess;
  final LinkExitListener? onExit;
  final LinkOnEventListener? onEvent;
}

class PlaidLinkSession {
  PlaidLinkSession._();

  Future<void> open([bool fullScreen = false]) {
    return PlaidLinkFlutterPlatform.instance.openLinkSession(fullScreen);
  }
}

class PlaidLayerSession {
  PlaidLayerSession._();

  Future<void> open() {
    return PlaidLinkFlutterPlatform.instance.openLayerSession();
  }

  Future<void> submit(SubmissionData data) {
    return PlaidLinkFlutterPlatform.instance.submitLayerData(data);
  }
}

class PlaidHeadlessSession {
  PlaidHeadlessSession._();

  Future<void> start() {
    return PlaidLinkFlutterPlatform.instance.startHeadlessSession();
  }
}

class PlaidLink {
  const PlaidLink._();

  static Future<String?> get sdkVersion {
    return PlaidLinkFlutterPlatform.instance.getSdkVersion();
  }

  static Stream<LinkEvent> get onEvent {
    return PlaidLinkFlutterPlatform.instance.onEvent;
  }
}

StreamSubscription<LinkSuccess>? _successSubscription;
StreamSubscription<LinkExit>? _exitSubscription;
StreamSubscription<LinkEvent>? _eventSubscription;

void _cleanupListeners() {
  _successSubscription?.cancel();
  _exitSubscription?.cancel();
  _eventSubscription?.cancel();
  _successSubscription = null;
  _exitSubscription = null;
  _eventSubscription = null;
}

Future<PlaidLinkSession> createPlaidLinkSession(
  LinkTokenConfiguration config,
) async {
  _cleanupListeners();

  _successSubscription = PlaidLinkFlutterPlatform.instance.onSuccess.listen((
    success,
  ) {
    config.onSuccess(success);
    _cleanupListeners();
  });

  _exitSubscription = PlaidLinkFlutterPlatform.instance.onExit.listen((exit) {
    config.onExit(exit);
    _cleanupListeners();
  });

  _eventSubscription = PlaidLinkFlutterPlatform.instance.onEvent.listen(
    config.onEvent,
  );

  try {
    await PlaidLinkFlutterPlatform.instance.createPlaidLinkSession(
      config.token,
    );
    config.onLoad?.call();
    return PlaidLinkSession._();
  } catch (_) {
    _cleanupListeners();
    rethrow;
  }
}

Future<PlaidLayerSession> createPlaidLayerSession(
  LayerTokenConfiguration config,
) async {
  _cleanupListeners();

  _successSubscription = PlaidLinkFlutterPlatform.instance.onSuccess.listen((
    success,
  ) {
    config.onSuccess(success);
    _cleanupListeners();
  });

  _exitSubscription = PlaidLinkFlutterPlatform.instance.onExit.listen((exit) {
    config.onExit?.call(exit);
    _cleanupListeners();
  });

  if (config.onEvent != null) {
    _eventSubscription = PlaidLinkFlutterPlatform.instance.onEvent.listen(
      config.onEvent,
    );
  }

  try {
    await PlaidLinkFlutterPlatform.instance.createPlaidLayerSession(
      config.token,
    );
    return PlaidLayerSession._();
  } catch (_) {
    _cleanupListeners();
    rethrow;
  }
}

Future<PlaidHeadlessSession> createPlaidHeadlessSession(
  LinkTokenConfiguration config,
) async {
  _cleanupListeners();

  _successSubscription = PlaidLinkFlutterPlatform.instance.onSuccess.listen((
    success,
  ) {
    config.onSuccess(success);
    _cleanupListeners();
  });

  _exitSubscription = PlaidLinkFlutterPlatform.instance.onExit.listen((exit) {
    config.onExit(exit);
    _cleanupListeners();
  });

  _eventSubscription = PlaidLinkFlutterPlatform.instance.onEvent.listen(
    config.onEvent,
  );

  try {
    await PlaidLinkFlutterPlatform.instance.createPlaidHeadlessSession(
      config.token,
    );
    config.onLoad?.call();
    return PlaidHeadlessSession._();
  } catch (_) {
    _cleanupListeners();
    rethrow;
  }
}

Future<void> syncFinanceKit(FinanceKitConfiguration config) {
  return PlaidLinkFlutterPlatform.instance.syncFinanceKit(config);
}
