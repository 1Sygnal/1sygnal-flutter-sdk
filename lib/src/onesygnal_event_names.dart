/// The client-facing event names dispatched over the `onesygnal_events`
/// EventChannel. Mirrors apps/android-sdk's `OneSygnalEvent` / apps/ios-sdk's
/// `OneSygnalEvent` — kept as an independent Dart declaration since Dart
/// can't import a compiled Kotlin/Swift enum.
enum OneSygnalEventName {
  /// Fires once the SDK has finished initializing.
  ready('ready'),

  /// Fires once a survey overlay is confirmed attached/rendered.
  surveyShown('survey:shown'),

  /// Fires once a survey is fully completed.
  surveyCompleted('survey:completed'),

  /// Fires when a survey is dismissed before completion.
  surveyDismissed('survey:dismissed'),

  /// Fires as soon as the visitor answers a question in a survey.
  surveyQuestionAnswered('survey:question_answered');

  const OneSygnalEventName(this.wireName);

  /// The raw string sent over the event channel for this event.
  final String wireName;

  /// Looks up the enum value for a raw wire-format event name — needed
  /// because `switch` cases must be compile-time constants, and
  /// enhanced-enum field access (`OneSygnalEventName.ready.wireName`)
  /// doesn't qualify, so dispatch code switches on the enum value itself via
  /// this lookup instead of on the raw wire string.
  static OneSygnalEventName? fromWireName(String value) {
    for (final name in values) {
      if (name.wireName == value) return name;
    }
    return null;
  }
}
