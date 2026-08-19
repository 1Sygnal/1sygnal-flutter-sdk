import 'package:onesygnal/src/onesygnal_event_listener.dart';
import 'package:onesygnal/src/onesygnal_platform_interface.dart';

/// The OneSygnal Flutter SDK's public entry point — a thin bridge over the
/// native Android/iOS SDKs (apps/android-sdk, apps/ios-sdk), which own
/// everything: HTTP transport, storage, trigger evaluation, and rendering
/// surveys as a native, OS-level window overlay above the entire app (Flutter
/// content included). Nothing here does any of that work itself — every
/// method is a direct pass-through to [OneSygnalPlatform.instance].
class OneSygnal {
  /// Returns the shared [OneSygnal] singleton instance.
  factory OneSygnal() => _instance ??= OneSygnal._internal();

  OneSygnal._internal();

  static OneSygnal? _instance;

  /// Overrides the API key normally read from the native
  /// `AndroidManifest.xml`/`Info.plist` config — lets integrators configure
  /// the key purely in code instead of adding those entries. Must be called
  /// before [initialize].
  Future<void> setApiKey(String apiKey) =>
      OneSygnalPlatform.instance.setApiKey(apiKey);

  /// Overrides the locale [initialize] would otherwise default to (the
  /// device's locale). Live-reactive: calling it after [initialize] has
  /// already run immediately triggers a fresh config/surveys fetch under the
  /// new locale — no restart needed.
  Future<void> setLocale(String locale) =>
      OneSygnalPlatform.instance.setLocale(locale);

  /// Initializes the SDK. Must be called before any other method (aside from
  /// [setApiKey]/[setLocale], which are meant to be called first). A no-op if
  /// already initialized.
  ///
  /// The returned future resolves only once native initialization has fully
  /// completed — config fetched, user ensured, surveys fetched, rules engine
  /// loaded — with whether it succeeded. On a poor network that's bounded by
  /// the native HTTP timeouts (Android: 10s connect / 15s read; iOS: 15s
  /// request / 30s resource) times up to four sequential calls, so this can
  /// take tens of seconds in the worst case. Do not block UI on
  /// `await initialize()`; show an "Initializing…" state instead and let it
  /// resolve in the background, or use the `ready` event
  /// ([addEventListener]) if you don't need the returned bool.
  Future<bool> initialize() => OneSygnalPlatform.instance.initialize();

  /// Records a custom event; evaluated against active surveys' trigger
  /// rules, which may show a survey. Returns whether the event was actually
  /// recorded (false if not yet initialized, or surveys are disabled, or
  /// rate-limited).
  Future<bool> track(String eventName, {Map<String, dynamic>? properties}) =>
      OneSygnalPlatform.instance.track(eventName, properties: properties);

  /// Links the anonymous device/session to a known external user ID, with
  /// optional trait attributes.
  ///
  /// The returned future resolves only once the native SDK has recorded the
  /// identify call, with whether it succeeded (false if not yet
  /// initialized). Awaiting it before tracking an event guarantees that
  /// event is evaluated against the identified user, not the outgoing
  /// anonymous one.
  Future<bool> identify(String userId, {Map<String, dynamic>? attributes}) =>
      OneSygnalPlatform.instance.identify(userId, attributes: attributes);

  /// Clears the identified user, reverting to anonymous tracking. The
  /// returned future resolves only once the native SDK has finished the
  /// logout, not just once the call was dispatched.
  Future<void> logout() => OneSygnalPlatform.instance.logout();

  /// Fully resets local device/user state (new anonymous ID) and re-fetches
  /// surveys. The returned future resolves only once the native SDK has
  /// finished the reset, not just once the call was dispatched.
  Future<void> reset() => OneSygnalPlatform.instance.reset();

  /// Globally suppresses (or re-enables) survey overlays from being shown,
  /// without affecting event tracking.
  // ignore: avoid_positional_boolean_parameters
  Future<void> setSurveysEnabled(bool enabled) =>
      OneSygnalPlatform.instance.setSurveysEnabled(enabled);

  /// Reads back the flag set by [setSurveysEnabled].
  Future<bool> areSurveysEnabled() =>
      OneSygnalPlatform.instance.areSurveysEnabled();

  /// Reads back whether [initialize] has completed.
  Future<bool> isInitialized() => OneSygnalPlatform.instance.isInitialized();

  /// Flushes any pending events, tears down native timers/listeners, and
  /// marks the SDK uninitialized. The returned future resolves only once
  /// that teardown has finished — awaiting it before calling [initialize]
  /// again guarantees the SDK isn't still marked initialized underneath you.
  Future<void> shutdown() => OneSygnalPlatform.instance.shutdown();

  /// Registers a listener for SDK lifecycle events (ready, survey
  /// shown/completed/dismissed, question answered). See
  /// [OneSygnalEventListenerInterface]/[OneSygnalEventListener].
  void addEventListener(OneSygnalEventListenerInterface listener) =>
      OneSygnalPlatform.instance.addEventListener(listener);

  /// Removes a listener added via [addEventListener].
  void removeEventListener(OneSygnalEventListenerInterface listener) =>
      OneSygnalPlatform.instance.removeEventListener(listener);
}
