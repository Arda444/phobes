import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:intl/intl.dart';
import 'firebase_service.dart';
import 'budget_service.dart';

/// Builds the RAG context string for Nova AI by fetching data from all
/// Phobes modules in parallel and caching the result.
class NovaContextBuilder {
  NovaContextBuilder._();
  static final NovaContextBuilder _instance = NovaContextBuilder._();
  factory NovaContextBuilder() => _instance;

  String? _cachedContext;
  DateTime? _cacheTime;
  static const _cacheTtl = Duration(seconds: 30);

  void invalidate() {
    _cachedContext = null;
    _cacheTime = null;
  }

  bool get isCached =>
      _cachedContext != null &&
      _cacheTime != null &&
      DateTime.now().difference(_cacheTime!) < _cacheTtl;

  Future<String> build({
    required String language,
    required String contextUserHeader,
    required String currentTimeLabel,
    required String tasksTodayLabel,
    required String upcomingTasksLabel,
    required String appointmentsLabel,
    required String medicationsLabel,
    required String habitsLabel,
    required String notesLabel,
    required String teamsLabel,
    required String budgetLabel,
    required String systemRole,
    required String toolUsageRulesHeader,
    required String readyInstruction,
  }) async {
    if (isCached) return _cachedContext!;

    final user = FirebaseAuth.instance.currentUser;
    final userName =
        user?.displayName?.split(' ').first ?? 'Dostum';

    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final locale = language == 'tr' ? 'tr' : 'en';
    final dayName = DateFormat('EEEE', locale).format(now);
    final weekLater = now.add(const Duration(days: 7));

    final fb = FirebaseService();
    final budget = BudgetService();

    final results = await Future.wait<dynamic>([
      fb.getTasksForStats()
          .then<dynamic>((v) => v)
          .catchError((Object e) { debugPrint('[NovaCtx] tasks: $e'); return []; }),
      fb.getUserTeamsStream().first
          .then<dynamic>((v) => v)
          .catchError((Object e) { debugPrint('[NovaCtx] teams: $e'); return []; }),
      budget.getBudgetVsActual()
          .then<dynamic>((v) => v)
          .catchError((Object e) { debugPrint('[NovaCtx] budget: $e'); return {}; }),
      fb.getMedicationsStream().first
          .then<dynamic>((v) => v)
          .catchError((Object e) { debugPrint('[NovaCtx] meds: $e'); return []; }),
      fb.getHabitsStream().first
          .then<dynamic>((v) => v)
          .catchError((Object e) { debugPrint('[NovaCtx] habits: $e'); return null; }),
      fb.getAppointmentsStreamForDateRange(now, weekLater).first
          .then<dynamic>((v) => v)
          .catchError((Object e) { debugPrint('[NovaCtx] appts: $e'); return []; }),
      fb.getNotesStream().first
          .then<dynamic>((v) => (v as List).take(80).toList())
          .catchError((Object e) { debugPrint('[NovaCtx] notes: $e'); return []; }),
      budget.getAccountsStream().first
          .then<dynamic>((v) => v)
          .catchError((Object e) { debugPrint('[NovaCtx] accounts: $e'); return []; }),
      budget.getTransactionsStream().first
          .then<dynamic>((v) => (v as List).take(150).toList())
          .catchError((Object e) { debugPrint('[NovaCtx] txs: $e'); return []; }),
    ]);

    final allTasks   = results[0] as List<dynamic>;
    final teams      = results[1] as List<dynamic>;
    final budgetMap  = results[2] as Map<String, dynamic>;
    final meds       = results[3] as List<dynamic>;
    final habitsSnap = results[4];
    final appts      = results[5] as List<dynamic>;
    final notes      = results[6] as List<dynamic>;
    final accounts   = results[7] as List<dynamic>;
    final allTxs     = results[8] as List<dynamic>;

    // ── Tasks ──────────────────────────────────────────────────────────────
    final todayTasks = allTasks.where((t) =>
        t.startTime.year == now.year &&
        t.startTime.month == now.month &&
        t.startTime.day == now.day &&
        !t.isCompleted,).toList();

    final upcomingTasks = (allTasks.where((t) {
      final isToday = t.startTime.year == now.year &&
          t.startTime.month == now.month &&
          t.startTime.day == now.day;
      return !isToday &&
          t.startTime.isAfter(now) &&
          t.startTime.isBefore(weekLater) &&
          !t.isCompleted;
    }).toList())..sort((a, b) => a.startTime.compareTo(b.startTime));

    final tasksCtx = todayTasks.isEmpty
        ? 'Bugün için planlanmış görev yok.'
        : '$tasksTodayLabel:\n${todayTasks.map((t) => '  • ID: ${t.id} | ${t.title} (${DateFormat('HH:mm').format(t.startTime)})').join('\n')}';

    final upcomingCtx = upcomingTasks.isEmpty ? '' :
        '\n$upcomingTasksLabel:\n${upcomingTasks.map((t) => '  • ID: ${t.id} | ${t.title} (${DateFormat('d MMM HH:mm', locale).format(t.startTime)})').join('\n')}';

    // ── Teams ──────────────────────────────────────────────────────────────
    var teamsCtx = '';
    for (final t in teams) {
      if (teamsCtx.isEmpty) teamsCtx = '\n$teamsLabel:\n';
      teamsCtx += '  • ID: ${t.id} | ${t.name}\n';
    }

    // ── Budget: categories + account balances + recent transactions ────────
    var budgetCtx = '';
    final budgetItems = budgetMap['items'] as List<dynamic>? ?? [];
    if (budgetItems.isNotEmpty || accounts.isNotEmpty) {
      budgetCtx = '\n$budgetLabel:\n';

      if (accounts.isNotEmpty) {
        final totalBalance = accounts.fold<double>(
            0, (sum, a) => sum + ((a.balance as num?)?.toDouble() ?? 0));
        budgetCtx += '  Toplam Bakiye: ${totalBalance.toStringAsFixed(2)} TL\n';
        for (final acc in accounts.take(4)) {
          budgetCtx += '  • ${acc.name}: ${(acc.balance as num?)?.toStringAsFixed(2) ?? '0'} TL\n';
        }
      }

      if (budgetItems.isNotEmpty) {
        budgetCtx += '  Bu Ay Harcama Kategorileri:\n';
        for (final item in budgetItems) {
          final actual = item['actual'] ?? 0;
          final limit = item['limit'] ?? 0;
          final pct = limit > 0 ? ((actual / limit) * 100).round() : 0;
          final warn = pct >= 90 ? ' ⚠️ Limit dolmak üzere!' : (pct >= 70 ? ' 🟡' : '');
          budgetCtx += '    - ${item['category']}: $actual TL / $limit TL (%$pct)$warn\n';
        }
      }

      // Last 5 transactions
      if (allTxs.isNotEmpty) {
        final recentTxs = (allTxs.toList()
          ..sort((a, b) {
            final aDate = a.date as DateTime? ?? DateTime(0);
            final bDate = b.date as DateTime? ?? DateTime(0);
            return bDate.compareTo(aDate);
          })).take(5).toList();
        budgetCtx += '  Son İşlemler:\n';
        for (final tx in recentTxs) {
          final sign = (tx.type?.toString().contains('expense') ?? false) ? '-' : '+';
          budgetCtx += '    - $sign${(tx.amount as num?)?.toStringAsFixed(2) ?? '0'} TL | ${tx.title} (${DateFormat('d MMM', locale).format(tx.date as DateTime)})\n';
        }
      }
    }

    // ── Medications ────────────────────────────────────────────────────────
    var medsCtx = '';
    final activeMeds = meds.where((m) => m.isActive == true).toList();
    if (activeMeds.isNotEmpty) {
      medsCtx = '\n$medicationsLabel:\n';
      for (final m in activeMeds) {
        medsCtx += '  • ID: ${m.id} | ${m.name} (${m.dosage}) | Saatler: ${(m.times as List?)?.join(', ') ?? '-'}';
        if (m.stockTracking == true) {
          final stock = m.stock as int? ?? 0;
          if (stock <= 0) {
            medsCtx += ' | Stok: BOŞ ❌';
          } else if (stock <= (m.stockThreshold as int? ?? 5)) {
            medsCtx += ' | Stok: $stock adet ⚠️ Az kaldı!';
          } else {
            medsCtx += ' | Stok: $stock adet';
          }
        }
        medsCtx += '\n';
      }
    }

    // ── Habits ────────────────────────────────────────────────────────────
    var habitsCtx = '';
    if (habitsSnap != null && habitsSnap.docs.isNotEmpty) {
      habitsCtx = '\n$habitsLabel:\n';
      for (final doc in habitsSnap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        habitsCtx += "  • ID: ${doc.id} | ${d['title'] ?? ''} (Seri: ${d['streak'] ?? 0} gün)\n";
      }
    }

    // ── Appointments ──────────────────────────────────────────────────────
    var apptsCtx = '';
    for (final a in appts) {
      if (apptsCtx.isEmpty) apptsCtx = '\n$appointmentsLabel:\n';
      apptsCtx += '  • ID: ${a.id} | ${a.title} | ${a.clientName} | ${DateFormat('d MMM HH:mm', locale).format(a.date)} (${a.durationMinutes} min)\n';
    }

    // ── Notes ─────────────────────────────────────────────────────────────
    var notesCtx = '';
    final recentNotes = (notes
        .where((n) => n.deletedAt == null && !n.isArchived)
        .toList()
      ..sort((a, b) => (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0))))
        .take(5)
        .toList();
    for (final n in recentNotes) {
      if (notesCtx.isEmpty) notesCtx = '\n$notesLabel:\n';
      notesCtx += '  • Not ID: ${n.id} | ${n.title}';
      if (n.notebookId != null) notesCtx += ' [Defter: ${n.notebookId}]';
      notesCtx += '\n';
    }

