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
  Future<String?> getSdkVersion() {
    return methodChannel.invokeMethod<String>('getSdkVersion');
  }

  @override
  Future<void> createPlaidLinkSession(String token) {
    return methodChannel.invokeMethod<void>('createPlaidLinkSession', {
      'token': token,
    });
  }

  @override
  Future<void> openLinkSession(bool fullScreen) {
    return methodChannel.invokeMethod<void>('openLinkSession', {
      'fullScreen': fullScreen,
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
