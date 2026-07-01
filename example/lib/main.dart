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
            ExampleRow(
              title: 'Plaid Layer Session',
              description: 'Create, open, and submit data to a Layer session.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PlaidLayerSessionScreen(),
                  ),
                );
              },
            ),
            ExampleRow(
              title: 'Plaid Headless Session',
              description: 'Create and start a Headless Link session.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PlaidHeadlessSessionScreen(),
                  ),
                );
              },
            ),
            ExampleRow(
              title: 'Plaid Embedded Search',
              description: 'Render embedded institution search in Flutter.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PlaidEmbeddedSearchScreen(),
                  ),
                );
              },
            ),
            ExampleRow(
              title: 'Sync FinanceKit',
              description: 'Sync FinanceKit data on supported iOS devices.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const FinanceKitScreen(),
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

class PlaidLayerSessionScreen extends StatefulWidget {
  const PlaidLayerSessionScreen({super.key});

  @override
  State<PlaidLayerSessionScreen> createState() =>
      _PlaidLayerSessionScreenState();
}

class _PlaidLayerSessionScreenState extends State<PlaidLayerSessionScreen> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _paramsController = TextEditingController();
  final List<LinkEvent> _events = <LinkEvent>[];
  PlaidLayerSession? _session;
  SessionState _state = SessionState.idle;
  String? _errorMessage;

  @override
  void dispose() {
    _tokenController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _paramsController.dispose();
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
      final session = await createPlaidLayerSession(
        LayerTokenConfiguration(
          token: token,
          onSuccess: (success) {
            _showResultSheet(
              title: 'Layer Success',
              rows: [
                ResultRow('Public token', success.publicToken),
                ResultRow('Link session ID', success.metadata.linkSessionId),
              ],
            );
          },
          onExit: (exit) {
            _showResultSheet(
              title: 'Layer Exit',
              rows: [
                ResultRow('Status', exit.metadata.status ?? ''),
                ResultRow('Error code', exit.error?.errorCode ?? ''),
                ResultRow('Error message', exit.error?.errorMessage ?? ''),
              ],
            );
          },
          onEvent: (event) => setState(() => _events.add(event)),
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
      await _session?.open();
    } catch (error) {
      setState(() {
        _state = SessionState.error;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _submit() async {
    try {
      await _session?.submit(
        SubmissionData(
          phoneNumber: emptyToNull(_phoneController.text),
          dateOfBirth: emptyToNull(_dobController.text),
          params: parseParams(_paramsController.text),
        ),
      );
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
    return ExampleDetailScaffold(
      title: 'Plaid Layer Session Example',
      children: [
        TokenInputView(
          controller: _tokenController,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 16),
        SmallTextInputView(
          label: 'Phone number',
          hintText: '+15551234567',
          controller: _phoneController,
        ),
        const SizedBox(height: 12),
        SmallTextInputView(
          label: 'Date of birth',
          hintText: 'YYYY-MM-DD',
          controller: _dobController,
        ),
        const SizedBox(height: 12),
        SmallTextInputView(
          label: 'Params',
          hintText: 'key=value,key2=value2',
          controller: _paramsController,
        ),
        const SizedBox(height: 20),
        if (_state == SessionState.error && _errorMessage != null)
          ErrorView(message: _errorMessage!),
        const SizedBox(height: 16),
        ConnectButton(
          state: _state,
          hasValidToken: _hasValidToken,
          createLabel: 'Create Layer Session',
          openLabel: 'Open Layer Session',
          onCreate: _createSession,
          onOpen: _openSession,
        ),
        const SizedBox(height: 12),
        SecondaryButton(
          label: 'Submit Layer Data',
          enabled: _session != null,
          onPressed: _submit,
        ),
      ],
    );
  }
}

class PlaidHeadlessSessionScreen extends StatefulWidget {
  const PlaidHeadlessSessionScreen({super.key});

  @override
  State<PlaidHeadlessSessionScreen> createState() =>
      _PlaidHeadlessSessionScreenState();
}

class _PlaidHeadlessSessionScreenState
    extends State<PlaidHeadlessSessionScreen> {
  final TextEditingController _tokenController = TextEditingController();
  final List<LinkEvent> _events = <LinkEvent>[];
  PlaidHeadlessSession? _session;
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
      final session = await createPlaidHeadlessSession(
        LinkTokenConfiguration(
          token: token,
          onSuccess: (success) {
            _showResultSheet(
              title: 'Headless Success',
              rows: [
                ResultRow('Public token', success.publicToken),
                ResultRow('Link session ID', success.metadata.linkSessionId),
              ],
            );
          },
          onExit: (exit) {
            _showResultSheet(
              title: 'Headless Exit',
              rows: [
                ResultRow('Status', exit.metadata.status ?? ''),
                ResultRow('Error code', exit.error?.errorCode ?? ''),
                ResultRow('Error message', exit.error?.errorMessage ?? ''),
              ],
            );
          },
          onEvent: (event) => setState(() => _events.add(event)),
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

  Future<void> _startSession() async {
    try {
      await _session?.start();
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
    return ExampleDetailScaffold(
      title: 'Plaid Headless Session Example',
      children: [
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
          createLabel: 'Create Headless Session',
          openLabel: 'Start Headless Session',
          onCreate: _createSession,
          onOpen: _startSession,
        ),
      ],
    );
  }
}

class PlaidEmbeddedSearchScreen extends StatefulWidget {
  const PlaidEmbeddedSearchScreen({super.key});

  @override
  State<PlaidEmbeddedSearchScreen> createState() =>
      _PlaidEmbeddedSearchScreenState();
}

class _PlaidEmbeddedSearchScreenState extends State<PlaidEmbeddedSearchScreen> {
  final TextEditingController _tokenController = TextEditingController();
  final List<LinkEvent> _events = <LinkEvent>[];
  String? _activeToken;
  String? _errorMessage;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  bool get _hasValidToken => isValidToken(_tokenController.text);

  void _loadEmbeddedSearch() {
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
      _activeToken = token;
      _errorMessage = null;
      _events.clear();
    });
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
          onClose: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExampleDetailScaffold(
      title: 'Plaid Embedded Search Example',
      children: [
        TokenInputView(
          controller: _tokenController,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 20),
        if (_errorMessage != null) ErrorView(message: _errorMessage!),
        const SizedBox(height: 16),
        SecondaryButton(
          label: 'Load Embedded Search',
          enabled: _hasValidToken,
          onPressed: _loadEmbeddedSearch,
        ),
        const SizedBox(height: 16),
        if (_activeToken != null)
          Container(
            height: 420,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCCCCCC)),
            ),
            child: PlaidEmbeddedSearchView(
              token: _activeToken!,
              onSuccess: (success) {
                _showResultSheet(
                  title: 'Embedded Success',
                  rows: [
                    ResultRow('Public token', success.publicToken),
                    ResultRow(
                      'Link session ID',
                      success.metadata.linkSessionId,
                    ),
                  ],
                );
              },
              onExit: (exit) {
                _showResultSheet(
                  title: 'Embedded Exit',
                  rows: [
                    ResultRow('Status', exit.metadata.status ?? ''),
                    ResultRow('Error code', exit.error?.errorCode ?? ''),
                    ResultRow('Error message', exit.error?.errorMessage ?? ''),
                  ],
                );
              },
              onEvent: (event) => setState(() => _events.add(event)),
            ),
          ),
      ],
    );
  }
}

class FinanceKitScreen extends StatefulWidget {
  const FinanceKitScreen({super.key});

  @override
  State<FinanceKitScreen> createState() => _FinanceKitScreenState();
}

class _FinanceKitScreenState extends State<FinanceKitScreen> {
  final TextEditingController _tokenController = TextEditingController();
  FinanceKitSyncBehavior _syncBehavior = FinanceKitSyncBehavior.live;
  SessionState _state = SessionState.idle;
  String? _resultMessage;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  bool get _hasValidToken => isValidToken(_tokenController.text);

  Future<void> _sync() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() => _resultMessage = 'Please enter a link token');
      return;
    }
    if (!isValidToken(token)) {
      setState(() => _resultMessage = 'Invalid token format');
      return;
    }

    setState(() {
      _state = SessionState.loading;
      _resultMessage = null;
    });

    try {
      await syncFinanceKit(
        FinanceKitConfiguration(token: token, syncBehavior: _syncBehavior),
      );
      setState(() {
        _state = SessionState.ready;
        _resultMessage = 'FinanceKit sync completed';
      });
    } catch (error) {
      setState(() {
        _state = SessionState.error;
        _resultMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _state == SessionState.loading;

    return ExampleDetailScaffold(
      title: 'Sync FinanceKit Example',
      children: [
        TokenInputView(
          controller: _tokenController,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SegmentedButton<FinanceKitSyncBehavior>(
            segments: const [
              ButtonSegment(
                value: FinanceKitSyncBehavior.live,
                label: Text('Live'),
              ),
              ButtonSegment(
                value: FinanceKitSyncBehavior.simulated,
                label: Text('Simulated'),
              ),
            ],
            selected: {_syncBehavior},
            onSelectionChanged: (values) {
              setState(() => _syncBehavior = values.single);
            },
          ),
        ),
        const SizedBox(height: 16),
        if (_resultMessage != null) ErrorView(message: _resultMessage!),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _hasValidToken && !isLoading ? _sync : null,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              disabledBackgroundColor: const Color(0xFFAAAAAA),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child:
                isLoading
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Text(
                      'SYNC FINANCEKIT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
          ),
        ),
      ],
    );
  }
}

class ExampleDetailScaffold extends StatelessWidget {
  const ExampleDetailScaffold({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
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
                  ...children,
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

class SmallTextInputView extends StatelessWidget {
  const SmallTextInputView({
    required this.label,
    required this.hintText,
    required this.controller,
    super.key,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: TextField(
        controller: controller,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
          ),
        ),
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
    this.createLabel = 'Create Link Session',
    this.openLabel = 'Connect Bank Account',
    super.key,
  });

  final SessionState state;
  final bool hasValidToken;
  final VoidCallback onCreate;
  final VoidCallback onOpen;
  final String createLabel;
  final String openLabel;

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
            ? createLabel
            : openLabel;

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

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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

String? emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

Map<String, String>? parseParams(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final params = <String, String>{};
  for (final entry in trimmed.split(',')) {
    final parts = entry.split('=');
    if (parts.length == 2) {
      params[parts.first.trim()] = parts.last.trim();
    }
  }
  return params.isEmpty ? null : params;
}