    final context = '''Sen Nova'sın — Phobes uygulamasının yapay zeka asistanı ve kişisel yaşam koçu.

═══ GİZLİ KULLANICI BAĞLAMI ═══
Kullanıcı Adı : $userName
Şu Anki Zaman : ${dateFormat.format(now)} ($dayName)

$tasksCtx$upcomingCtx$apptsCtx$medsCtx$habitsCtx$notesCtx$teamsCtx$budgetCtx

═══ KİŞİLİĞİN ═══
• Zeki, samimi, motive edici, bazen esprili — ama her zaman pratik.
• Kısa ve öz konuş. Bilgiyi madde madde ver, uzun paragraf yok.
• Kullanıcı sormadıkça bağlamı yüzüne vurma — sadece arka plan olarak kullan.
• Emojileri yerinde kullan; gereksiz emoji yığma.
• Türkçe konuş. İngilizce sormadıkça Türkçe yanıt ver.

═══ YAPAY ZEKA DANIŞMANLIĞI ═══
BÜTÇE: Harcama sorulduğunda bağlamdaki verileri analiz et. Tasarruf önerileri, harcama kategorisi dağılımı, bütçe aşımı uyarısı, birikme hesabı yap. Araç çağırmadan da analiz ve tavsiye verebilirsin.
İLAÇ: İlaç sıklığı, doz hatırlatması, stok uyarısı, ilaç etkileşim genel bilgisi (doktor tavsiyesi dışında) için danışabilirler. Stok azsa kullanıcıyı uyar.
GENEL: Zaman yönetimi, üretkenlik, motivasyon, sağlıklı yaşam, stres yönetimi konularında koçluk yap.

═══ ARAÇ KULLANIM KURALLARI ═══
► Görev EKLE (tekli)          → create_task
► Görev EKLE (çoklu / liste)  → create_multiple_tasks  ← BİRDEN FAZLA VARSA BUNU KULLAN
► Günlük/haftalık PLAN yap    → create_day_plan
► Belirsiz istek / soru sor   → ask_user_options  ← DÜZMETIN SORU SORMA, BU ARACI KULLAN
► Görev ERTELE/TAŞI           → reschedule_task
► Görev SİL/İPTAL             → cancel_task
► Görev GÜNCELLE              → update_task
► Görev TAMAMLA               → complete_task
► Görev ARA/BUL               → find_task
► Alt görev EKLE              → add_subtasks
► Randevu OLUŞTUR             → create_appointment
► Randevu İPTAL               → cancel_appointment
► Randevu ERTELE              → reschedule_appointment
► Not OLUŞTUR                 → create_note
► Alışkanlık EKLE             → add_habit
► İlaç ALINDI                 → mark_medication_taken
► Harcama EKLE                → add_expense
► Gelir EKLE                  → add_income
► Tasarruf hedefi EKLE        → add_savings_goal
► Takıma duyuru GÖNDER        → send_team_announcement

ÖRNEKLER:
  "Pazartesi spor, Salı toplantı, Perşembe diş"  → create_multiple_tasks (3 görev)
  "Yarını planla"  → create_day_plan
  "Hafta sonu ne yapayım?"  → ask_user_options (seçenekler sun)
  "Kaç param kaldı?"  → bağlamdan hesapla, araç çağırma
  "İlacımı içtim"  → mark_medication_taken

KURALLAR:
• Tarih yoksa yarını, saat yoksa 09:00 varsay. Format: YYYY-MM-DD / HH:MM.
• ASLA araç çağırmadan işlem yaptığını söyleme.
• __PENDING_TASK__ gibi etiketleri KENDİN YAZMA — sistem otomatik üretir.
• Her araç çağrısı onay kartı oluşturur; kullanıcı onaylamadan HİÇBİR ŞEY değişmez.
• Belirsiz isteklerde (hangi gün? hangi saat? ne tür?) ask_user_options ile seçenek sun.
• Araç çağırdıktan sonra sadece "Hazırladım 👇" de, tekrar tekrar açıklama yapma.''';

    const maxContextChars = 3500;
    final trimmed = context.length > maxContextChars
        ? '${context.substring(0, maxContextChars)}\n…[bağlam kısaltıldı]'
        : context;

    _cachedContext = trimmed;
    _cacheTime = DateTime.now();
    return trimmed;
  }
}
