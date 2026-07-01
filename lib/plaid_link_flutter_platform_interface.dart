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

  Future<String?> getSdkVersion() {
    throw UnimplementedError('getSdkVersion() has not been implemented.');
  }

  Future<void> createPlaidLinkSession(String token) {
    throw UnimplementedError(
      'createPlaidLinkSession() has not been implemented.',
    );
  }

  Future<void> openLinkSession(bool fullScreen) {
    throw UnimplementedError('openLinkSession() has not been implemented.');
  }
}
