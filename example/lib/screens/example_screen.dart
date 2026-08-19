import 'package:flutter/material.dart';
import 'package:onesygnal/onesygnal.dart';

// Local dev stack — see .context/e2e-test-suite/config.env (written by 01-api-setup.ts). Swap
// for the real staging apiKey if you need to point this app back at staging instead. Set via
// setApiKey() rather than AndroidManifest.xml/Info.plist meta-data — the primary, no-native-edit
// setup path for Flutter integrators.
const _localApiKey = 'pk_be8e04c9e026cf809f24cb2db608ede6';

class ExampleScreen extends StatefulWidget {
  const ExampleScreen({super.key});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  final _localeController = TextEditingController(text: 'fr');
  final _userIdController = TextEditingController();
  final _eventNameController = TextEditingController();
  bool _sdkInitialized = false;
  bool _sdkInitializing = false;
  String? _identifiedUserId;
  int _trackedCount = 0;

  @override
  void initState() {
    super.initState();
    _userIdController.addListener(_rebuild);
    _eventNameController.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _localeController.dispose();
    _userIdController.removeListener(_rebuild);
    _userIdController.dispose();
    _eventNameController.removeListener(_rebuild);
    _eventNameController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _initializeSdk() async {
    // initialize() now only resolves once native init (config/user/surveys fetch, rules engine
    // load) has actually finished, which can take a few seconds — show an intermediate state so
    // the button doesn't look hung while that's in flight.
    setState(() => _sdkInitializing = true);
    await OneSygnal().setApiKey(_localApiKey);
    final locale = _localeController.text.trim();
    if (locale.isNotEmpty) await OneSygnal().setLocale(locale);
    await OneSygnal().initialize();
    setState(() {
      _sdkInitializing = false;
      _sdkInitialized = true;
    });
  }

  Future<void> _updateLocale() async {
    final locale = _localeController.text.trim();
    if (locale.isNotEmpty) await OneSygnal().setLocale(locale);
  }

  Future<void> _identify() async {
    final userId = _userIdController.text.trim();
    await OneSygnal().identify(userId, attributes: {'source': 'example_app'});
    setState(() => _identifiedUserId = userId);
  }

  Future<void> _track(String eventName) async {
    final tracked = await OneSygnal().track(eventName);
    setState(() => _trackedCount++);
    _showSnack(
      tracked ? 'Tracked "$eventName"' : 'Failed to track "$eventName"',
    );
  }

  @override
  Widget build(BuildContext context) {
    final canIdentify =
        _sdkInitialized && _userIdController.text.trim().isNotEmpty;
    final canTrackEvent =
        _sdkInitialized && _eventNameController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('OneSygnal Flutter')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'OneSygnal Flutter example app',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'This screen is plain Flutter content. Tapping a button below calls '
            'OneSygnal().track(...) — if a survey\'s trigger rules match, it renders as a '
            'native window-level overlay above this screen, not inside it.',
          ),
          const SizedBox(height: 32),
          Text('Staging test', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          // Left editable after init (not `!_sdkInitialized && ...`) so the "Update Locale"
          // button below has a live value to send — setLocale() is documented live-switchable
          // with no restart needed, but there was previously no UI path to exercise that
          // post-init.
          TextField(
            controller: _localeController,
            enabled: !_sdkInitializing,
            decoration: const InputDecoration(
              labelText: 'Locale (e.g. fr, fr-FR)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed:
                (_sdkInitialized || _sdkInitializing) ? null : _initializeSdk,
            child: Text(
              _sdkInitialized
                  ? 'Initialized'
                  : _sdkInitializing
                  ? 'Initializing…'
                  : 'Initialize SDK',
            ),
          ),
          if (_sdkInitialized)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Initialized with locale "${_localeController.text}" — call '
                'OneSygnal().setLocale(...) to switch it live, no restart needed.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (_sdkInitialized)
            OutlinedButton(
              onPressed: _updateLocale,
              child: const Text('Update Locale'),
            ),
          const SizedBox(height: 32),
          Text('Identify user', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _userIdController,
            enabled: _sdkInitialized,
            decoration: const InputDecoration(
              labelText: 'User ID',
              hintText: 'e.g. user_123',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: canIdentify ? _identify : null,
            child: const Text('Identify'),
          ),
          if (_identifiedUserId != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Identified as "$_identifiedUserId".',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 32),
          TextField(
            controller: _eventNameController,
            decoration: const InputDecoration(
              labelText: 'Event name (e.g. shipping)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed:
                canTrackEvent
                    ? () => _track(_eventNameController.text.trim())
                    : null,
            child: const Text('Track event'),
          ),
          const SizedBox(height: 32),
          Text('Survey types', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _sdkInitialized ? () => _track('shipping') : null,
            child: const Text('Track shipping'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _sdkInitialized ? () => _track('checkout_made') : null,
            child: const Text('Track checkout_made'),
          ),
          const SizedBox(height: 32),
          Text(
            'Tracked $_trackedCount time(s) this session.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
