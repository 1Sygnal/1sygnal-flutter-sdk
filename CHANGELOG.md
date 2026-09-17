## 1.0.3

Internal only — no public API or wire-value changes.

* Event names like `"survey:question_answered"` and `"survey_dismissed"` were repeated as raw
  string literals at every call site across this plugin's Dart code and its Android/iOS native
  bridges. Both vocabularies (internal tracking names vs. client-facing emit/on names) are now
  declared once (`src/onesygnal_event_names.dart`, not part of this package's public API) and
  referenced everywhere; the native plugin bridges derive their event list from the native SDKs'
  own public enum instead of hand-typing a duplicate copy that could drift.

## 1.0.2

### New

* `QuestionAnsweredEvent` now carries `answer` (the raw answer value — its shape depends on the
  question type, and it's `null` if an optional question was left unanswered) and `languageCode`
  (the language the survey was rendered in), alongside the existing `surveyId`/`questionId`. Both
  native SDKs already computed these values for the `survey.question.answered` webhook; they're
  now also included in the event this plugin already delivered to Dart listeners.

## 1.0.1

### Fixes

* Android: the native `onesygnal-sdk` AAR dependency was pinned to `0.1.0` regardless of which
  native SDK version was actually current at release time — `1.0.0` shipped depending on this same
  stale `0.1.0` AAR. The publish pipeline now resolves it to the real native release version.
* The `WRAPPER_VERSION`/`wrapperVersion` identifiers this plugin reports to the native SDK (surfaced
  in `clientContext`/`$lib_version` on tracked events) had drifted to `"0.4.0"` in the published
  `1.0.0` package instead of tracking the actual package version — the publish pipeline now stamps
  both to the real release version.

## 1.0.0

Initial public release on pub.dev.

## 0.4.0

The Android host-app requirement from 0.2.0 is gone: `SurveyWindowOverlay` now supplies its own
`Lifecycle`/`ViewModelStore`/`SavedStateRegistry`/`OnBackPressedDispatcher` owners instead of
borrowing the host Activity's, so a plain `class MainActivity : FlutterActivity()` works again.
Hosts that added the `ViewModelStoreOwner`/`SavedStateRegistryOwner`/`OnBackPressedDispatcherOwner`
ceremony documented under 0.2.0 can revert their `MainActivity` back to that one-liner.

## 0.3.0 (breaking)

Every `Future` this package returns previously resolved before the native work it represents had
actually happened — the channel reply was sent on the line right after the native call was
dispatched, not once it finished. `await identify('u1'); track('purchase')` could evaluate against
the outgoing anonymous user instead of the newly-identified one, and `await shutdown();
await initialize()` could leave the SDK dead for the rest of the process (`shutdown` cleared
`initialized` inside its own async work, after `initialize` had already seen it still `true` and
no-opped). Native (`apps/android-sdk`, `apps/ios-sdk`) now answers every completion from inside the
async work itself, on every path, so `await` means what it says on both platforms.

### Breaking changes

* `identify(userId, {attributes})` and `initialize()` now return `Future<bool>` (were
  `Future<void>`) — `identify` reports whether the identify call succeeded, `initialize` whether
  the SDK became ready. Existing callers that don't use the return value are unaffected.
* `initialize()`'s future (and the `ready` event) now resolve only once native setup has fully
  finished — config fetched, user ensured, surveys fetched, rules engine loaded — not the instant
  the call is dispatched. On a poor network this is bounded by the native HTTP timeouts (Android:
  10s connect / 15s read; iOS: 15s request / 30s resource) times up to four sequential calls, so it
  can now take noticeably longer than before. Do not block UI on `await initialize()`; show an
  "Initializing…" state instead (see `example/`).
* `logout()`/`reset()`/`shutdown()` keep their `Future<void>` signature, but now also resolve only
  once the native work has actually finished, not just once it was dispatched.

### Fixes

* Removing an event listener (`removeEventListener`/disposing an `OneSygnalEventListener`) and
  then adding a new one used to duplicate every subsequent native event delivery — a widget that
  registers in `initState` and removes in `dispose` accumulated one extra callback per navigation
  cycle, since neither native plugin actually released its native listener on cancel. Both native
  SDKs' `on()` now returns a handle that's cancelled on `onCancel` (and on engine detach), so a
  removed listener stays removed.

## 0.2.0 (breaking)

Converted from a from-scratch Dart implementation to a thin, non-federated Flutter plugin
bridging to the native [Android](../android-sdk) and [iOS](../ios-sdk) SDKs — see
[`docs/native-sdk-port/04-flutter-bridge.md`](../../docs/native-sdk-port/04-flutter-bridge.md)
for the design behind this change, and [`ARCHITECTURE.md`](ARCHITECTURE.md) for the resulting
channel contract. Surveys now render as a native, OS-level window overlay above the entire app
(Flutter content included) instead of an embedded Flutter widget.

### Breaking changes

* `init(apiKey, {host, locale, trackPurchases})` → split into `setApiKey(apiKey)`, `setLocale(locale)`
  (both optional, called before `initialize()`), and `initialize()` (no arguments). `host` is no
  longer configurable at all (the native SDKs hardcode it); `trackPurchases` was already dead code.
* `track(eventName, {properties})` now returns `Future<bool>` (was `Future<void>`) — reports
  whether the event was actually recorded.
* `on(String event, Function callback)` replaced by typed event listeners:
  `addOneSygnalEventListener`/`removeOneSygnalEventListener` with
  `OneSygnalEventListenerInterface`/`OneSygnalEventListener`, and typed event classes
  (`SurveyShownEvent`, `SurveyCompletedEvent`, `SurveyDismissedEvent`, `QuestionAnsweredEvent`).
* `navigatorKey` removed, with no replacement — no longer needed now that surveys render natively.
* `surveyCompleted()`/`surveyDismissed()` removed from the public API — response capture happens
  inside the native renderer now.
* `init(testDio:)` and `resetForTesting()` removed — test seams move to channel mocking
  (`TestDefaultBinaryMessenger`).

### New

* `questionAnswered` event — the SDK now notifies host-app listeners as each question is
  answered, not just on survey shown/completed/dismissed (previously only tracked internally as
  an analytics event).

### Android integration requirement

* Your `MainActivity.kt` must implement `ViewModelStoreOwner`, `SavedStateRegistryOwner`, and
  `OnBackPressedDispatcherOwner` — Flutter's default `FlutterActivity` implements none of them.
  Missing the first two means surveys never render (no crash, no error); missing the third crashes
  the app on a Dropdown question. See [`ARCHITECTURE.md`](ARCHITECTURE.md) and `example/`'s
  `MainActivity.kt`.

## 0.0.1

* TODO: Describe initial release.
