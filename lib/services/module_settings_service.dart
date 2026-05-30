import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Toggleable app module metadata (sidebar + life menu).
class AppModuleSetting {
  const AppModuleSetting({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.navShortcutEligible = true,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;

  /// Shown in "Hızlı Erişim Butonu" dropdown (mobile bottom bar).
  final bool navShortcutEligible;
}

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
  final ValueNotifier<bool> sidebarCollapsed = ValueNotifier<bool>(false);
  final ValueNotifier<bool> intelligencePanelEnabled = ValueNotifier<bool>(true);

  static const List<AppModuleSetting> appModules = [
    AppModuleSetting(
      id: 'calendar',
      name: 'Takvim',
      icon: Icons.calendar_month_rounded,
      color: Color(0xFF6366F1),
      navShortcutEligible: false,
    ),
    AppModuleSetting(
      id: 'teams',
      name: 'Ekipler',
      icon: Icons.groups_2_rounded,
      color: Color(0xFF3B82F6),
    ),
    AppModuleSetting(
      id: 'chat',
      name: 'Nova Asistan',
      icon: Icons.auto_awesome,
      color: Color(0xFF8B5CF6),
      navShortcutEligible: false,
    ),
    AppModuleSetting(
      id: 'habit',
      name: 'Alışkanlıklar',
      icon: Icons.spa_rounded,
      color: Color(0xFF10B981),
    ),
    AppModuleSetting(
      id: 'focus',
      name: 'Odaklanma',
      icon: Icons.timelapse_rounded,
      color: Color(0xFFF97316),
    ),
    AppModuleSetting(
      id: 'budget',
      name: 'Bütçe Takip',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFFF59E0B),
    ),
    AppModuleSetting(
      id: 'appointments',
      name: 'Randevular',
      icon: Icons.event_available_rounded,
      color: Color(0xFF06B6D4),
    ),
    AppModuleSetting(
      id: 'notes',
      name: 'Notlarım',
      icon: Icons.note_alt_rounded,
      color: Color(0xFF6366F1),
    ),
    AppModuleSetting(
      id: 'medications',
      name: 'İlaçlarım',
      icon: Icons.medication_rounded,
      color: Color(0xFF14B8A6),
    ),
    AppModuleSetting(
      id: 'upcoming',
      name: 'Yaklaşanlar',
      icon: Icons.upcoming_rounded,
      color: Color(0xFFEC4899),
    ),
    AppModuleSetting(
      id: 'statistics',
      name: 'İstatistikler',
      icon: Icons.insights_rounded,
      color: Color(0xFFA855F7),
    ),
    AppModuleSetting(
      id: 'corkboard',
      name: 'Kişisel Pano',
      icon: Icons.dashboard_customize_rounded,
      color: Color(0xFF7C3AED),
    ),
    AppModuleSetting(
      id: 'books',
      name: 'Kitaplarım',
      icon: Icons.menu_book_rounded,
      color: Color(0xFFD97706),
    ),
  ];

  /// Legacy shape for callers expecting maps.
  static List<Map<String, String>> get availableModules => appModules
      .map((m) => {'id': m.id, 'name': m.name})
      .toList(growable: false);

  static AppModuleSetting? findModule(String id) {
    for (final m in appModules) {
      if (m.id == id) return m;
    }
    return null;
  }

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

    sidebarCollapsed.value = _prefs.getBool('sidebar_collapsed') ?? false;
    intelligencePanelEnabled.value =
        _prefs.getBool('intelligence_panel_enabled') ?? true;
  }

  Future<void> setSidebarCollapsed(bool collapsed) async {
    sidebarCollapsed.value = collapsed;
    await _prefs.setBool('sidebar_collapsed', collapsed);
  }

  Future<void> setIntelligencePanelEnabled(bool enabled) async {
    intelligencePanelEnabled.value = enabled;
    await _prefs.setBool('intelligence_panel_enabled', enabled);
  }

  Future<void> setModuleDisabled(String moduleId, bool disabled) async {
    final List<String> currentList = List.from(disabledModules.value);

    if (disabled) {
      if (!currentList.contains(moduleId)) {
        currentList.add(moduleId);
      }

      if (customNavButton.value == moduleId) {
        final fallback = appModules
            .firstWhere(
              (m) => m.navShortcutEligible && !currentList.contains(m.id),
              orElse: () => appModules.firstWhere((m) => m.id == 'teams'),
            )
            .id;
        await setCustomNavButton(fallback);
      }
    } else {
      currentList.remove(moduleId);
    }

    disabledModules.value = currentList;
    await _prefs.setStringList('disabled_modules', currentList);
  }

  Future<void> setCustomNavButton(String moduleId) async {
    customNavButton.value = moduleId;
    await _prefs.setString('custom_nav_button', moduleId);
  }

  bool isModuleEnabled(String moduleId) {
    return !disabledModules.value.contains(moduleId);
  }

  int get enabledModuleCount =>
      appModules.length - disabledModules.value.length;
}
