import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModuleSettingsService {
  static final ModuleSettingsService instance =
      ModuleSettingsService._internal();

  factory ModuleSettingsService() {
    return instance;
  }

  ModuleSettingsService._internal();

  late SharedPreferences _prefs;

  final ValueNotifier<List<String>> disabledModules =
      ValueNotifier<List<String>>([]);
  final ValueNotifier<String> customNavButton = ValueNotifier<String>('teams');

  // Definitions of all toggleable modules
  static const List<Map<String, String>> availableModules = [
    {'id': 'budget', 'name': 'Bütçe Takip'},
    {'id': 'habit', 'name': 'Alışkanlıklar'},
    {'id': 'notes', 'name': 'Notlarım'},
    {'id': 'appointments', 'name': 'Randevular'},
    {'id': 'medications', 'name': 'İlaçlarım'},
    {'id': 'focus', 'name': 'Odaklanma'},
    {'id': 'upcoming', 'name': 'Yaklaşanlar'},
    {'id': 'statistics', 'name': 'İstatistikler'},
    {'id': 'teams', 'name': 'Ekipler'},
  ];

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    final savedDisabled = _prefs.getStringList('disabled_modules');
    if (savedDisabled != null) {
      disabledModules.value = savedDisabled;
    }

    final savedNavButton = _prefs.getString('custom_nav_button');
    if (savedNavButton != null) {
      customNavButton.value = savedNavButton;
    }
  }

  Future<void> setModuleDisabled(String moduleId, bool disabled) async {
    final List<String> currentList = List.from(disabledModules.value);

    if (disabled) {
      if (!currentList.contains(moduleId)) {
        currentList.add(moduleId);
      }

      // If the disabled module is currently the nav button, fallback to 'teams' or another available module
      if (customNavButton.value == moduleId) {
        await setCustomNavButton('teams');
      }
    } else {
      currentList.remove(moduleId);
    }

    disabledModules.value = currentList;
    await _prefs.setStringList('disabled_modules', currentList);
  }

  Future<void> setCustomNavButton(String moduleId) async {
    customNavButton.value = moduleId;
    await _prefs.setString(customNavButton.value, moduleId);
  }

  bool isModuleEnabled(String moduleId) {
    return !disabledModules.value.contains(moduleId);
  }
}
