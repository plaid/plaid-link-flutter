import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'plaid_link_flutter_method_channel.dart';
import 'src/types.dart';

abstract class PlaidLinkFlutterPlatform extends PlatformInterface {
  PlaidLinkFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static PlaidLinkFlutterPlatform _instance = MethodChannelPlaidLinkFlutter();

  static PlaidLinkFlutterPlatform get instance => _instance;

  static set instance(PlaidLinkFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Stream<LinkSuccess> get onSuccess {
    throw UnimplementedError('onSuccess has not been implemented.');
  }

  Stream<LinkExit> get onExit {
    throw UnimplementedError('onExit has not been implemented.');
  }

  Stream<LinkEvent> get onEvent {
    throw UnimplementedError('onEvent has not been implemented.');
  }

  Stream<void> get onLoad {
    throw UnimplementedError('onLoad has not been implemented.');
  }

  Stream<LinkSuccess> onSuccessForSession(int sessionId) {
    throw UnimplementedError('onSuccessForSession() has not been implemented.');
  }

  Stream<LinkExit> onExitForSession(int sessionId) {
    throw UnimplementedError('onExitForSession() has not been implemented.');
  }

  Stream<LinkEvent> onEventForSession(int sessionId) {
    throw UnimplementedError('onEventForSession() has not been implemented.');
  }

  Stream<void> onLoadForSession(int sessionId) {
    throw UnimplementedError('onLoadForSession() has not been implemented.');
  }

  Stream<LinkSuccess> embeddedSuccessEvents(int viewId) {
    throw UnimplementedError(
      'embeddedSuccessEvents() has not been implemented.',
    );
  }

  Stream<LinkExit> embeddedExitEvents(int viewId) {
    throw UnimplementedError('embeddedExitEvents() has not been implemented.');
  }

  Stream<LinkEvent> embeddedLinkEvents(int viewId) {
    throw UnimplementedError('embeddedLinkEvents() has not been implemented.');
  }

  Stream<void> embeddedLoadEvents(int viewId) {
    throw UnimplementedError('embeddedLoadEvents() has not been implemented.');
  }

  Future<String?> getSdkVersion() {
    throw UnimplementedError('getSdkVersion() has not been implemented.');
  }

  Future<void> createPlaidLinkSession(String token, int sessionId) {
    throw UnimplementedError(
      'createPlaidLinkSession() has not been implemented.',
    );
  }

  Future<void> openLinkSession(bool fullScreen) {
    throw UnimplementedError('openLinkSession() has not been implemented.');
  }

  Future<void> createPlaidLayerSession(String token, int sessionId) {
    throw UnimplementedError(
      'createPlaidLayerSession() has not been implemented.',
    );
  }

  Future<void> openLayerSession() {
    throw UnimplementedError('openLayerSession() has not been implemented.');
  }

  Future<void> submitLayerData(SubmissionData data) {
    throw UnimplementedError('submitLayerData() has not been implemented.');
  }

  Future<void> createPlaidHeadlessSession(String token, int sessionId) {
    throw UnimplementedError(
      'createPlaidHeadlessSession() has not been implemented.',
    );
  }

  Future<void> startHeadlessSession() {
    throw UnimplementedError(
      'startHeadlessSession() has not been implemented.',
    );
  }

  Future<void> syncFinanceKit(FinanceKitConfiguration config) {
    throw UnimplementedError('syncFinanceKit() has not been implemented.');
  }
}
