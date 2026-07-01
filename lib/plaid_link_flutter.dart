import 'dart:async';

import 'plaid_link_flutter_platform_interface.dart';
import 'src/types.dart';

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

class PlaidLinkSession {
  PlaidLinkSession._();

  Future<void> open([bool fullScreen = false]) {
    return PlaidLinkFlutterPlatform.instance.openLinkSession(fullScreen);
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

  await PlaidLinkFlutterPlatform.instance.createPlaidLinkSession(config.token);
  config.onLoad?.call();
  return PlaidLinkSession._();
}
