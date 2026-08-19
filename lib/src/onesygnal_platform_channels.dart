import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:onesygnal/src/onesygnal_event_listener.dart';
import 'package:onesygnal/src/onesygnal_event_models.dart';
import 'package:onesygnal/src/onesygnal_platform_interface.dart';

/// The (only) implementation of [OneSygnalPlatform] — talks to the native
/// Android/iOS SDKs via a method channel for one-shot calls and an event
/// channel for survey lifecycle events. No business logic lives here: every
/// method is a direct pass-through, and the native SDKs decide everything
/// (targeting, rendering, persistence).
class OneSygnalChannels extends OneSygnalPlatform {
  /// The method channel used for one-shot calls into the native SDKs.
  @visibleForTesting
  final methodChannel = const MethodChannel('onesygnal');

  /// The event channel used to receive survey lifecycle events from the
  /// native SDKs.
  @visibleForTesting
  final eventChannel = const EventChannel('onesygnal_events');

  final List<OneSygnalEventListenerInterface> _listeners = [];
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;

  @override
  Future<bool> initialize() async {
    final result = await methodChannel.invokeMethod<bool>('initialize');
    return result ?? false;
  }

  @override
  Future<void> setApiKey(String apiKey) async {
    await methodChannel.invokeMethod('setApiKey', apiKey);
  }

  @override
  Future<void> setLocale(String locale) async {
    await methodChannel.invokeMethod('setLocale', locale);
  }

  @override
  Future<bool> track(
    String eventName, {
    Map<String, dynamic>? properties,
  }) async {
    final result = await methodChannel.invokeMethod<bool>('track', {
      'eventName': eventName,
      'properties': properties ?? const {},
    });
    return result ?? false;
  }

  @override
  Future<bool> identify(
    String userId, {
    Map<String, dynamic>? attributes,
  }) async {
    final result = await methodChannel.invokeMethod<bool>('identify', {
      'userId': userId,
      'attributes': attributes,
    });
    return result ?? false;
  }

  @override
  Future<void> logout() async {
    await methodChannel.invokeMethod('logout');
  }

  @override
  Future<void> reset() async {
    await methodChannel.invokeMethod('reset');
  }

  @override
  Future<void> setSurveysEnabled(bool enabled) async {
    await methodChannel.invokeMethod('setSurveysEnabled', enabled);
  }

  @override
  Future<bool> areSurveysEnabled() async {
    final result = await methodChannel.invokeMethod<bool>('areSurveysEnabled');
    return result ?? false;
  }

  @override
  Future<bool> isInitialized() async {
    final result = await methodChannel.invokeMethod<bool>('isInitialized');
    return result ?? false;
  }

  @override
  Future<void> shutdown() async {
    await methodChannel.invokeMethod('shutdown');
  }

  @override
  void addEventListener(OneSygnalEventListenerInterface listener) {
    _listeners.add(listener);
    if (_listeners.length > 1) return;

    _eventSubscription = eventChannel
        .receiveBroadcastStream()
        .map<Map<String, dynamic>>(
          (dynamic event) => Map<String, dynamic>.from(event as Map),
        )
        .listen(_dispatch);
  }

  @override
  void removeEventListener(OneSygnalEventListenerInterface listener) {
    _listeners.remove(listener);
    if (_listeners.isNotEmpty) return;

    unawaited(_eventSubscription?.cancel());
    _eventSubscription = null;
  }

  void _dispatch(Map<String, dynamic> map) {
    // Snapshot: a listener may synchronously add/removeEventListener from
    // within its own callback (e.g. unsubscribing itself after handling one
    // event), which would otherwise mutate _listeners mid-iteration and
    // throw ConcurrentModificationError.
    for (final listener in List.of(_listeners)) {
      switch (map['event_type'] as String) {
        case 'ready':
          listener.ready();
        case 'survey:shown':
          listener.surveyShown(SurveyShownEvent.from(map));
        case 'survey:completed':
          listener.surveyCompleted(SurveyCompletedEvent.from(map));
        case 'survey:dismissed':
          listener.surveyDismissed(SurveyDismissedEvent.from(map));
        case 'survey:question_answered':
          listener.questionAnswered(QuestionAnsweredEvent.from(map));
      }
    }
  }
}
