<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.
-->

OneSygnal is an in-app survey SDK: track user events, and the SDK evaluates them against your
survey trigger rules and displays a matching survey natively, above your entire app.

This package is a thin Flutter bridge over the native [Android](../android-sdk) and
[iOS](../ios-sdk) SDKs — see [`ARCHITECTURE.md`](ARCHITECTURE.md) for how the bridge works. All
targeting, rendering, and persistence happens natively; this package only marshals calls across a
platform channel.

## Getting started

Register a listener for survey lifecycle events first (this just subscribes — it doesn't require
the SDK to already be running), then set your API key in code (no need to edit
`AndroidManifest.xml`/`Info.plist`) and initialize:

```dart
// Listen for survey lifecycle events. A native replay latch means this still receives "ready"
// even if it's registered after initialize() has already resolved, so there's no ordering
// requirement between this and the block below — registering first just matches this example.
OneSygnal().addEventListener(OneSygnalEventListener(
  onReady: () => print('SDK ready'),
  onSurveyShown: (e) => print('Survey shown: ${e.surveyId}'),
  onSurveyCompleted: (e) => print('Survey completed: ${e.surveyId}'),
  onSurveyDismissed: (e) => print('Survey dismissed: ${e.surveyId}'),
  onQuestionAnswered: (e) => print('Question ${e.questionId} answered in ${e.surveyId}'),
));

await OneSygnal().setApiKey('pk_your_key');
final ready = await OneSygnal().initialize();
```

`initialize()`'s future resolves only once native setup has actually finished — on a poor network
that can take a few seconds, bounded by the native HTTP timeouts. Don't block your UI on it; show
an "Initializing…" state instead (see `example/`), or listen for the `ready` event if you don't
need the returned bool.

## Usage

```dart
// Optional: override the device's default locale. Live-reactive — can be called before or
// after initialize().
await OneSygnal().setLocale('fr');

// Record an event; the SDK evaluates it against your survey trigger rules.
final tracked = await OneSygnal().track('purchase_completed', properties: {'amount': 49.99});

// Link the anonymous session to a known user. Resolves only once the native SDK has recorded
// it — awaiting this before tracking an event guarantees that event evaluates against the
// identified user, not the outgoing anonymous one.
await OneSygnal().identify('user_123', attributes: {'plan': 'pro'});
```

See `example/` for a full demo app.

## Additional information

File issues against this monorepo. See [`ARCHITECTURE.md`](ARCHITECTURE.md) for the channel
contract and native plugin structure, and
[`docs/native-sdk-port/04-flutter-bridge.md`](../../docs/native-sdk-port/04-flutter-bridge.md)
for the design behind this bridge conversion.
