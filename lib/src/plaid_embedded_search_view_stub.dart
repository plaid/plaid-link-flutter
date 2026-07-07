import 'package:flutter/widgets.dart';

import 'types.dart';

class PlaidEmbeddedSearchView extends StatelessWidget {
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
  Widget build(BuildContext context) => const SizedBox.shrink();
}
