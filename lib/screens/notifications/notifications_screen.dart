import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../models/app_notification_model.dart';
import '../../services/firebase_service.dart';
import '../../core/page_transitions.dart';
import 'notification_preferences_screen.dart';
import '../../widgets/phobes_widgets.dart';
import '../../core/phobes_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _firebaseService = FirebaseService();
  String _filter = 'all';

  static const _filters = {
    'all': 'Tümü',
    'task': 'Görevler',
    'habit': 'Alışkanlıklar',
    'medication': 'İlaçlar',
    'appointment': 'Randevular',
    'team': 'Takımlar',
    'system': 'Sistem',
  };

  static const _typeIcons = {
    'task': Icons.task_alt_rounded,
    'habit': Icons.spa_rounded,
    'medication': Icons.medication_rounded,
    'appointment': Icons.event_rounded,
    'team': Icons.groups_rounded,
    'project': Icons.folder_rounded,
    'system': Icons.info_rounded,
  };

  static const _typeColors = {
    'task': Color(0xFF8B5CF6),
    'habit': Color(0xFF4CAF50),
    'medication': Color(0xFF009688),
    'appointment': Color(0xFF2196F3),
    'team': Color(0xFFFF9800),
    'project': Color(0xFFE91E63),
    'system': Color(0xFF607D8B),
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAmoled = PhobesTheme.amoledMode.value;
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 900;

      return Scaffold(
        backgroundColor: isWide
            ? Colors.transparent
            : (isAmoled && isDark ? Colors.black : cs.surface),
        appBar: isWide
            ? null
            : AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: UnconstrainedBox(
                  child: PhobesIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                title: Text(
                  'Bildirimler',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                actions: [
                  PhobesIconButton(
                    icon: Icons.done_all_rounded,
                    color: cs.primary,
                    onTap: () => _firebaseService.markAllNotificationsRead(),
                  ),
                  const SizedBox(width: 8),
                  PhobesIconButton(
                    icon: Icons.settings_outlined,
                    onTap: () => PhobesPageRoute.pushResponsive(
                      context,
                      const NotificationPreferencesScreen(),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 12,
                children: _filters.entries.map((e) {
                  final isSelected = _filter == e.key;
                  final color = e.key == 'all'
                      ? cs.primary
                      : _typeColors[e.key] ?? const Color(0xFF607D8B);
                  return PhobesChip(
                    label: e.value,
                    isSelected: isSelected,
                    color: color,
                    onTap: () => setState(() => _filter = e.key),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<AppNotification>>(
                stream: _firebaseService.getNotificationsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: PhobesLoadingIndicator(color: cs.primary),
                    );
                  }

                  var notifications = snapshot.data ?? [];
                  if (_filter != 'all') {
                    notifications =
                        notifications.where((n) => n.type == _filter).toList();
                  }

                  if (notifications.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      return FadeInRight(
                        delay: Duration(milliseconds: index * 40),
                        child: _buildNotificationCard(notif),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildNotificationCard(AppNotification notif) {
    final cs = Theme.of(context).colorScheme;
    final color = _typeColors[notif.type] ?? const Color(0xFF607D8B);
    final icon = _typeIcons[notif.type] ?? Icons.notifications_rounded;
    final timeAgo = _formatTimeAgo(notif.createdAt);

    return PhobesCard(
      onTap: () {
        if (!notif.isRead && notif.id != null) {
          _firebaseService.markNotificationRead(notif.id!);
        }
      },
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      gradient: notif.isRead
          ? null
          : LinearGradient(
              colors: [
                color.withValues(alpha: 0.08),
                color.withValues(alpha: 0.02),
              ],
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: notif.icon.length <= 2
                  ? Text(notif.icon, style: const TextStyle(fontSize: 18))
                  : Icon(icon, size: 20, color: color),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notif.title,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight:
                              notif.isRead ? FontWeight.w500 : FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  notif.body,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!notif.isRead)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(left: 8, top: 4),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: FadeInUp(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhobesGlassCard(
                padding: const EdgeInsets.all(28),
                borderRadius: 40,
                child: Icon(Icons.notifications_off_rounded,
                    size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
              ),
              const SizedBox(height: 24),
              Text(
                'Henüz bildiriminiz yok',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Görevler, ilaçlar ve diğer etkinlikleriniz\nilgili bildirimler burada görünecek',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes}dk';
    if (diff.inHours < 24) return '${diff.inHours}sa';
    if (diff.inDays < 7) return '${diff.inDays}g';
    return '${date.day}.${date.month}';
  }
}
