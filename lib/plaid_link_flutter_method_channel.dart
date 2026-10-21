import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'plaid_link_flutter_platform_interface.dart';
import 'src/types.dart';

class MethodChannelPlaidLinkFlutter extends PlaidLinkFlutterPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('plaid_link_flutter');

  @visibleForTesting
  final eventChannel = const EventChannel('plaid_link_flutter/events');

  Stream<Map<Object?, Object?>>? _events;

  /// Restored results (see [onRestoredSuccess]) that arrived while nothing was
  /// listening for them. The native side only flushes a held result once the
  /// event channel has a subscriber, which may be a listener for a different
  /// event kind, so the Dart side keeps the result until a restored-result
  /// listener attaches and replays it to that first listener.
  final List<Map<Object?, Object?>> _unclaimedRestoredResults =
      <Map<Object?, Object?>>[];
  final Map<String, int> _restoredListeners = <String, int>{};

  Stream<Map<Object?, Object?>> get _nativeEvents {
    return _events ??=
        eventChannel.receiveBroadcastStream().map((event) {
          if (event is Map<Object?, Object?>) {
            return event;
          }
          if (event is Map) {
            return event.cast<Object?, Object?>();
          }
          return <Object?, Object?>{};
        }).map(_holdUnclaimedRestoredResult).asBroadcastStream();
  }

  Map<Object?, Object?> _holdUnclaimedRestoredResult(
    Map<Object?, Object?> event,
  ) {
    final type = event['type'];
    if (type is String &&
        _isRestoredType(type) &&
        (_restoredListeners[type] ?? 0) == 0) {
      _unclaimedRestoredResults.add(event);
    }
    return event;
  }

  static bool _isRestoredType(String type) =>
      type == 'restoredSuccess' || type == 'restoredExit';

  @override
  Stream<LinkSuccess> get onSuccess {
    return _nativeEvents
        .where((event) => event['type'] == 'success')
        .map((event) => LinkSuccess.fromMap(event.payload()));
  }

  @override
  Stream<LinkExit> get onExit {
    return _nativeEvents
        .where((event) => event['type'] == 'exit')
        .map((event) => LinkExit.fromMap(event.payload()));
  }

  @override
  Stream<LinkEvent> get onEvent {
    return _nativeEvents
        .where((event) => event['type'] == 'event')
        .map((event) => LinkEvent.fromMap(event.payload()));
  }

  @override
  Stream<void> get onLoad {
    return _nativeEvents.where((event) => event['type'] == 'load').map((_) {});
  }

  @override
  Stream<LinkSuccess> get onRestoredSuccess {
    return _restoredEvents(
      'restoredSuccess',
    ).map((event) => LinkSuccess.fromMap(event.payload()));
  }

  @override
  Stream<LinkExit> get onRestoredExit {
    return _restoredEvents(
      'restoredExit',
    ).map((event) => LinkExit.fromMap(event.payload()));
  }

  /// Live restored results of [type], preceded by any that arrived before this
  /// listener attached. A result is replayed to exactly one listener.
  Stream<Map<Object?, Object?>> _restoredEvents(String type) {
    return Stream<Map<Object?, Object?>>.multi((controller) {
      _restoredListeners[type] = (_restoredListeners[type] ?? 0) + 1;
      final subscription = _nativeEvents
          .where((event) => event['type'] == type)
          .listen(
            controller.add,
            onError: controller.addError,
            onDone: controller.close,
          );
      final unclaimed = _unclaimedRestoredResults
          .where((event) => event['type'] == type)
          .toList();
      _unclaimedRestoredResults.removeWhere((event) => event['type'] == type);
      unclaimed.forEach(controller.add);
      controller.onCancel = () {
        _restoredListeners[type] = (_restoredListeners[type] ?? 1) - 1;
        return subscription.cancel();
      };
    });
  }

  @override
  Stream<LinkSuccess> onSuccessForSession(int sessionId) {
    return _sessionEvents(
      'success',
      sessionId,
    ).map((event) => LinkSuccess.fromMap(event.payload()));
  }

  @override
  Stream<LinkExit> onExitForSession(int sessionId) {
    return _sessionEvents(
      'exit',
      sessionId,
    ).map((event) => LinkExit.fromMap(event.payload()));
  }

  @override
  Stream<LinkEvent> onEventForSession(int sessionId) {
    return _sessionEvents(
      'event',
      sessionId,
    ).map((event) => LinkEvent.fromMap(event.payload()));
  }

  @override
  Stream<void> onLoadForSession(int sessionId) {
    return _sessionEvents('load', sessionId).map((_) {});
  }

  @override
  Stream<LinkSuccess> embeddedSuccessEvents(int viewId) {
    return _embeddedEvents(
      'embeddedSuccess',
      viewId,
    ).map((event) => LinkSuccess.fromMap(event.payload()));
  }

  @override
  Stream<LinkExit> embeddedExitEvents(int viewId) {
    return _embeddedEvents(
      'embeddedExit',
      viewId,
    ).map((event) => LinkExit.fromMap(event.payload()));
  }

  @override
  Stream<LinkEvent> embeddedLinkEvents(int viewId) {
    return _embeddedEvents(
      'embeddedEvent',
      viewId,
    ).map((event) => LinkEvent.fromMap(event.payload()));
  }

  @override
  Stream<void> embeddedLoadEvents(int viewId) {
    return _embeddedEvents('embeddedLoad', viewId).map((_) {});
  }

  @override
  Future<String?> getSdkVersion() {
    return methodChannel.invokeMethod<String>('getSdkVersion');
  }

  @override
  Future<void> createPlaidLinkSession(String token, int sessionId) {
    return _invokeLink<void>('createPlaidLinkSession', {
      'token': token,
      'sessionId': sessionId,
    });
  }

  @override
  Future<void> openLinkSession(bool fullScreen) {
    return _invokeLink<void>('openLinkSession', {'fullScreen': fullScreen});
  }

  @override
  Future<void> createPlaidLayerSession(String token, int sessionId) {
    return _invokeLink<void>('createPlaidLayerSession', {
      'token': token,
      'sessionId': sessionId,
    });
  }

  @override
  Future<void> openLayerSession() {
    return _invokeLink<void>('openLayerSession');
  }

  @override
  Future<void> submitLayerData(SubmissionData data) {
    return _invokeLink<void>('submitLayerData', data.toMap());
  }

  @override
  Future<void> createPlaidHeadlessSession(String token, int sessionId) {
    return _invokeLink<void>('createPlaidHeadlessSession', {
      'token': token,
      'sessionId': sessionId,
    });
  }

  @override
  Future<void> startHeadlessSession() {
    return _invokeLink<void>('startHeadlessSession');
  }

  /// Invokes a Link method, translating native `PlatformException`s into the
  /// typed [PlaidLinkException] so callers get a consistent error contract.
  Future<T?> _invokeLink<T>(String method, [dynamic arguments]) async {
    try {
      return await methodChannel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      throw PlaidLinkException.fromPlatformException(error);
    }
  }

  @override
  Future<void> syncFinanceKit(FinanceKitConfiguration config) async {
    try {
      await methodChannel.invokeMethod<void>('syncFinanceKit', config.toMap());
    } on PlatformException catch (error) {
      throw FinanceKitException.fromPlatformException(error);
    }
  }

  Stream<Map<Object?, Object?>> _sessionEvents(String type, int sessionId) {
    return _nativeEvents.where((event) {
      return event['type'] == type && event['sessionId'] == sessionId;
    });
  }

  Stream<Map<Object?, Object?>> _embeddedEvents(String type, int viewId) {
    return _nativeEvents.where((event) {
      return event['type'] == type && event['viewId'] == viewId;
    });
  }
}

extension _PayloadParsing on Map<Object?, Object?> {
  Map<Object?, Object?> payload() {
    final payload = this['payload'];
    if (payload is Map<Object?, Object?>) {
      return payload;
    }
    if (payload is Map) {
      return payload.cast<Object?, Object?>();
    }
    return <Object?, Object?>{};
  }
}
