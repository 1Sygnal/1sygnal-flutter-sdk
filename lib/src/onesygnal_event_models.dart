const _surveyId = 'surveyId';
const _questionId = 'questionId';

/// Emitted every time a survey is shown to the user.
class SurveyShownEvent {
  /// Creates a [SurveyShownEvent] for the given [surveyId].
  SurveyShownEvent({required this.surveyId});

  /// Builds a [SurveyShownEvent] from the event-channel payload [map].
  factory SurveyShownEvent.from(Map<String, dynamic> map) {
    return SurveyShownEvent(surveyId: map[_surveyId] as String);
  }

  /// The ID of the survey that was shown.
  final String surveyId;
}

/// Emitted once a survey has been completed — every question in the flow was
/// answered.
class SurveyCompletedEvent {
  /// Creates a [SurveyCompletedEvent] for the given [surveyId].
  SurveyCompletedEvent({required this.surveyId});

  /// Builds a [SurveyCompletedEvent] from the event-channel payload [map].
  factory SurveyCompletedEvent.from(Map<String, dynamic> map) {
    return SurveyCompletedEvent(surveyId: map[_surveyId] as String);
  }

  /// The ID of the survey that was completed.
  final String surveyId;
}

/// Emitted when a survey is dismissed before completion (closed, or
/// backgrounded past the throttle window).
class SurveyDismissedEvent {
  /// Creates a [SurveyDismissedEvent] for the given [surveyId].
  SurveyDismissedEvent({required this.surveyId});

  /// Builds a [SurveyDismissedEvent] from the event-channel payload [map].
  factory SurveyDismissedEvent.from(Map<String, dynamic> map) {
    return SurveyDismissedEvent(surveyId: map[_surveyId] as String);
  }

  /// The ID of the survey that was dismissed.
  final String surveyId;
}

/// Emitted as soon as the visitor answers a question in a survey.
class QuestionAnsweredEvent {
  /// Creates a [QuestionAnsweredEvent] for the given [surveyId] and
  /// [questionId].
  QuestionAnsweredEvent({required this.surveyId, required this.questionId});

  /// Builds a [QuestionAnsweredEvent] from the event-channel payload [map].
  factory QuestionAnsweredEvent.from(Map<String, dynamic> map) {
    return QuestionAnsweredEvent(
      surveyId: map[_surveyId] as String,
      questionId: map[_questionId] as String,
    );
  }

  /// The ID of the survey the answered question belongs to.
  final String surveyId;

  /// The ID of the question that was answered.
  final String questionId;
}
