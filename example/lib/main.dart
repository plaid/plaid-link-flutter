import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plaid_link_flutter/plaid_link_flutter.dart';

void main() {
  runApp(const LinkKitExampleApp());
}

class LinkKitExampleApp extends StatelessWidget {
  const LinkKitExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LinkKit Examples',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007AFF)),
        scaffoldBackgroundColor: const Color(0xFFEEEEEE),
        useMaterial3: true,
      ),
      home: const ExampleListScreen(),
    );
  }
}

class ExampleListScreen extends StatefulWidget {
  const ExampleListScreen({super.key});

  @override
  State<ExampleListScreen> createState() => _ExampleListScreenState();
}

class _ExampleListScreenState extends State<ExampleListScreen> {
  late final Future<String?> _sdkVersion = PlaidLink.sdkVersion;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: SafeArea(
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'LinkKit Examples',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
            ),
            FutureBuilder<String?>(
              future: _sdkVersion,
              builder: (context, snapshot) {
                return Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 12),
                  child: Text(
                    'SDK: ${snapshot.data ?? 'Loading...'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF888888),
                    ),
                  ),
                );
              },
            ),
            ExampleRow(
              title: 'Plaid Link Session',
              description: 'Create and open a Link session with a link token.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PlaidLinkSessionScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PlaidLinkSessionScreen extends StatefulWidget {
  const PlaidLinkSessionScreen({super.key});

  @override
  State<PlaidLinkSessionScreen> createState() => _PlaidLinkSessionScreenState();
}

class _PlaidLinkSessionScreenState extends State<PlaidLinkSessionScreen> {
  final TextEditingController _tokenController = TextEditingController();
  final List<LinkEvent> _events = <LinkEvent>[];
  PlaidLinkSession? _session;
  SessionState _state = SessionState.idle;
  String? _errorMessage;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  bool get _hasValidToken => isValidToken(_tokenController.text);

