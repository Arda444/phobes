import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/phobes_widgets.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final Map<String, bool> _prefs = {};
  bool _isLoading = true;

  static const _sections = [
    _NotifSection(
      title: 'Görevler',
      icon: Icons.task_alt_rounded,
      color: Color(0xFF8B5CF6),
      items: [
        _NotifItem('notif_task_deadline', 'Görev Son Tarihi',
            'Son tarih yaklaştığında hatırlat'),
        _NotifItem(
            'notif_task_overdue', 'Gecikmiş Görev', 'Süresi geçen görevler'),
      ],
    ),
    _NotifSection(
      title: 'Alışkanlıklar',
      icon: Icons.spa_rounded,
      color: Color(0xFF4CAF50),
      items: [
        _NotifItem('notif_habit_streak', 'Seriler Risk Altında',
            'Seri kaybetme uyarısı'),
        _NotifItem('notif_habit_milestone', 'Kilometre Taşı',
            '7, 30, 100 gün seriler'),
      ],
    ),
    _NotifSection(
      title: 'İlaçlar',
      icon: Icons.medication_rounded,
      color: Color(0xFF009688),
      items: [
        _NotifItem(
            'notif_med_dose', 'Doz Saati', 'İlaç alma saatinde bildirim'),
        _NotifItem('notif_med_missed', 'Atlanan Doz', 'Alınmayan ilaç uyarısı'),
        _NotifItem(
            'notif_med_refill', 'Stok Azaldı', 'İlaç yenileme hatırlatması'),
      ],
    ),
    _NotifSection(
      title: 'Randevular',
      icon: Icons.event_rounded,
      color: Color(0xFF2196F3),
      items: [
        _NotifItem('notif_appt_reminder', 'Randevu Hatırlatma',
            'Randevudan önce hatırlat'),
        _NotifItem('notif_appt_status', 'Durum Değişikliği',
            'Onay, iptal ve değişiklikler'),
      ],
    ),
    _NotifSection(
      title: 'Odaklanma',
      icon: Icons.timelapse_rounded,
      color: Color(0xFFFF9800),
      items: [
        _NotifItem('notif_focus_break', 'Mola Bitişi',
            'Mola süresi dolduğunda hatırlat'),
      ],
    ),
    _NotifSection(
      title: 'Bütçe',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF26A69A),
      items: [
        _NotifItem(
            'notif_budget_limit', 'Limit Uyarısı', 'Bütçe limiti aşıldığında'),
        _NotifItem('notif_budget_goal', 'Tasarruf Hedefi',
            'Hedefe ulaşılınca kutlama'),
        _NotifItem('notif_budget_insight', 'Bütçe İçgörüleri',
            'Haftalık harcama davranış analizleri'),
      ],
    ),
    _NotifSection(
      title: 'Takımlar',
      icon: Icons.groups_rounded,
      color: Color(0xFFFF5722),
      items: [
        _NotifItem(
            'notif_team_assign', 'Görev Atama', 'Size görev atandığında'),
        _NotifItem('notif_team_announce', 'Duyurular', 'Takım duyuruları'),
        _NotifItem('notif_team_deadline', 'Takım Son Tarihi',
            'Takım görevleri son tarihleri'),
      ],
    ),
    _NotifSection(
      title: 'XP & Seviye',
      icon: Icons.stars_rounded,
      color: Color(0xFFFFD600),
      items: [
        _NotifItem('notif_level_up', 'Seviye Atlama',
            'Yeni seviyeye yükselince kutlama'),
        _NotifItem('notif_milestones', 'Özel Kutlamalar',
            'Doğum günü, uygulamaya başlama yıldönümü vb.'),
      ],
    ),
    _NotifSection(
      title: 'Genel',
      icon: Icons.notifications_rounded,
      color: Color(0xFF607D8B),
      items: [
        _NotifItem(
            'notif_morning_brief', 'Sabah Brifing', 'Günün programı özeti'),
        _NotifItem('notif_evening_summary', 'Akşam Özeti',
            'Bugünkü ilerlemelerin raporu'),
        _NotifItem('notif_motivation', 'Motivasyon Mektupları',
            'Rastgele saatlerde günün sözü'),
        _NotifItem('notif_weekly_digest', 'Haftalık Özet',
            'Haftanın performans raporu'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final sp = await SharedPreferences.getInstance();
    for (final section in _sections) {
      for (final item in section.items) {
        _prefs[item.key] = sp.getBool(item.key) ?? true;
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _togglePref(String key, bool value) async {
    setState(() => _prefs[key] = value);
    final sp = await SharedPreferences.getInstance();
    sp.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF050505) : const Color(0xFFF8FAFC),
      appBar: PhobesPremiumAppBar(
        title: 'Bildirim Ayarları',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              itemCount: _sections.length,
              itemBuilder: (context, index) {
                final section = _sections[index];
                return FadeInUp(
                  delay: Duration(milliseconds: index * 60),
                  child: _buildSection(section, isDark),
                );
              },
            ),
    );
  }

  Widget _buildSection(_NotifSection section, bool isDark) {
    final allOn = section.items.every((item) => _prefs[item.key] == true);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            onTap: () {
              final newVal = !allOn;
              for (final item in section.items) {
                _togglePref(item.key, newVal);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: section.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(section.icon, size: 18, color: section.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      section.title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: allOn,
                    onChanged: (v) {
                      for (final item in section.items) {
                        _togglePref(item.key, v);
                      }
                    },
                    activeTrackColor: section.color,
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.04),
          ),
          ...section.items.map((item) {
            final isOn = _prefs[item.key] ?? true;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isOn
                                ? isDark
                                    ? Colors.white
                                    : Colors.black87
                                : isDark
                                    ? Colors.white24
                                    : Colors.black26,
                          ),
                        ),
                        Text(
                          item.description,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: isOn,
                    onChanged: (v) => _togglePref(item.key, v),
                    activeTrackColor: section.color,
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NotifSection {
  final String title;
  final IconData icon;
  final Color color;
  final List<_NotifItem> items;

  const _NotifSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });
}

class _NotifItem {
  final String key;
  final String title;
  final String description;

  const _NotifItem(this.key, this.title, this.description);
}
