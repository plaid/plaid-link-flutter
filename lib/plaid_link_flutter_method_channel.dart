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
        }).asBroadcastStream();
  }

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
  Future<void> createPlaidLinkSession(String token) {
    return _invokeLink<void>('createPlaidLinkSession', {'token': token});
  }

  @override
  Future<void> openLinkSession(bool fullScreen) {
    return _invokeLink<void>('openLinkSession', {'fullScreen': fullScreen});
  }

  @override
  Future<void> createPlaidLayerSession(String token) {
    return _invokeLink<void>('createPlaidLayerSession', {'token': token});
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
  Future<void> createPlaidHeadlessSession(String token) {
    return _invokeLink<void>('createPlaidHeadlessSession', {'token': token});
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
