class AnalyticsEvents {
  // Core app events
  static const String appOpen = 'app_open';
  static const String appFirstOpen = 'app_first_open';
  static const String appBackgrounded = 'app_backgrounded';
  static const String appForegrounded = 'app_foregrounded';
  
  // Onboarding events
  static const String onboardingStart = 'onboarding_start';
  static const String onboardingComplete = 'onboarding_complete';
  static const String onboardingSkipped = 'onboarding_skipped';
  static const String onboardingStepViewed = 'onboarding_step_viewed';
  
  // Theme events
  static const String themeSelected = 'theme_selected';
  static const String themePreviewViewed = 'theme_preview_viewed';
  static const String themeChanged = 'theme_changed';
  
  // Voice interaction events
  static const String questionAsked = 'question_asked';
  static const String ttsSpoken = 'tts_spoken';
  static const String speechRecognitionStarted = 'speech_recognition_started';
  static const String speechRecognitionSuccess = 'speech_recognition_success';
  static const String speechRecognitionError = 'speech_recognition_error';
  static const String hotwordDetected = 'hotword_detected';
  static const String voiceInterrupted = 'voice_interrupted';
  
  // LLM provider events
  static const String modelAutoSwitch = 'model_auto_switch';
  static const String modelManualSwitch = 'model_manual_switch';
  static const String providerRequestStarted = 'provider_request_started';
  static const String providerRequestSuccess = 'provider_request_success';
  static const String providerRequestFailed = 'provider_request_failed';
  static const String providerKeyAdded = 'provider_key_added';
  static const String providerKeyTested = 'provider_key_tested';
  static const String providerKeyRemoved = 'provider_key_removed';
  static const String fallbackModelUsed = 'fallback_model_used';
  
  // Family sharing events
  static const String familyInviteCreated = 'family_invite_created';
  static const String familyInviteShared = 'family_invite_shared';
  static const String familyInviteJoined = 'family_invite_joined';
  static const String familyInviteFailed = 'family_invite_failed';
  static const String familyMemberAdded = 'family_member_added';
  static const String familyMemberRemoved = 'family_member_removed';
  static const String familyListViewed = 'family_list_viewed';
  
  // Error events
  static const String errorOccurred = 'error_occurred';
  static const String networkError = 'network_error';
  static const String crashOccurred = 'crash_occurred';
  static const String apiError = 'api_error';
  static const String authError = 'auth_error';
  
  // Feature usage events
  static const String featureUsed = 'feature_used';
  static const String settingsOpened = 'settings_opened';
  static const String helpViewed = 'help_viewed';
  static const String aboutViewed = 'about_viewed';
  static const String debugMenuOpened = 'debug_menu_opened';
  
  // Performance events
  static const String appLaunchTime = 'app_launch_time';
  static const String responseTime = 'response_time';
  static const String animationPerformance = 'animation_performance';
  
  // User preference events
  static const String preferenceChanged = 'preference_changed';
  static const String accessibilityFeatureUsed = 'accessibility_feature_used';
  static const String motionPreferenceChanged = 'motion_preference_changed';
  
  // Common event parameters
  static const String paramFeatureName = 'feature_name';
  static const String paramThemeId = 'theme_id';
  static const String paramProvider = 'provider';
  static const String paramErrorType = 'error_type';
  static const String paramErrorMessage = 'error_message';
  static const String paramWordCount = 'word_count';
  static const String paramDuration = 'duration';
  static const String paramFromModel = 'from_model';
  static const String paramToModel = 'to_model';
  static const String paramReason = 'reason';
  static const String paramMemberName = 'member_name';
  static const String paramInviteMethod = 'invite_method';
  static const String paramResponseTimeMs = 'response_time_ms';
  static const String paramStepNumber = 'step_number';
  static const String paramPreferenceName = 'preference_name';
  static const String paramPreferenceValue = 'preference_value';
}