  Future<void> _createSession() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() => _errorMessage = 'Please enter a link token');
      return;
    }
    if (!isValidToken(token)) {
      setState(() => _errorMessage = 'Invalid token format');
      return;
    }

    setState(() {
      _state = SessionState.loading;
      _errorMessage = null;
      _events.clear();
    });

    try {
      final session = await createPlaidLinkSession(
        LinkTokenConfiguration(
          token: token,
          onSuccess: (success) {
            _showResultSheet(
              title: 'Success',
              rows: [
                ResultRow('Public token', success.publicToken),
                ResultRow(
                  'Institution',
                  success.metadata.institution?.name ?? '',
                ),
                ResultRow(
                  'Accounts',
                  success.metadata.accounts.length.toString(),
                ),
                ResultRow('Link session ID', success.metadata.linkSessionId),
              ],
            );
          },
          onExit: (exit) {
            _showResultSheet(
              title: 'Exit',
              rows: [
                ResultRow('Status', exit.metadata.status ?? ''),
                ResultRow('Error code', exit.error?.errorCode ?? ''),
                ResultRow('Error message', exit.error?.errorMessage ?? ''),
                ResultRow('Link session ID', exit.metadata.linkSessionId),
              ],
            );
          },
          onEvent: (event) {
            _events.add(event);
            if (event.eventName == 'ERROR') {
              setState(() {
                _state = SessionState.error;
                _errorMessage =
                    event.metadata.errorMessage ?? 'Failed to create session.';
              });
            }
          },
        ),
      );
      setState(() {
        _session = session;
        _state = SessionState.ready;
      });
    } catch (error) {
      setState(() {
        _state = SessionState.error;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _openSession() async {
    try {
      await _session?.open(false);
    } catch (error) {
      setState(() {
        _state = SessionState.error;
        _errorMessage = error.toString();
      });
    }
  }

  void _showResultSheet({
    required String title,
    required List<ResultRow> rows,
  }) {
    if (!mounted) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return ResultSheet(
          title: title,
          rows: rows,
          events: List<LinkEvent>.of(_events),
          onClose: () {
            Navigator.of(context).pop();
            _createSession();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: SafeArea(
        child: ListView(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Plaid Link Session Example',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<String?>(
                    future: PlaidLink.sdkVersion,
                    builder: (context, snapshot) {
                      return Text(
                        'LinkKit ${snapshot.data ?? 'Loading...'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888888),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  TokenInputView(
                    controller: _tokenController,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  if (_state == SessionState.error && _errorMessage != null)
                    ErrorView(message: _errorMessage!),
                  const SizedBox(height: 16),
                  ConnectButton(
                    state: _state,
                    hasValidToken: _hasValidToken,
                    onCreate: _createSession,
                    onOpen: _openSession,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExampleRow extends StatelessWidget {
  const ExampleRow({
    required this.title,
    required this.description,
    required this.onTap,
    super.key,
  });

  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF555555),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TokenInputView extends StatelessWidget {
  const TokenInputView({
    required this.controller,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final validationError =
        controller.text.isEmpty || isValidToken(controller.text)
            ? null
            : 'Invalid token format';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Link token',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            onChanged: (_) => onChanged(),
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              hintText: 'link-sandbox-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
              hintStyle: const TextStyle(color: Color(0xFF999999)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.fromLTRB(10, 10, 44, 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color:
                      validationError == null
                          ? const Color(0xFFCCCCCC)
                          : const Color(0xFFFF3B30),
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  controller.text.isEmpty ? Icons.content_paste : Icons.close,
                ),
                onPressed: () async {
                  if (controller.text.isEmpty) {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    controller.text = data?.text?.trim() ?? '';
                  } else {
                    controller.clear();
                  }
                  onChanged();
                },
              ),
            ),
          ),
          if (validationError != null) ...[
            const SizedBox(height: 4),
            Text(
              validationError,
              style: const TextStyle(fontSize: 12, color: Color(0xFFFF3B30)),
            ),
          ],
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 28),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ConnectButton extends StatelessWidget {
  const ConnectButton({
    required this.state,
    required this.hasValidToken,
    required this.onCreate,
    required this.onOpen,
    super.key,
  });

  final SessionState state;
  final bool hasValidToken;
  final VoidCallback onCreate;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final isLoading = state == SessionState.loading;
    final isReady = state == SessionState.ready;
    final isIdle = state == SessionState.idle || state == SessionState.error;
    final isEnabled = (isIdle && hasValidToken) || isReady;
    final title =
        isLoading
            ? 'Initializing...'
            : isIdle
            ? 'Create Link Session'
            : 'Connect Bank Account';

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed:
            isEnabled && !isLoading ? (isReady ? onOpen : onCreate) : null,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF007AFF),
          disabledBackgroundColor: const Color(0xFFAAAAAA),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              title.toUpperCase(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class ResultSheet extends StatelessWidget {
  const ResultSheet({
    required this.title,
    required this.rows,
    required this.events,
    required this.onClose,
    super.key,
  });

  final String title;
  final List<ResultRow> rows;
  final List<LinkEvent> events;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...rows.map((row) => ResultLine(row: row)),
            const SizedBox(height: 12),
            Text(
              'Events: ${events.length}',
              style: const TextStyle(fontSize: 14, color: Color(0xFF555555)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onClose,
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResultLine extends StatelessWidget {
  const ResultLine({required this.row, super.key});

  final ResultRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
          ),
          Text(
            row.value.isEmpty ? '-' : row.value,
            style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
          ),
        ],
      ),
    );
  }
}

class ResultRow {
  const ResultRow(this.label, this.value);

  final String label;
  final String value;
}

enum SessionState { idle, loading, ready, error }

bool isValidToken(String token) {
  return RegExp(r'^link-(sandbox|development|production)-').hasMatch(token);
}
