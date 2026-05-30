part of 'account_screen.dart';

enum _AccountLayoutMode { narrow, dual, wide }

/// Web [wide]: iki eşit sütun + modüller tam genişlik (orta sütun daraltmaz).
_AccountLayoutMode _layoutMode(double width) {
  if (kIsWeb && width >= 880) return _AccountLayoutMode.wide;
  if (width >= 760) return _AccountLayoutMode.dual;
  return _AccountLayoutMode.narrow;
}

Widget buildAccountScreenLayout(
  BuildContext context, {
  required AccountScreenState host,
  required AppLocalizations l10n,
  required ColorScheme cs,
  required String name,
  required String email,
  required String birthDate,
  required String? photoUrl,
  required int xp,
  required int level,
}) {
  final enabledCount = ModuleSettingsService.appModules.length -
      ModuleSettingsService.instance.disabledModules.value.length;

  Widget topActions = Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      StreamBuilder<int>(
        stream: host._firebaseService.getUnreadNotificationCount(),
        builder: (context, snap) {
          final count = snap.data ?? 0;
          return PhobesIconButton(
            icon: count > 0
                ? Icons.notifications_active_rounded
                : Icons.notifications_none_rounded,
            badgeCount: count,
            onTap: () => PhobesPageRoute.pushResponsive(
              context,
              const NotificationsScreen(),
            ),
          );
        },
      ),
      const SizedBox(width: 8),
      PhobesIconButton(
        icon: Icons.logout_rounded,
        color: cs.error,
        backgroundColor: cs.error.withValues(alpha: 0.1),
        onTap: host._signOut,
      ),
    ],
  );

  Widget authSection(String n, String e) => AccountSettingsUi.section(
        title: l10n.accountSectionSecurity,
        icon: Icons.shield_outlined,
        cs: cs,
        child: host._buildAuthSettings(context, n, e),
      );

  Widget modulesSection() => ValueListenableBuilder<List<String>>(
        valueListenable: ModuleSettingsService.instance.disabledModules,
        builder: (context, disabled, _) {
          return ValueListenableBuilder<String>(
            valueListenable: ModuleSettingsService.instance.customNavButton,
            builder: (context, navBtn, __) {
              return AccountSettingsUi.modulesPanel(
                l10n: AppLocalizations.of(context)!,
                cs: cs,
                disabledModules: disabled,
                customNavButton: navBtn,
                expanded: host.isModulesExpanded,
                onToggleExpanded: host.toggleModulesExpanded,
                onModuleToggle: (id, isCurrentlyEnabled) =>
                    ModuleSettingsService.instance.setModuleDisabled(
                  id,
                  isCurrentlyEnabled,
                ),
                onNavButtonChanged: (id) =>
                    ModuleSettingsService.instance.setCustomNavButton(id),
              );
            },
          );
        },
      );

  Widget appearanceSection() => AccountSettingsUi.section(
        title: l10n.accountSectionAppearance,
        icon: Icons.palette_outlined,
        cs: cs,
        child: host._buildThemeSettings(context),
      );

  Widget appSection() => AccountSettingsUi.section(
        title: l10n.accountSectionApp,
        icon: Icons.info_outline_rounded,
        cs: cs,
        child: Column(
          children: [
            host._buildSettingTile(
              icon: Icons.auto_awesome_rounded,
              title: l10n.aboutPhobesTitle,
              subtitle: l10n.aboutPhobesVisionSubtitle,
              color: cs.primary,
              onTap: () => PhobesPageRoute.pushResponsive(
                context,
                const AboutPhobesScreen(),
                isCentered: true,
              ),
              cs: cs,
            ),
            AccountSettingsUi.rowDivider(cs),
            host._buildSettingTile(
              icon: Icons.account_tree_rounded,
              title: l10n.featureTreeTitleLabel,
              subtitle: l10n.featureTreeAllModulesSubtitle,
              color: Colors.blueAccent,
              onTap: () => PhobesPageRoute.pushResponsive(
                context,
                const PhobesFeatureTreeScreen(),
                isCentered: true,
              ),
              cs: cs,
            ),
            AccountSettingsUi.rowDivider(cs),
            host._buildSettingTile(
              icon: Icons.contact_support_rounded,
              title: l10n.contactSupport,
              subtitle: l10n.contactGetHelpSubtitle,
              color: Colors.green,
              onTap: () => PhobesPageRoute.pushResponsive(
                context,
                const PhobesContactScreen(),
                isCentered: true,
              ),
              cs: cs,
            ),
            AccountSettingsUi.rowDivider(cs),
            host._buildSettingTile(
              icon: Icons.privacy_tip_outlined,
              title: l10n.privacyPolicy,
              subtitle: l10n.yourDataYourFortress,
              color: Colors.teal,
              onTap: () => PhobesPageRoute.pushResponsive(
                context,
                const LegalDocumentScreen(type: LegalDocumentType.privacy),
                isCentered: true,
              ),
              cs: cs,
            ),
            AccountSettingsUi.rowDivider(cs),
            host._buildSettingTile(
              icon: Icons.gavel_outlined,
              title: l10n.termsOfService,
              subtitle: l10n.legalLastUpdated,
              color: Colors.blueGrey,
              onTap: () => PhobesPageRoute.pushResponsive(
                context,
                const LegalDocumentScreen(type: LegalDocumentType.terms),
                isCentered: true,
              ),
              cs: cs,
            ),
          ],
        ),
      );

  Widget dataSection() => AccountSettingsUi.section(
        title: l10n.accountSectionData,
        icon: Icons.storage_rounded,
        cs: cs,
        child: Column(
          children: [
            host._buildSettingTile(
              icon: Icons.notifications_outlined,
              title: l10n.accountNotificationSettings,
              subtitle: l10n.accountNotificationSettingsSubtitle,
              color: Colors.blueAccent,
              onTap: () => PhobesPageRoute.pushResponsive(
                context,
                const NotificationPreferencesScreen(),
              ),
              cs: cs,
            ),
            if (kIsWeb) AccountSettingsUi.rowDivider(cs),
            if (kIsWeb)
              host._buildSwitchTile(
                icon: Icons.wb_sunny_outlined,
                title: l10n.weatherPanelTitle,
                subtitle: l10n.weatherPanelSubtitle,
                color: Colors.amber,
                listenable:
                    ModuleSettingsService.instance.intelligencePanelEnabled,
                onChanged: (v) => ModuleSettingsService.instance
                    .setIntelligencePanelEnabled(v),
                cs: cs,
              ),
            AccountSettingsUi.rowDivider(cs),
            host._buildSettingTile(
              icon: Icons.science_rounded,
              title: l10n.testData,
              subtitle: l10n.simulateTestDataSubtitle,
              color: Colors.green,
              onTap: () => host._showSimulateDialog(context),
              cs: cs,
            ),
            AccountSettingsUi.rowDivider(cs),
            host._buildSettingTile(
              icon: Icons.upload_file_rounded,
              title: l10n.backupExportData,
              subtitle: l10n.backupExportSubtitle,
              color: cs.primary,
              onTap: host._exportUserData,
              cs: cs,
            ),
            AccountSettingsUi.rowDivider(cs),
            host._buildSettingTile(
              icon: Icons.delete_sweep_rounded,
              title: l10n.clearAllData,
              subtitle: l10n.clearLocalDataSubtitle,
              color: Colors.orange,
              onTap: host._showClearDataDialog,
              cs: cs,
            ),
            AccountSettingsUi.rowDivider(cs),
            host._buildSettingTile(
              icon: Icons.delete_forever_rounded,
              title: l10n.deleteAccount,
              subtitle: l10n.permanentActionSubtitle,
              color: cs.error,
              onTap: host._showDeleteAccountDialog,
              isDanger: true,
              cs: cs,
            ),
            AccountSettingsUi.rowDivider(cs),
            host._buildLanguageSelector(context, l10n),
          ],
        ),
      );

  Widget settingsBody(_AccountLayoutMode mode, String n, String e) {
    switch (mode) {
      case _AccountLayoutMode.wide:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      authSection(n, e),
                      dataSection(),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      appearanceSection(),
                      appSection(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            modulesSection(),
          ],
        );
      case _AccountLayoutMode.dual:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      authSection(n, e),
                      dataSection(),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      appearanceSection(),
                      appSection(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            modulesSection(),
          ],
        );
      case _AccountLayoutMode.narrow:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            authSection(n, e),
            dataSection(),
            appearanceSection(),
            appSection(),
            modulesSection(),
          ],
        );
    }
  }

  return LayoutBuilder(
    builder: (context, constraints) {
      final mode = _layoutMode(constraints.maxWidth);
      final compactBanner = constraints.maxWidth < 600;
      const horizontalPad = kIsWeb ? 24.0 : 0.0;
      final maxW = kIsWeb ? constraints.maxWidth : 1120.0;

      final scroll = CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: AccountSettingsUi.topBar(
              context: context,
              title: l10n.accountAndSettings,
              cs: cs,
              trailing: topActions,
            ),
          ),
          SliverToBoxAdapter(
            child: FadeInDown(
              child: AccountSettingsUi.profileBanner(
                context: context,
                cs: cs,
                displayName: name,
                email: email,
                birthDate: birthDate,
                photoUrl: photoUrl,
                xp: xp,
                level: level,
                enabledModules: enabledCount,
                totalModules: ModuleSettingsService.appModules.length,
                onEditPhoto: host._showAvatarPicker,
                compact: compactBanner,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(horizontalPad, 0, horizontalPad, 48),
            sliver: SliverToBoxAdapter(
              child: settingsBody(mode, name, email),
            ),
          ),
          SliverToBoxAdapter(child: AccountSettingsUi.footer(cs)),
        ],
      );

      if (kIsWeb) {
        return scroll;
      }

      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: scroll,
        ),
      );
    },
  );
}
