import 'package:onesygnal/src/onesygnal_event_listener.dart';
import 'package:onesygnal/src/onesygnal_platform_channels.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The interface every platform-specific OneSygnal implementation must
/// satisfy. Not federated across separate pub.dev packages (this repo has
/// exactly one implementation, [OneSygnalChannels]) — this abstraction exists
/// purely as a clean internal seam for tests to substitute a fake instance,
/// not to support alternate platform backends. Consumers should use the
/// `OneSygnal` facade instead of this class directly.
abstract class OneSygnalPlatform extends PlatformInterface {
  /// Constructs a platform implementation guarded by [PlatformInterface]'s
  /// token check.
  OneSygnalPlatform() : super(token: _token);

  static final Object _token = Object();

  static OneSygnalPlatform _instance = OneSygnalChannels();

  /// The active platform implementation, defaulting to [OneSygnalChannels].
  static OneSygnalPlatform get instance => _instance;

  /// Overrides [instance] — used by tests to substitute a fake
  /// implementation.
  static set instance(OneSygnalPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Mirrors `OneSygnal.initialize()`.
  Future<bool> initialize() {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Mirrors `OneSygnal.setApiKey()`.
  Future<void> setApiKey(String apiKey) {
    throw UnimplementedError('setApiKey() has not been implemented.');
  }

  /// Mirrors `OneSygnal.setLocale()`.
  Future<void> setLocale(String locale) {
    throw UnimplementedError('setLocale() has not been implemented.');
  }

  /// Mirrors `OneSygnal.track()`.
  Future<bool> track(String eventName, {Map<String, dynamic>? properties}) {
    throw UnimplementedError('track() has not been implemented.');
  }

  /// Mirrors `OneSygnal.identify()`.
  Future<bool> identify(String userId, {Map<String, dynamic>? attributes}) {
    throw UnimplementedError('identify() has not been implemented.');
  }

  /// Mirrors `OneSygnal.logout()`.
  Future<void> logout() {
    throw UnimplementedError('logout() has not been implemented.');
  }

  /// Mirrors `OneSygnal.reset()`.
  Future<void> reset() {
    throw UnimplementedError('reset() has not been implemented.');
  }

  /// Mirrors `OneSygnal.setSurveysEnabled()`.
  // ignore: avoid_positional_boolean_parameters
  Future<void> setSurveysEnabled(bool enabled) {
    throw UnimplementedError('setSurveysEnabled() has not been implemented.');
  }

  /// Mirrors `OneSygnal.areSurveysEnabled()`.
  Future<bool> areSurveysEnabled() {
    throw UnimplementedError('areSurveysEnabled() has not been implemented.');
  }

  /// Mirrors `OneSygnal.isInitialized()`.
  Future<bool> isInitialized() {
    throw UnimplementedError('isInitialized() has not been implemented.');
  }

  /// Mirrors `OneSygnal.shutdown()`.
  Future<void> shutdown() {
    throw UnimplementedError('shutdown() has not been implemented.');
  }

  /// Mirrors `OneSygnal.addEventListener()`.
  void addEventListener(OneSygnalEventListenerInterface listener) {
    throw UnimplementedError('addEventListener() has not been implemented.');
  }

  /// Mirrors `OneSygnal.removeEventListener()`.
  void removeEventListener(OneSygnalEventListenerInterface listener) {
    throw UnimplementedError(
      'removeEventListener() has not been implemented.',
    );
  }
}
