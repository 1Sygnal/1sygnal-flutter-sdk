import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:onesygnal/onesygnal.dart';
import 'app.dart';

// Prints one tagged line per host-facing SDK event so the device E2E harness can tail it via
// `adb logcat` (Android) or the iOS log stream — `debugPrint` reliably reaches both.
void _logE2eEvent(String eventName, {String? surveyId, String? questionId}) {
  final payload = jsonEncode({
    'event': eventName,
    'surveyId': surveyId,
    'questionId': questionId,
  });
  debugPrint('ONESYGNAL_E2E_EVENT $payload');
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Registered before initialize() is ever called — addEventListener() just subscribes to the
  // event stream, it doesn't require the SDK to already be running. Events start arriving once
  // Initialize SDK is tapped on the Profile screen.
  OneSygnal().addEventListener(
    OneSygnalEventListener(
      onReady: () {
        debugPrint('[OneSygnal] SDK ready');
        _logE2eEvent('ready');
      },
      onSurveyShown: (e) {
        debugPrint('[OneSygnal] Survey shown: ${e.surveyId}');
        _logE2eEvent('survey:shown', surveyId: e.surveyId);
      },
      onSurveyCompleted: (e) {
        debugPrint('[OneSygnal] Survey completed: ${e.surveyId}');
        _logE2eEvent('survey:completed', surveyId: e.surveyId);
      },
      onSurveyDismissed: (e) {
        debugPrint('[OneSygnal] Survey dismissed: ${e.surveyId}');
        _logE2eEvent('survey:dismissed', surveyId: e.surveyId);
      },
      onQuestionAnswered: (e) {
        debugPrint(
          '[OneSygnal] Question answered: ${e.questionId} (survey ${e.surveyId})',
        );
        _logE2eEvent(
          'survey:question_answered',
          surveyId: e.surveyId,
          questionId: e.questionId,
        );
      },
    ),
  );

  runApp(const OneSygnalExampleApp());
}
