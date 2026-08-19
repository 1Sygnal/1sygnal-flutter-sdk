import 'package:onesygnal/src/onesygnal_event_models.dart';

/// Implement this (overriding only what you need — every method has a no-op
/// default) to listen for OneSygnal SDK lifecycle events. See also
/// [OneSygnalEventListener] for a closure-based convenience alternative that
/// doesn't require declaring a subclass.
abstract class OneSygnalEventListenerInterface {
  /// The native SDK has finished initializing and is ready to trigger surveys.
  void ready() {}

  /// A survey was shown to the user.
  void surveyShown(SurveyShownEvent event) {}

  /// A survey was completed — every question in the flow was answered.
  void surveyCompleted(SurveyCompletedEvent event) {}

  /// A survey was dismissed before completion.
  void surveyDismissed(SurveyDismissedEvent event) {}

  /// The visitor answered a question in a survey.
  void questionAnswered(QuestionAnsweredEvent event) {}
}

/// A convenience [OneSygnalEventListenerInterface] taking optional named
/// closures, for callers who only care about a subset of events and don't
/// want to declare a subclass.
class OneSygnalEventListener implements OneSygnalEventListenerInterface {
  /// Creates a listener from the given optional per-event closures.
  OneSygnalEventListener({
    this.onReady,
    this.onSurveyShown,
    this.onSurveyCompleted,
    this.onSurveyDismissed,
    this.onQuestionAnswered,
  });

  /// Called when the native SDK finishes initializing.
  final void Function()? onReady;

  /// Called when a survey is shown to the user.
  final void Function(SurveyShownEvent event)? onSurveyShown;

  /// Called when a survey is completed.
  final void Function(SurveyCompletedEvent event)? onSurveyCompleted;

  /// Called when a survey is dismissed before completion.
  final void Function(SurveyDismissedEvent event)? onSurveyDismissed;

  /// Called when the visitor answers a question in a survey.
  final void Function(QuestionAnsweredEvent event)? onQuestionAnswered;

  @override
  void ready() => onReady?.call();

  @override
  void surveyShown(SurveyShownEvent event) => onSurveyShown?.call(event);

  @override
  void surveyCompleted(SurveyCompletedEvent event) =>
      onSurveyCompleted?.call(event);

  @override
  void surveyDismissed(SurveyDismissedEvent event) =>
      onSurveyDismissed?.call(event);

  @override
  void questionAnswered(QuestionAnsweredEvent event) =>
      onQuestionAnswered?.call(event);
}
