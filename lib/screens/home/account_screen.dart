import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/firebase_service.dart';
import '../../main.dart';
import '../../l10n/app_localizations.dart';
import '../../core/phobes_theme.dart';
import '../../widgets/phobes_widgets.dart';
import '../../core/page_transitions.dart';
import '../notifications/notifications_screen.dart';
import '../settings/about_phobes_screen.dart';
import '../../services/module_settings_service.dart';
import '../../services/notification_settings_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isModulesExpanded = false;

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
    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text("Karakter Seç",
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
                        message: "Profil resmi güncellendi! 😎",
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
    final nameCtrl = TextEditingController(text: currentName);
    final surnameCtrl = TextEditingController(text: currentSurname);

    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Bilgileri Düzenle",
                style: GoogleFonts.outfit(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            PhobesTextField(
              controller: nameCtrl,
              hintText: "Ad",
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 12),
            PhobesTextField(
              controller: surnameCtrl,
              hintText: "Soyad",
              prefixIcon: Icons.badge_outlined,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: PhobesButton(
                    text: "İptal",
                    isOutlined: true,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PhobesButton(
                    text: "Kaydet",
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
    final passCtrl = TextEditingController();
    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Şifre Değiştir",
                style: GoogleFonts.outfit(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            PhobesTextField(
              controller: passCtrl,
              hintText: "Yeni Şifre",
              prefixIcon: Icons.lock_outline,
              obscureText: true,
            ),
            const SizedBox(height: 24),
            PhobesButton(
              text: "Güncelle",
              onPressed: () async {
                final navigator = Navigator.of(ctx);
                try {
                  await _auth.currentUser?.updatePassword(passCtrl.text.trim());
                  if (mounted) {
                    navigator.pop();
                    PhobesSnackbar.show(context,
                        message: "Şifre başarıyla güncellendi",
                        type: PhobesSnackbarType.success);
                  }
                } catch (e) {
                  if (mounted) {
                    PhobesSnackbar.show(context,
                        message: "Hata: $e", type: PhobesSnackbarType.error);
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
    final emailCtrl = TextEditingController(text: current);
    PhobesBottomSheet.show(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("E-posta Değiştir",
                style: GoogleFonts.outfit(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            PhobesTextField(
              controller: emailCtrl,
              hintText: "Yeni E-posta",
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: 24),
            PhobesButton(
              text: "Onay İste",
              onPressed: () async {
                final navigator = Navigator.of(ctx);
                try {
                  await _auth.currentUser
                      ?.verifyBeforeUpdateEmail(emailCtrl.text.trim());
                  if (mounted) {
                    navigator.pop();
                    PhobesSnackbar.show(context,
                        message: "Onay postası gönderildi",
                        type: PhobesSnackbarType.info);
                  }
                } catch (e) {
                  if (mounted) {
                    PhobesSnackbar.show(context,
                        message: "Hata: $e", type: PhobesSnackbarType.error);
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
    final confirmed = await PhobesBottomSheet.confirm(
      context: context,
      title: "Çıkış Yap",
      message: "Oturumu kapatmak istediğinize emin misiniz?",
      confirmText: "Çıkış Yap",
      cancelText: "İptal",
      confirmColor: Colors.redAccent,
    );
    if (confirmed == true && mounted) {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final confirmed = await PhobesBottomSheet.confirm(
      context: context,
      title: "Hesabı Sil",
      message:
          "Hesabınızı ve tüm verilerinizi kalıcı olarak silmek istediğinize emin misiniz? Bu işlem geri alınamaz.",
      confirmText: "Kalıcı Olarak Sil",
      cancelText: "Vazgeç",
      confirmColor: Colors.red,
    );
    if (confirmed == true && mounted) {
      try {
        await _firebaseService.deleteAllData();
        await _auth.currentUser?.delete();
        if (mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (route) => false);
          PhobesSnackbar.show(context,
              message: "Hesabınız başarıyla silindi",
              type: PhobesSnackbarType.success);
        }
      } catch (e) {
        if (mounted) {
          PhobesSnackbar.show(context,
              message: "Hata: $e", type: PhobesSnackbarType.error);
        }
      }
    }
  }

  Future<void> _showClearDataDialog() async {
    final confirmed = await PhobesBottomSheet.confirm(
      context: context,
      title: "Verileri Temizle",
      message: "Tüm görevleriniz ve ayarlarınız silinecek. Emin misiniz?",
      confirmText: "Verileri Sil",
      cancelText: "İptal",
      confirmColor: Colors.orange,
    );
    if (confirmed == true && mounted) {
      try {
        await _firebaseService.deleteAllData();
        if (!mounted) return;
        PhobesSnackbar.show(context,
            message: "Tüm veriler temizlendi",
            type: PhobesSnackbarType.success);
      } catch (e) {
        if (!mounted) return;
        PhobesSnackbar.show(context,
            message: "Hata: $e", type: PhobesSnackbarType.error);
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
            String name = "Yükleniyor...", email = "", birthDate = "";
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
                birthDate = DateFormat('d MMMM yyyy', 'tr')
                    .format((data['birthDate'] as Timestamp).toDate());
              }
            } else if (_auth.currentUser != null) {
              email = _auth.currentUser!.email ?? "";
              photoUrl = _auth.currentUser!.photoURL;
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 48, 0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l10n.accountAndSettings,
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 26,
                                    color: cs.onSurface)),
                            Row(
                              children: [
                                StreamBuilder<int>(
                                  stream: _firebaseService
                                      .getUnreadNotificationCount(),
                                  builder: (context, snap) {
                                    final count = snap.data ?? 0;
                                    return PhobesIconButton(
                                      icon: count > 0
                                          ? Icons.notifications_active_rounded
                                          : Icons.notifications_none_rounded,
                                      badgeCount: count,
                                      onTap: () =>
                                          PhobesPageRoute.pushResponsive(
                                              context,
                                              const NotificationsScreen()),
                                    );
                                  },
                                ),
                                const SizedBox(width: 10),
                                PhobesIconButton(
                                  icon: Icons.logout_rounded,
                                  color: cs.error,
                                  backgroundColor:
                                      cs.error.withValues(alpha: 0.1),
                                  onTap: _signOut,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        FadeInDown(
                          child: PhobesGlassCard(
                            padding: const EdgeInsets.all(24),
                            margin: EdgeInsets.zero,
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: _showAvatarPicker,
                                  child: Stack(
                                    children: [
                                      PhobesAvatar(
                                          imageUrl: photoUrl,
                                          name: name,
                                          size: 90),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                              color: cs.primary,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.2),
                                                    blurRadius: 5)
                                              ]),
                                          child: Icon(Icons.camera_alt,
                                              size: 16, color: cs.onPrimary),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(name,
                                    style: GoogleFonts.outfit(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: cs.onSurface)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: cs.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Text("Seviye $level • $xp XP",
                                      style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: cs.primary,
                                          fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(height: 8),
                                Text(email,
                                    style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: cs.onSurface
                                            .withValues(alpha: 0.6))),
                                if (birthDate.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text("Doğum Tarihi: $birthDate",
                                      style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color: cs.onSurface
                                              .withValues(alpha: 0.4))),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildSectionHeader(context, "Bildirim Tercihleri"),
                      _buildNotificationSettings(context),
                      _buildSectionHeader(context, "Erişim ve Güvenlik"),
                      _buildAuthSettings(context, name, email),
                      _buildSectionHeader(context, "Görünüm ve Tema"),
                      _buildThemeSettings(context),
                      _buildSectionHeader(context, "Uygulama Bilgileri"),
                      PhobesCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _buildSettingTile(
                              icon: Icons.auto_awesome_rounded,
                              title: "Phobes Hakkında",
                              subtitle: "Vizyonumuz ve kurumsal hikayemiz",
                              color: cs.primary,
                              onTap: () => PhobesPageRoute.pushResponsive(
                                  context, const AboutPhobesScreen(),
                                  isCentered: true),
                              cs: cs,
                            ),
                            _buildSettingTile(
                              icon: Icons.account_tree_rounded,
                              title: "Özellik Ağacı",
                              subtitle: "Phobes modüllerini keşfedin",
                              color: Colors.blueAccent,
                              onTap: () => PhobesPageRoute.pushResponsive(
                                  context, const PhobesFeatureTreeScreen(),
                                  isCentered: true),
                              cs: cs,
                            ),
                            _buildSettingTile(
                              icon: Icons.contact_support_rounded,
                              title: "İletişim ve Destek",
                              subtitle: "Bize ulaşın ve yardım alın",
                              color: Colors.green,
                              onTap: () => PhobesPageRoute.pushResponsive(
                                  context, const PhobesContactScreen(),
                                  isCentered: true),
                              cs: cs,
                            ),
                          ],
                        ),
                      ),
                      _buildSectionHeader(context, "Uygulama ve Modüller"),
                      _buildModuleSettings(context),
                      _buildSectionHeader(context, "Dil ve Veri Yönetimi"),
                      PhobesCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _buildLanguageSelector(context, l10n),
                            const Divider(indent: 56),
                            _buildSettingTile(
                              icon: Icons.science_rounded,
                              title: "3 Aylık Full Test Sistemi",
                              subtitle: "Tüm uygulamayı senkronize eder",
                              color: Colors.green,
                              onTap: () => _showSimulateDialog(context),
                              cs: cs,
                            ),
                            const Divider(indent: 56),
                            _buildSettingTile(
                              icon: Icons.delete_sweep_rounded,
                              title: l10n.clearAllData,
                              subtitle: "Tüm verileri siler",
                              color: Colors.orange,
                              onTap: _showClearDataDialog,
                              cs: cs,
                            ),
                            const Divider(indent: 56),
                            _buildSettingTile(
                              icon: Icons.delete_forever_rounded,
                              title: "Hesabı Sil",
                              subtitle: "Kalıcı olarak kapatır",
                              color: cs.error,
                              onTap: _showDeleteAccountDialog,
                              isDanger: true,
                              cs: cs,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Center(
                        child: Column(children: [
                          Text("Phobes v1.2.5-modern",
                              style: GoogleFonts.jetBrainsMono(
                                  color: cs.onSurface.withValues(alpha: 0.2),
                                  fontSize: 10)),
                          const SizedBox(height: 8),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.code, size: 12, color: cs.primary),
                                const SizedBox(width: 4),
                                Text("Powered by Techluna Software",
                                    style: GoogleFonts.outfit(
                                        color:
                                            cs.primary.withValues(alpha: 0.5),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ]),
                        ]),
                      ),
                      const SizedBox(height: 80),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 32, 4, 12),
      child: Text(title.toUpperCase(),
          style: GoogleFonts.outfit(
              color: cs.primary.withValues(alpha: 0.6),
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1.5)),
    );
  }

  Widget _buildNotificationSettings(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ns = NotificationSettingsService.instance;

    return PhobesCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.notifications_active_rounded,
            title: "Anlık Bildirimler",
            subtitle: "Genel uygulama bildirimleri",
            color: Colors.blue,
            listenable: ns.pushEnabled,
            onChanged: (v) => ns.setPushEnabled(v),
            cs: cs,
          ),
          const Divider(indent: 56),
          _buildSwitchTile(
            icon: Icons.task_alt_rounded,
            title: "Görev Hatırlatıcıları",
            subtitle: "Başlayan görevler için uyar",
            color: Colors.orange,
            listenable: ns.taskRemindersEnabled,
            onChanged: (v) => ns.setTaskRemindersEnabled(v),
            cs: cs,
          ),
          const Divider(indent: 56),
          _buildSwitchTile(
            icon: Icons.group_add_rounded,
            title: "Ekip Davetleri",
            subtitle: "Yeni üyelik ve projeler",
            color: Colors.teal,
            listenable: ns.teamInvitesEnabled,
            onChanged: (v) => ns.setTeamInvitesEnabled(v),
            cs: cs,
          ),
          const Divider(indent: 56),
          _buildSwitchTile(
            icon: Icons.wb_sunny_rounded,
            title: "Günlük Özet",
            subtitle: "Nova'dan her sabah briefing",
            color: Colors.amber,
            listenable: ns.dailyBriefingEnabled,
            onChanged: (v) => ns.setDailyBriefingEnabled(v),
            cs: cs,
          ),
          const Divider(indent: 56),
          _buildSwitchTile(
            icon: Icons.alternate_email_rounded,
            title: "E-posta Bildirimleri",
            subtitle: "Önemli güncellemeleri kaçırma",
            color: Colors.purple,
            listenable: ns.emailEnabled,
            onChanged: (v) => ns.setEmailEnabled(v),
            cs: cs,
          ),
        ],
      ),
    );
  }

  Widget _buildAuthSettings(BuildContext context, String name, String email) {
    final cs = Theme.of(context).colorScheme;
    return PhobesCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildSettingTile(
            icon: Icons.person_outline_rounded,
            title: "Profili Düzenle",
            subtitle: name,
            color: Colors.blueAccent,
            onTap: () => _editNameDialog(name.split(" ")[0],
                name.split(" ").length > 1 ? name.split(" ")[1] : ""),
            cs: cs,
          ),
          const Divider(indent: 56),
          _buildSettingTile(
            icon: Icons.email_outlined,
            title: "E-posta",
            subtitle: email,
            color: Colors.teal,
            onTap: () => _changeEmailDialog(email),
            cs: cs,
          ),
          const Divider(indent: 56),
          _buildSettingTile(
            icon: Icons.lock_outline_rounded,
            title: "Şifre ve Güvenlik",
            subtitle: "Şifrenizi güncelleyin",
            color: Colors.orange,
            onTap: _changePasswordDialog,
            cs: cs,
          ),
        ],
      ),
    );
  }

  Widget _buildModuleSettings(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PhobesCard(
      padding: EdgeInsets.zero,
      child: ValueListenableBuilder<List<String>>(
        valueListenable: ModuleSettingsService.instance.disabledModules,
        builder: (context, disabledModules, child) {
          return ValueListenableBuilder<String>(
            valueListenable: ModuleSettingsService.instance.customNavButton,
            builder: (context, customNavButton, child) {
              return Column(
                children: [
                  _buildNavSelector(
                      context, customNavButton, disabledModules, cs),
                  const Divider(indent: 56),
                  _buildSettingTile(
                    icon: Icons.dashboard_customize_rounded,
                    title: "Modülleri Seç",
                    subtitle: _isModulesExpanded ? "Ayarları daralt" : "Hangi modüller görünsün?",
                    color: Colors.deepPurpleAccent,
                    trailing: Icon(
                      _isModulesExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: cs.primary,
                    ),
                    onTap: () => setState(() => _isModulesExpanded = !_isModulesExpanded),
                    cs: cs,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Visibility(
                      visible: _isModulesExpanded,
                      child: Column(
                        children: [
                          const Divider(indent: 56),
                          ...ModuleSettingsService.availableModules.map((module) {
                            final isEnabled = !disabledModules.contains(module['id']);
                            return Column(
                              children: [
                                _buildModuleToggle(module, isEnabled, cs),
                                if (module !=
                                    ModuleSettingsService.availableModules.last)
                                  const Divider(indent: 56),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNavSelector(BuildContext context, String current,
      List<String> disabled, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child:
                const Icon(Icons.touch_app_rounded, color: Colors.blueAccent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Hızlı Erişim Butonu",
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                Text("Alt barda 'Ekipler' yerine geçer",
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: current,
              dropdownColor: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              style: GoogleFonts.outfit(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
              icon: const Icon(Icons.unfold_more_rounded, size: 18),
              items: ModuleSettingsService.availableModules
                  .where((m) => !disabled.contains(m['id']))
                  .map((module) {
                return DropdownMenuItem<String>(
                    value: module['id'], child: Text(module['name']!));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  ModuleSettingsService.instance.setCustomNavButton(val);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleToggle(
      Map<String, String> module, bool isEnabled, ColorScheme cs) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Icon(_getModuleIcon(module['id']!), color: cs.primary, size: 20),
      ),
      title: Text(module['name']!,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
      value: isEnabled,
      onChanged: (val) =>
          ModuleSettingsService.instance.setModuleDisabled(module['id']!, !val),
      activeThumbColor: cs.primary,
    );
  }

  IconData _getModuleIcon(String id) {
    switch (id) {
      case 'budget':
        return Icons.account_balance_wallet_rounded;
      case 'habit':
        return Icons.spa_rounded;
      case 'notes':
        return Icons.note_alt_rounded;
      case 'appointments':
        return Icons.event_available_rounded;
      case 'medications':
        return Icons.medication_rounded;
      case 'focus':
        return Icons.timelapse_rounded;
      case 'upcoming':
        return Icons.upcoming_rounded;
      case 'statistics':
        return Icons.insights_rounded;
      case 'teams':
        return Icons.groups_2_rounded;
      default:
        return Icons.widgets_rounded;
    }
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
    return ValueListenableBuilder<bool>(
      valueListenable: listenable,
      builder: (context, value, _) {
        return SwitchListTile(
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(title,
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text(subtitle,
              style: GoogleFonts.outfit(
                  fontSize: 11, color: cs.onSurface.withValues(alpha: 0.6))),
          value: value,
          onChanged: (v) => onChanged(v),
          activeThumbColor: cs.primary,
        );
      },
    );
  }

  Future<void> _showSimulateDialog(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await PhobesBottomSheet.confirm(
      context: context,
      title: "Simülasyonu Başlat",
      message:
          "90 günlük gerçekçi veri seti oluşturulacak ve mevcut tüm verilerin silinecek. Devam edilsin mi?",
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
                    Text("Simülasyon Hazırlanıyor...",
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
        message: "Tüm sistem senkronize edildi! 🚀",
        type: PhobesSnackbarType.success);
  }

  Widget _buildLanguageSelector(BuildContext context, AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    final currentLocale = MyApp.of(context)?.locale ?? const Locale('tr');
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(Icons.language_rounded, color: cs.primary, size: 20),
      ),
      title: Text(l10n.language,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<Locale>(
          value: currentLocale.languageCode == 'tr'
              ? const Locale('tr', '')
              : const Locale('en', ''),
          dropdownColor: cs.surfaceContainerHigh,
          items: [
            DropdownMenuItem(
                value: const Locale('tr', ''),
                child: Text('Türkçe', style: GoogleFonts.outfit(fontSize: 13))),
            DropdownMenuItem(
                value: const Locale('en', ''),
                child:
                    Text('English', style: GoogleFonts.outfit(fontSize: 13))),
          ],
          onChanged: (v) {
            if (v != null) MyApp.of(context)?.setLocale(v);
          },
        ),
      ),
    );
  }

  Widget _buildThemeSettings(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PhobesCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: PhobesTheme.themeMode,
              builder: (context, mode, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _themeTab(context, ThemeMode.light, "Gündüz",
                        Icons.light_mode_rounded, mode == ThemeMode.light),
                    _themeTab(context, ThemeMode.dark, "Gece",
                        Icons.dark_mode_rounded, mode == ThemeMode.dark),
                    _themeTab(
                        context,
                        ThemeMode.system,
                        "Sistem",
                        Icons.settings_suggest_rounded,
                        mode == ThemeMode.system),
                  ],
                );
              },
            ),
          ),
          const Divider(indent: 56),
          ValueListenableBuilder<bool>(
            valueListenable: PhobesTheme.amoledMode,
            builder: (context, isAmoled, _) {
              return SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.dark_mode_outlined,
                      color: Colors.blueGrey, size: 20),
                ),
                title: Text("AMOLED Siyah",
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text("Pil tasarrufu için tam siyah arka plan",
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.6))),
                value: isAmoled,
                onChanged: (v) => PhobesTheme.setAmoledMode(v),
                activeThumbColor: cs.primary,
              );
            },
          ),
          const Divider(indent: 56),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Tema Rengi",
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: cs.onSurface)),
                const SizedBox(height: 12),
                ValueListenableBuilder<Color>(
                  valueListenable: PhobesTheme.userAccentColor,
                  builder: (context, accentColor, _) {
                    return SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: PhobesTheme.accentColorOptions.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final color = PhobesTheme.accentColorOptions[index];
                          final isSelected = color == accentColor;
                          return GestureDetector(
                            onTap: () => PhobesTheme.setAccentColor(color),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: cs.onSurface, width: 2)
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                            color: color.withValues(alpha: 0.4),
                                            blurRadius: 10)
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 20)
                                  : null,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _themeTab(BuildContext context, ThemeMode mode, String label,
      IconData icon, bool isSelected) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => PhobesTheme.setThemeMode(mode),
      child: AnimatedContainer(
        duration: PhobesTheme.animFast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected ? cs.onPrimary : cs.onSurface, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? cs.onPrimary : cs.onSurface)),
          ],
        ),
      ),
    );
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
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title,
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              color: isDanger ? cs.error : cs.onSurface,
              fontSize: 15)),
      subtitle: Text(subtitle,
          style: GoogleFonts.outfit(
              color: cs.onSurface.withValues(alpha: 0.5), fontSize: 12)),
      trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: cs.outline, size: 20),
    );
  }
}
