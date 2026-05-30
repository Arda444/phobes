import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_service.dart';
import '../../main.dart';
import '../../l10n/app_localizations.dart';
import '../../core/app_locales.dart';
import '../../core/phobes_theme.dart';
import '../../widgets/phobes_widgets.dart';
import '../../core/page_transitions.dart';
import '../notifications/notifications_screen.dart';
import '../notifications/notification_preferences_screen.dart';
import '../settings/about_phobes_screen.dart';
import '../../services/module_settings_service.dart';
import 'widgets/account_settings_ui.dart';
import '../../services/user_data_export_service.dart';
import '../common/phobes_feature_tree_screen.dart';
import '../common/phobes_contact_screen.dart';
import '../common/legal_document_screen.dart';
import '../../core/legal_content.dart';

part 'account_screen_layout.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => AccountScreenState();
}

class AccountScreenState extends State<AccountScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isModulesExpanded = true;

  void toggleModulesExpanded() {
    setState(() => isModulesExpanded = !isModulesExpanded);
  }

  Future<void> _exportUserData() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await UserDataExportService.instance.exportAndShare();
      if (!mounted) return;
      PhobesSnackbar.show(
        context,
        message: l10n.backupReady,
        type: PhobesSnackbarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      PhobesSnackbar.show(
        context,
        message: '${l10n.exportFailed}: $e',
        type: PhobesSnackbarType.error,
      );
    }
  }

  final List<String> _avatarSeeds = [
    "Alex",
    "Jordan",
    "Taylor",
    "Morgan",
    "Casey",
    "Riley",
    "Jamie",
    "Skyler",
    "Cameron",
    "Avery",
    "Quinn",
    "Rowan",
    "Drew",
    "Peyton",
    "Reese",
    "Harper"
  ];

  void _showAvatarPicker() {
    final l10n = AppLocalizations.of(context)!;
    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(l10n.accountChooseAvatar,
                style: GoogleFonts.outfit(
                    fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, crossAxisSpacing: 12, mainAxisSpacing: 12),
              itemCount: _avatarSeeds.length,
              itemBuilder: (context, index) {
                final seed = _avatarSeeds[index];
                final url = "https://api.dicebear.com/9.x/micah/png?seed=$seed";
                return GestureDetector(
                  onTap: () async {
                    final navigator = Navigator.of(ctx);
                    await _firebaseService.updateAvatar(seed);
                    if (!context.mounted) return;
                    navigator.pop();
                    PhobesSnackbar.show(context,
                        message: l10n.profilePictureUpdated,
                        type: PhobesSnackbarType.success);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.1),
                          width: 2),
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: url,
                        placeholder: (_, __) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        errorWidget: (_, __, ___) => const Icon(Icons.error),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _editNameDialog(
      String currentName, String currentSurname) async {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: currentName);
    final surnameCtrl = TextEditingController(text: currentSurname);

    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.editInfoTitle,
                style: GoogleFonts.outfit(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            PhobesTextField(
              controller: nameCtrl,
              hintText: l10n.name,
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 12),
            PhobesTextField(
              controller: surnameCtrl,
              hintText: l10n.surname,
              prefixIcon: Icons.badge_outlined,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: PhobesButton(
                    text: l10n.cancel,
                    isOutlined: true,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PhobesButton(
                    text: l10n.save,
                    onPressed: () async {
                      final navigator = Navigator.of(ctx);
                      await _firebaseService.updateUserName(
                          nameCtrl.text.trim(), surnameCtrl.text.trim());
                      if (mounted) navigator.pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePasswordDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final passCtrl = TextEditingController();
    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.changePasswordTitle,
                style: GoogleFonts.outfit(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            PhobesTextField(
              controller: passCtrl,
              hintText: l10n.newPassword,
              prefixIcon: Icons.lock_outline,
              obscureText: true,
            ),
            const SizedBox(height: 24),
            PhobesButton(
              text: l10n.update,
              onPressed: () async {
                final navigator = Navigator.of(ctx);
                try {
                  await _auth.currentUser?.updatePassword(passCtrl.text.trim());
                  if (mounted) {
                    navigator.pop();
                    PhobesSnackbar.show(context,
                        message: l10n.passwordUpdated,
                        type: PhobesSnackbarType.success);
                  }
                } catch (e) {
                  if (mounted) {
                    PhobesSnackbar.show(context,
                        message: '${l10n.error}: $e',
                        type: PhobesSnackbarType.error);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeEmailDialog(String current) async {
    final l10n = AppLocalizations.of(context)!;
    final emailCtrl = TextEditingController(text: current);
    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.changeEmailTitle,
                style: GoogleFonts.outfit(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            PhobesTextField(
              controller: emailCtrl,
              hintText: l10n.newEmail,
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: 24),
            PhobesButton(
              text: l10n.requestConfirmation,
              onPressed: () async {
                final navigator = Navigator.of(ctx);
                try {
                  await _auth.currentUser
                      ?.verifyBeforeUpdateEmail(emailCtrl.text.trim());
                  if (mounted) {
                    navigator.pop();
                    PhobesSnackbar.show(context,
                        message: l10n.emailVerificationSent);
                  }
                } catch (e) {
                  if (mounted) {
                    PhobesSnackbar.show(context,
                        message: '${l10n.error}: $e',
                        type: PhobesSnackbarType.error);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await PhobesBottomSheet.confirm(
      context: context,
      title: l10n.signOut,
      message: l10n.signOutConfirmation,
      confirmText: l10n.signOut,
      confirmColor: Colors.redAccent,
    );
    if (confirmed == true && mounted) {
      await _auth.signOut();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await PhobesBottomSheet.confirm(
      context: context,
      title: l10n.deleteAccount,
      message: l10n.deleteAccountConfirmation,
      confirmText: l10n.deletePermanently,
      cancelText: l10n.cancel,
      confirmColor: Colors.red,
    );
    if (confirmed == true && mounted) {
      try {
        await _authService.deleteAccount();
        if (mounted) {
          context.go('/login');
          PhobesSnackbar.show(context,
              message: l10n.accountDeleted,
              type: PhobesSnackbarType.success);
        }
      } catch (e) {
        if (mounted) {
          PhobesSnackbar.show(context,
              message: '${l10n.error}: $e', type: PhobesSnackbarType.error);
        }
      }
    }
  }

  Future<void> _showClearDataDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await PhobesBottomSheet.confirm(
      context: context,
      title: l10n.clearData,
      message: l10n.clearDataConfirmation,
      confirmText: l10n.clearData,
      confirmColor: Colors.orange,
    );
    if (confirmed == true && mounted) {
      try {
        await _authService.clearAllUserData();
        if (!mounted) return;
        PhobesSnackbar.show(context,
            message: l10n.dataCleared,
            type: PhobesSnackbarType.success);
      } catch (e) {
        if (!mounted) return;
        PhobesSnackbar.show(context,
            message: '${l10n.error}: $e', type: PhobesSnackbarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmoled = PhobesTheme.amoledMode.value;

    return Scaffold(
      backgroundColor: isAmoled && isDark ? Colors.black : cs.surface,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: _firebaseService.getUserDataStream(),
          builder: (context, snapshot) {
            String name = l10n.loading, email = "", birthDate = "";
            String? photoUrl;
            int xp = 0, level = 1;

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              name = "${data['name'] ?? ''} ${data['surname'] ?? ''}";
              email = data['email'] ?? "";
              photoUrl = data['photoUrl'];
              xp = data['xp'] ?? 0;
              level = data['level'] ?? 1;
              if (data['birthDate'] != null) {
                birthDate = DateFormat('d MMMM yyyy', l10n.localeName)
                    .format((data['birthDate'] as Timestamp).toDate());
              }
            } else if (_auth.currentUser != null) {
              email = _auth.currentUser!.email ?? "";
              photoUrl = _auth.currentUser!.photoURL;
            }

            return AccountSettingsUi.pageBackground(
              cs,
              child: buildAccountScreenLayout(
                context,
                host: this,
                l10n: l10n,
                cs: cs,
                name: name,
                email: email,
                birthDate: birthDate,
                photoUrl: photoUrl,
                xp: xp,
                level: level,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAuthSettings(BuildContext context, String name, String email) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        _buildSettingTile(
            icon: Icons.person_outline_rounded,
            title: l10n.editProfile,
            subtitle: name,
            color: Colors.blueAccent,
            onTap: () => _editNameDialog(name.split(" ")[0],
                name.split(" ").length > 1 ? name.split(" ")[1] : ""),
            cs: cs,
          ),
          AccountSettingsUi.rowDivider(cs),
          _buildSettingTile(
            icon: Icons.email_outlined,
            title: l10n.email,
            subtitle: email,
            color: Colors.teal,
            onTap: () => _changeEmailDialog(email),
            cs: cs,
          ),
          AccountSettingsUi.rowDivider(cs),
          _buildSettingTile(
            icon: Icons.lock_outline_rounded,
            title: l10n.securityAndPrivacy,
            subtitle: l10n.passwordSecuritySubtitle,
            color: Colors.orange,
            onTap: _changePasswordDialog,
            cs: cs,
          ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required ValueListenable<bool> listenable,
    required Function(bool) onChanged,
    required ColorScheme cs,
  }) {
    return AccountSettingsUi.switchRow(
      cs: cs,
      icon: icon,
      title: title,
      subtitle: subtitle,
      color: color,
      listenable: listenable,
      onChanged: onChanged,
    );
  }

  Future<void> _showSimulateDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final confirmed = await PhobesBottomSheet.confirm(
      context: context,
      title: l10n.simulateStartTitle,
      message: l10n.simulateStartMessage,
    );
    if (confirmed != true) return;
    final progressController = StreamController<double>();
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StreamBuilder<double>(
          stream: progressController.stream,
          initialData: 0.0,
          builder: (context, snapshot) {
            double p = snapshot.data ?? 0.0;
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: PhobesCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PhobesLoadingIndicator(),
                    const SizedBox(height: 20),
                    Text(l10n.simulatePreparing,
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                        value: p,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(cs.primary)),
                    const SizedBox(height: 10),
                    Text("%${(p * 100).toInt()}",
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w500, color: cs.primary)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    try {
      await _firebaseService.generateFullTestEnvironment(
          onProgress: (p) => progressController.add(p));
    } finally {
      progressController.close();
    }
    if (!context.mounted) return;
    Navigator.pop(context);
    PhobesSnackbar.show(context,
        message: l10n.allSystemsSynced,
        type: PhobesSnackbarType.success);
  }

  Widget _buildLanguageSelector(BuildContext context, AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    final currentCode =
        MyApp.of(context)?.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    final localeValue = localeOptionForCode(currentCode)?.locale ??
        const Locale('en');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          AccountSettingsUi.rowIcon(
            icon: Icons.translate_rounded,
            color: cs.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.language,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<Locale>(
              value: localeValue,
              dropdownColor: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              isDense: true,
              items: [
                for (final option in kAppLocaleOptions)
                  DropdownMenuItem(
                    value: option.locale,
                    child: Text(
                      option.nativeLabel,
                      style: GoogleFonts.outfit(fontSize: 13),
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v != null) MyApp.of(context)?.setLocale(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSettings(BuildContext context) {
    return AccountSettingsUi.themePanel(context);
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required ColorScheme cs,
    bool isDanger = false,
    Widget? trailing,
  }) {
    return AccountSettingsUi.actionRow(
      cs: cs,
      icon: icon,
      title: title,
      subtitle: subtitle,
      color: color,
      onTap: onTap,
      isDanger: isDanger,
      trailing: trailing,
    );
  }
}
