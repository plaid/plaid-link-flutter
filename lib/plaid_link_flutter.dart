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

/// How long to keep a session's listeners alive after `onSuccess` while waiting
/// for the terminal `HANDOFF` event. The native SDK sends `HANDOFF` after
/// success and self-tears-down after ~2s if it never arrives; we wait slightly
/// longer to cover the extra native->Dart channel hop, then clean up regardless.
const Duration _handoffTimeout = Duration(seconds: 3);

/// Shared lifecycle for the non-embedded sessions. Each session owns the
/// callback subscriptions bound to its session id; nothing lives in
/// module-global state, so sessions never cross-deliver each other's events.
abstract class _PlaidSession {
  _PlaidSession._();

  final List<StreamSubscription<Object?>> _subscriptions =
      <StreamSubscription<Object?>>[];
  Timer? _handoffTimer;
  bool _disposed = false;

  void _bind(StreamSubscription<Object?> subscription) {
    _subscriptions.add(subscription);
  }

  /// Keeps this session's listeners alive after `onSuccess` so the terminal
  /// `HANDOFF` event (which the native SDK sends *after* success) is still
  /// delivered; the `HANDOFF` handler then tears the session down. Starts a
  /// fallback timer so a session whose `HANDOFF` never arrives still cleans up.
  void _armHandoffTeardown() {
    if (_disposed) {
      return;
    }
    _handoffTimer ??= Timer(_handoffTimeout, dispose);
  }

  /// Cancels this session's callback subscriptions.
  ///
  /// Called automatically after a terminal `onExit`, after the `HANDOFF` event
  /// that follows `onSuccess`, or after the [_handoffTimeout] fallback if that
  /// `HANDOFF` never arrives. Call it yourself to abandon a session that was
  /// created but never opened (for example when the owning widget is disposed),
  /// so its callbacks cannot fire on dead state. Safe to call more than once.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _handoffTimer?.cancel();
    _handoffTimer = null;
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
      // HANDOFF is delivered after onSuccess; keep listening for it (or the
      // fallback timeout) instead of tearing the session down immediately.
      session._armHandoffTeardown();
    }),
  );
  session._bind(
    platform.onExitForSession(sessionId).listen((exit) {
      config.onExit(exit);
      session.dispose();
    }),
  );
  session._bind(
    platform.onEventForSession(sessionId).listen((event) {
      config.onEvent(event);
      if (event.eventName == LinkEventName.handoff) {
        session.dispose();
      }
    }),
  );
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
      // HANDOFF is delivered after onSuccess; keep listening for it (or the
      // fallback timeout) instead of tearing the session down immediately.
      session._armHandoffTeardown();
    }),
  );
  final onExit = config.onExit;
  session._bind(
    platform.onExitForSession(sessionId).listen((exit) {
      onExit?.call(exit);
      session.dispose();
    }),
  );
  // Always observe events (even when the caller passed no onEvent) so the
  // terminal HANDOFF can trigger teardown; forward to the caller when present.
  final onEvent = config.onEvent;
  session._bind(
    platform.onEventForSession(sessionId).listen((event) {
      onEvent?.call(event);
      if (event.eventName == LinkEventName.handoff) {
        session.dispose();
      }
    }),
  );

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
      // HANDOFF is delivered after onSuccess; keep listening for it (or the
      // fallback timeout) instead of tearing the session down immediately.
      session._armHandoffTeardown();
    }),
  );
  session._bind(
    platform.onExitForSession(sessionId).listen((exit) {
      config.onExit(exit);
      session.dispose();
    }),
  );
  session._bind(
    platform.onEventForSession(sessionId).listen((event) {
      config.onEvent(event);
      if (event.eventName == LinkEventName.handoff) {
        session.dispose();
      }
    }),
  );
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
