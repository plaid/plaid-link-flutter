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

/// Counter used to give every created session a unique id. Native events are
/// tagged with this id so each session instance only receives its own
/// callbacks, even when multiple sessions exist at once.
int _nextSessionId = 0;

/// Shared lifecycle for the non-embedded sessions. Each session owns the
/// callback subscriptions bound to its session id; nothing lives in
/// module-global state, so sessions never cross-deliver each other's events.
abstract class _PlaidSession {
  _PlaidSession._();

  final List<StreamSubscription<Object?>> _subscriptions =
      <StreamSubscription<Object?>>[];
  bool _disposed = false;

  void _bind(StreamSubscription<Object?> subscription) {
    _subscriptions.add(subscription);
  }

  /// Cancels this session's callback subscriptions.
  ///
  /// Called automatically after a terminal `onSuccess`/`onExit`. Call it
  /// yourself to abandon a session that was created but never opened (for
  /// example when the owning widget is disposed), so its callbacks cannot fire
  /// on dead state. Safe to call more than once.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }
}

class PlaidLinkSession extends _PlaidSession {
  PlaidLinkSession._() : super._();

  Future<void> open([bool fullScreen = false]) {
    return PlaidLinkFlutterPlatform.instance.openLinkSession(fullScreen);
  }
}

class PlaidLayerSession extends _PlaidSession {
  PlaidLayerSession._() : super._();

  Future<void> open() {
    return PlaidLinkFlutterPlatform.instance.openLayerSession();
  }

  Future<void> submit(SubmissionData data) {
    return PlaidLinkFlutterPlatform.instance.submitLayerData(data);
  }
}

class PlaidHeadlessSession extends _PlaidSession {
  PlaidHeadlessSession._() : super._();

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

Future<PlaidLinkSession> createPlaidLinkSession(
  LinkTokenConfiguration config,
) async {
  final sessionId = _nextSessionId++;
  final platform = PlaidLinkFlutterPlatform.instance;
  final session = PlaidLinkSession._();

  session._bind(
    platform.onSuccessForSession(sessionId).listen((success) {
      config.onSuccess(success);
      session.dispose();
    }),
  );
  session._bind(
    platform.onExitForSession(sessionId).listen((exit) {
      config.onExit(exit);
      session.dispose();
    }),
  );
  session._bind(platform.onEventForSession(sessionId).listen(config.onEvent));
  final onLoad = config.onLoad;
  if (onLoad != null) {
    session._bind(platform.onLoadForSession(sessionId).listen((_) => onLoad()));
  }

  try {
    await platform.createPlaidLinkSession(config.token, sessionId);
    return session;
  } catch (_) {
    session.dispose();
    rethrow;
  }
}

Future<PlaidLayerSession> createPlaidLayerSession(
  LayerTokenConfiguration config,
) async {
  final sessionId = _nextSessionId++;
  final platform = PlaidLinkFlutterPlatform.instance;
  final session = PlaidLayerSession._();

  session._bind(
    platform.onSuccessForSession(sessionId).listen((success) {
      config.onSuccess(success);
      session.dispose();
    }),
  );
  final onExit = config.onExit;
  session._bind(
    platform.onExitForSession(sessionId).listen((exit) {
      onExit?.call(exit);
      session.dispose();
    }),
  );
  final onEvent = config.onEvent;
  if (onEvent != null) {
    session._bind(platform.onEventForSession(sessionId).listen(onEvent));
  }

  try {
    await platform.createPlaidLayerSession(config.token, sessionId);
    return session;
  } catch (_) {
    session.dispose();
    rethrow;
  }
}

Future<PlaidHeadlessSession> createPlaidHeadlessSession(
  LinkTokenConfiguration config,
) async {
  final sessionId = _nextSessionId++;
  final platform = PlaidLinkFlutterPlatform.instance;
  final session = PlaidHeadlessSession._();

  session._bind(
    platform.onSuccessForSession(sessionId).listen((success) {
      config.onSuccess(success);
      session.dispose();
    }),
  );
  session._bind(
    platform.onExitForSession(sessionId).listen((exit) {
      config.onExit(exit);
      session.dispose();
    }),
  );
  session._bind(platform.onEventForSession(sessionId).listen(config.onEvent));
  final onLoad = config.onLoad;
  if (onLoad != null) {
    session._bind(platform.onLoadForSession(sessionId).listen((_) => onLoad()));
  }

  try {
    await platform.createPlaidHeadlessSession(config.token, sessionId);
    return session;
  } catch (_) {
    session.dispose();
    rethrow;
  }
}

Future<void> syncFinanceKit(FinanceKitConfiguration config) {
  return PlaidLinkFlutterPlatform.instance.syncFinanceKit(config);
}
