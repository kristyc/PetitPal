enum AnalyticsEvent {
  app_open,
  app_first_open,
  onboarding_start,
  onboarding_theme_selected,
  onboarding_provider_saved,
  onboarding_invite_joined,
  onboarding_complete,
  voice_activation_started,
  question_asked,
  tts_spoken,
  interaction_completed,
  speech_recognition_error,
  provider_request_failed,
  family_member_invited,
  family_invite_joined,
}

extension AnalyticsEventName on AnalyticsEvent {
  String get name => toString().split('.').last;
}
