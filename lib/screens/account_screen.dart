import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/firebase_service.dart';
import '../main.dart';
import '../l10n/app_localizations.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> _avatarSeeds = [
    "Felix",
    "Aneka",
    "Zoe",
    "Jack",
    "Bella",
    "Rocky",
    "Milo",
    "Loki",
    "Ginger",
    "Shadow",
    "Luna",
    "Bear",
    "Leo",
    "Jasper",
    "Max",
    "Cleo"
  ];

  @override
  void initState() {
    super.initState();
  }

  // --- AVATAR SEÇİM DİYALOĞU ---
  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        height: 400,
        child: Column(
          children: [
            Text("Bir Karakter Seç",
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _avatarSeeds.length,
                itemBuilder: (context, index) {
                  final seed = _avatarSeeds[index];
                  final url =
                      "https://api.dicebear.com/9.x/adventurer/png?seed=$seed";

                  return GestureDetector(
                    onTap: () async {
                      // Referansları al
                      final navigator = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(this.context);

                      navigator.pop(); // Menüyü kapat

                      await _firebaseService.updateAvatar(seed);

                      messenger.showSnackBar(const SnackBar(
                          content: Text("Profil resmi güncellendi! 😎")));
                    },
                    child: ClipOval(
                      child: Container(
                        color: Colors.grey.shade800,
                        child: CachedNetworkImage(
                          imageUrl: url,
                          placeholder: (context, url) => const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(
                                color: Colors.teal, strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error, color: Colors.red),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. İSİM GÜNCELLEME
  Future<void> _editNameDialog(
      String currentName, String currentSurname) async {
    final nameCtrl = TextEditingController(text: currentName);
    final surnameCtrl = TextEditingController(text: currentSurname);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Bilgileri Düzenle",
            style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _buildDialogTextField(nameCtrl, "Ad"),
          const SizedBox(height: 10),
          _buildDialogTextField(surnameCtrl, "Soyad")
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B1FA2)),
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              await _firebaseService.updateUserName(
                  nameCtrl.text.trim(), surnameCtrl.text.trim());
              navigator.pop();
            },
            child: const Text("Kaydet", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // 2. ŞİFRE DEĞİŞTİRME
  Future<void> _changePasswordDialog() async {
    final passCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title:
            const Text("Şifre Değiştir", style: TextStyle(color: Colors.white)),
        content:
            _buildDialogTextField(passCtrl, "Yeni Şifre", isPassword: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B1FA2)),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(dialogContext);

              try {
                await _auth.currentUser?.updatePassword(passCtrl.text.trim());
                navigator.pop();
                messenger.showSnackBar(
                    const SnackBar(content: Text("Şifre değişti")));
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text("Hata: $e")));
              }
            },
            child:
                const Text("Güncelle", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // 3. E-POSTA DEĞİŞTİRME
  Future<void> _changeEmailDialog(String current) async {
    final emailCtrl = TextEditingController(text: current);
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("E-posta Değiştir",
            style: TextStyle(color: Colors.white)),
        content: _buildDialogTextField(emailCtrl, "Yeni E-posta"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B1FA2)),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(dialogContext);

              try {
                await _auth.currentUser
                    ?.verifyBeforeUpdateEmail(emailCtrl.text.trim());
                navigator.pop();
                messenger.showSnackBar(
                    const SnackBar(content: Text("Onay postası gönderildi")));
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text("Hata: $e")));
              }
            },
            child:
                const Text("Güncelle", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildDialogTextField(TextEditingController c, String h,
          {bool isPassword = false}) =>
      TextField(
        controller: c,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
            labelText: h, labelStyle: const TextStyle(color: Colors.grey)),
      );

  Future<void> _signOut() async {
    final navigator = Navigator.of(context);
    await _auth.signOut();
    navigator.pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<void> _showDeleteAccountDialog() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Hesabı Sil",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
            "Hesabınızı ve verilerinizi kalıcı olarak silmek istediğinize emin misiniz?",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Sil"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return; // HATA ÇÖZÜMÜ
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      try {
        await _firebaseService.deleteAllData();
        await _auth.currentUser?.delete();
        navigator.pushNamedAndRemoveUntil('/login', (route) => false);
        messenger
            .showSnackBar(const SnackBar(content: Text("Hesabınız silindi.")));
      } catch (e) {
        messenger.showSnackBar(
            SnackBar(content: Text("Hata: $e (Tekrar giriş yapıp deneyin)")));
      }
    }
  }

  Future<void> _showClearDataDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(l10n.clearAllDataTitle,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.white)),
        content: Text("Tüm veriler silinecek. Emin misiniz?",
            style: GoogleFonts.poppins(color: Colors.grey.shade300)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return; // HATA ÇÖZÜMÜ
      final messenger = ScaffoldMessenger.of(context);
      messenger
          .showSnackBar(const SnackBar(content: Text("Veriler siliniyor...")));

      await _firebaseService.deleteAllData();

      if (!mounted) return; // HATA ÇÖZÜMÜ
      messenger.showSnackBar(SnackBar(content: Text(l10n.allDataDeleted)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.accountAndSettings,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 24,
                color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: StreamBuilder<DocumentSnapshot>(
            stream: _firebaseService.getUserDataStream(),
            builder: (context, snapshot) {
              String name = "Yükleniyor...", email = "", birthDate = "";
              String? photoUrl;
              int xp = 0;
              int level = 1;

              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                name = "${data['name']} ${data['surname']}";
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

              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.purple.shade900.withValues(alpha: 0.4),
                        Colors.blue.shade900.withValues(alpha: 0.4)
                      ]),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _showAvatarPicker,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: const Color(0xFF7B1FA2),
                                child: photoUrl != null
                                    ? ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: photoUrl,
                                          placeholder: (context, url) =>
                                              const CircularProgressIndicator(
                                                  color: Colors.white),
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.error),
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : "?",
                                        style: GoogleFonts.poppins(
                                            fontSize: 32,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                      color: Colors.teal,
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.edit,
                                      size: 14, color: Colors.white),
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              Text("Seviye $level Zaman Lordu ($xp XP)",
                                  style: GoogleFonts.poppins(
                                      fontSize: 14, color: Colors.tealAccent)),
                              Text(email,
                                  style: GoogleFonts.poppins(
                                      fontSize: 14, color: Colors.white70)),
                              if (birthDate.isNotEmpty)
                                Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text("Doğum: $birthDate",
                                        style: GoogleFonts.poppins(
                                            fontSize: 12, color: Colors.grey))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle("Hesap Ayarları"),
                  _buildSettingTile(context,
                      icon: Icons.science_rounded,
                      title: "Test Verisi Oluştur (1 Yıl)",
                      subtitle: "Uygulamaya rastgele veri ekler",
                      color: Colors.green.shade400, onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.showSnackBar(
                        const SnackBar(content: Text("Simülasyon başladı...")));
                    await _firebaseService.generateSimulationData();
                    messenger.showSnackBar(const SnackBar(
                        content: Text("Simülasyon tamamlandı!")));
                  }),
                  if (isDesktop) ...[
                    Row(children: [
                      Expanded(
                          child: _buildSettingTile(context,
                              icon: Icons.password_rounded,
                              title: "Şifre Değiştir",
                              subtitle: "****",
                              color: Colors.blue.shade400,
                              onTap: _changePasswordDialog)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildSettingTile(context,
                              icon: Icons.email_outlined,
                              title: "E-posta",
                              subtitle: email,
                              color: Colors.teal.shade400,
                              onTap: () => _changeEmailDialog(email))),
                    ]),
                    const SizedBox(height: 12),
                    _buildSettingTile(context,
                        icon: Icons.edit,
                        title: "Bilgileri Düzenle",
                        subtitle: name,
                        color: Colors.indigo.shade400,
                        onTap: () => _editNameDialog(
                            name.split(" ")[0],
                            name.split(" ").length > 1
                                ? name.split(" ")[1]
                                : "")),
                  ] else ...[
                    _buildSettingTile(context,
                        icon: Icons.edit,
                        title: "Bilgileri Düzenle",
                        subtitle: name,
                        color: Colors.indigo.shade400,
                        onTap: () => _editNameDialog(
                            name.split(" ")[0],
                            name.split(" ").length > 1
                                ? name.split(" ")[1]
                                : "")),
                    _buildSettingTile(context,
                        icon: Icons.password_rounded,
                        title: "Şifre Değiştir",
                        subtitle: "****",
                        color: Colors.blue.shade400,
                        onTap: _changePasswordDialog),
                    _buildSettingTile(context,
                        icon: Icons.email_outlined,
                        title: "E-posta Değiştir",
                        subtitle: email,
                        color: Colors.teal.shade400,
                        onTap: () => _changeEmailDialog(email)),
                  ],
                  _buildSectionTitle(l10n.dataManagement),
                  _buildSettingTile(context,
                      icon: Icons.delete_sweep_rounded,
                      title: l10n.clearAllData,
                      subtitle: "Sadece verileri siler",
                      color: Colors.orange.shade400,
                      onTap: _showClearDataDialog),
                  _buildSettingTile(context,
                      icon: Icons.delete_forever_rounded,
                      title: "Hesabı Sil",
                      subtitle: "Kalıcı olarak siler",
                      color: Colors.red.shade400,
                      onTap: _showDeleteAccountDialog),
                  _buildSectionTitle(l10n.languageSettings),
                  _buildLanguageSelector(context, l10n),

                  // TECHLUNA SOFTWARE İMZASI
                  const SizedBox(height: 40),
                  Column(
                    children: [
                      Text("Phobes v1.0.0",
                          style: GoogleFonts.jetBrainsMono(
                              color: Colors.white24, fontSize: 10)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.code,
                              size: 12, color: Colors.purple),
                          const SizedBox(width: 4),
                          Text("Powered by Techluna Software",
                              style: GoogleFonts.poppins(
                                  color: Colors.purple.shade300,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
      padding: const EdgeInsets.only(top: 32.0, bottom: 16.0),
      child: Text(title.toUpperCase(),
          style: GoogleFonts.poppins(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
              fontSize: 13)));

  Widget _buildSettingTile(BuildContext context,
          {required IconData icon,
          required String title,
          required String subtitle,
          required Color color,
          required VoidCallback onTap}) =>
      Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
              leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color)),
              title: Text(title,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, color: Colors.white)),
              subtitle: Text(subtitle,
                  style:
                      GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: Colors.white54),
              onTap: onTap));

  Widget _buildLanguageSelector(BuildContext context, AppLocalizations l10n) {
    // HATA ÇÖZÜMÜ: Artık getter olduğu için bu çalışır.
    final currentLocale = MyApp.of(context)?.locale ?? const Locale('tr');
    return Card(
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.language_rounded,
                      color: Colors.purple.shade300)),
              const SizedBox(width: 16),
              Text(l10n.language,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 16)),
              const Spacer(),
              DropdownButton<Locale>(
                  value: currentLocale.languageCode == 'tr'
                      ? const Locale('tr', '')
                      : const Locale('en', ''),
                  dropdownColor: Colors.grey.shade800,
                  style: GoogleFonts.poppins(color: Colors.white),
                  underline: Container(),
                  items: [
                    DropdownMenuItem(
                        value: const Locale('tr', ''),
                        child: Text('Türkçe',
                            style: GoogleFonts.poppins(fontSize: 14))),
                    DropdownMenuItem(
                        value: const Locale('en', ''),
                        child: Text('English',
                            style: GoogleFonts.poppins(fontSize: 14)))
                  ],
                  onChanged: (v) {
                    if (v != null) MyApp.of(context)?.setLocale(v);
                  })
            ])));
  }
}
