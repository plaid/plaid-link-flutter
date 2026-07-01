import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../plaid_link_flutter_platform_interface.dart';
import 'types.dart';

class PlaidEmbeddedSearchView extends StatefulWidget {
  const PlaidEmbeddedSearchView({
    required this.token,
    this.onSuccess,
    this.onExit,
    this.onEvent,
    this.onLoad,
    super.key,
  });

  final String token;
  final void Function(LinkSuccess success)? onSuccess;
  final void Function(LinkExit exit)? onExit;
  final void Function(LinkEvent event)? onEvent;
  final VoidCallback? onLoad;

  @override
  State<PlaidEmbeddedSearchView> createState() =>
      _PlaidEmbeddedSearchViewState();
}

class _PlaidEmbeddedSearchViewState extends State<PlaidEmbeddedSearchView> {
  final List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const viewType = 'plaid_link_flutter/embedded_search';
    final creationParams = <String, Object?>{'token': widget.token};

    if (kIsWeb) {
      return const SizedBox.shrink();
    }

    if (Platform.isIOS) {
      return UiKitView(
        viewType: viewType,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }

    if (Platform.isAndroid) {
      return AndroidView(
        viewType: viewType,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }

    return const SizedBox.shrink();
  }

  void _onPlatformViewCreated(int viewId) {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions
      ..clear()
      ..add(
        PlaidLinkFlutterPlatform.instance
            .embeddedSuccessEvents(viewId)
            .listen(widget.onSuccess),
      )
      ..add(
        PlaidLinkFlutterPlatform.instance
            .embeddedExitEvents(viewId)
            .listen(widget.onExit),
      )
      ..add(
        PlaidLinkFlutterPlatform.instance
            .embeddedLinkEvents(viewId)
            .listen(widget.onEvent),
      )
      ..add(
        PlaidLinkFlutterPlatform.instance.embeddedLoadEvents(viewId).listen((
          _,
        ) {
          widget.onLoad?.call();
        }),
      );
  }
}
