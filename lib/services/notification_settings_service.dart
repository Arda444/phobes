import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsService {
  static final NotificationSettingsService instance =
      NotificationSettingsService._internal();

  factory NotificationSettingsService() {
    return instance;
  }

  NotificationSettingsService._internal();

  late SharedPreferences _prefs;

  // Notification types
  final ValueNotifier<bool> pushEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<bool> emailEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> teamInvitesEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<bool> taskRemindersEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<bool> dailyBriefingEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<bool> marketingEnabled = ValueNotifier<bool>(false);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    pushEnabled.value = _prefs.getBool('notify_push') ?? true;
    emailEnabled.value = _prefs.getBool('notify_email') ?? false;
    teamInvitesEnabled.value = _prefs.getBool('notify_teams') ?? true;
    taskRemindersEnabled.value = _prefs.getBool('notify_tasks') ?? true;
    dailyBriefingEnabled.value = _prefs.getBool('notify_briefing') ?? true;
    marketingEnabled.value = _prefs.getBool('notify_marketing') ?? false;
  }

  Future<void> setPushEnabled(bool enabled) async {
    pushEnabled.value = enabled;
    await _prefs.setBool('notify_push', enabled);
  }

  Future<void> setEmailEnabled(bool enabled) async {
    emailEnabled.value = enabled;
    await _prefs.setBool('notify_email', enabled);
  }

  Future<void> setTeamInvitesEnabled(bool enabled) async {
    teamInvitesEnabled.value = enabled;
    await _prefs.setBool('notify_teams', enabled);
  }

  Future<void> setTaskRemindersEnabled(bool enabled) async {
    taskRemindersEnabled.value = enabled;
    await _prefs.setBool('notify_tasks', enabled);
  }

  Future<void> setDailyBriefingEnabled(bool enabled) async {
    dailyBriefingEnabled.value = enabled;
    await _prefs.setBool('notify_briefing', enabled);
  }

  Future<void> setMarketingEnabled(bool enabled) async {
    marketingEnabled.value = enabled;
    await _prefs.setBool('notify_marketing', enabled);
  }
}
