import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/appointment_group_model.dart';
import '../models/budget_model.dart';
import '../models/app_notification_model.dart';
import '../services/budget_service.dart';
import '../services/notification_service.dart';

/// Tüm modüller için 3 aylık gerçekçi test verisi oluşturur.
class DevDataService {
  static final DevDataService _instance = DevDataService._internal();
  factory DevDataService() => _instance;
  DevDataService._internal();

  FirebaseFirestore get db => FirebaseFirestore.instance;
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;
  User? get currentUser => FirebaseAuth.instance.currentUser;

  final _rng = Random();
  late String _uid;
  late DateTime _now;

  DateTime _daysAgo(int d) => _now.subtract(Duration(days: d));
  DateTime _daysLater(int d) => _now.add(Duration(days: d));
  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ─── Tüm verileri sil ─────────────────────────────────────────────────────
  Future<void> deleteAllData() async {
    if (currentUserId == null) return;

    final subcollections = [
      db.collection('users').doc(currentUserId).collection('medications'),
      db.collection('users').doc(currentUserId).collection('notifications'),
      db.collection('users').doc(currentUserId).collection('user_books'),
      db.collection('users').doc(currentUserId).collection('book_quotes'),
      db.collection('users').doc(currentUserId).collection('reading_goals'),
      db.collection('users').doc(currentUserId).collection('shelf_decorations'),
    ];

    final topLevel = [
      db.collection('tasks').where('userId', isEqualTo: currentUserId),
      db.collection('notes').where('userId', isEqualTo: currentUserId),
      db.collection('notebooks').where('userId', isEqualTo: currentUserId),
      db.collection('habits').where('userId', isEqualTo: currentUserId),
      db.collection('appointments').where('userId', isEqualTo: currentUserId),
      db.collection('budget_transactions').where('userId', isEqualTo: currentUserId),
      db.collection('budget_accounts').where('userId', isEqualTo: currentUserId),
      db.collection('budget_debts').where('userId', isEqualTo: currentUserId),
      db.collection('budget_limits').where('userId', isEqualTo: currentUserId),
      db.collection('savings_goals').where('userId', isEqualTo: currentUserId),
      db.collection('budget_assets').where('userId', isEqualTo: currentUserId),
      db.collection('corkboard_items').where('userId', isEqualTo: currentUserId),
      db.collection('corkboard_connections').where('userId', isEqualTo: currentUserId),
      db.collection('corkboard_boards').where('userId', isEqualTo: currentUserId),
      db.collection('clients').where('userId', isEqualTo: currentUserId),
      db.collection('activity_logs').where('userId', isEqualTo: currentUserId),
    ];

    // Takımlar: sahip olunanları sil, üye olunanlardan ayrıl
    try {
      final teamsSnap = await db
          .collection('teams')
          .where('memberIds', arrayContains: currentUserId)
          .get();
      for (final t in teamsSnap.docs) {
        final isOwner = t.data()['ownerId'] == currentUserId;
        if (isOwner) {
          for (final col in ['projects', 'resources', 'book_clubs']) {
            final sub = await t.reference.collection(col).get();
            for (final d in sub.docs) {
              await d.reference.delete();
            }
          }
          await t.reference.delete();
        } else {
          await t.reference.update({
            'memberIds': FieldValue.arrayRemove([currentUserId]),
            'adminIds': FieldValue.arrayRemove([currentUserId]),
          });
        }
      }
    } catch (e) {
      debugPrint('deleteAllData teams error: $e');
    }

    // book_prefs dokümanını sil
    try {
      await db.doc('users/$currentUserId/book_prefs/order').delete();
    } catch (_) {}

    final allRefs = <DocumentReference>[];

    // Randevu grupları + slot alt koleksiyonları
    try {
      final groupsSnap = await db
          .collection('appointment_groups')
          .where('ownerId', isEqualTo: currentUserId)
          .get();
      for (final g in groupsSnap.docs) {
        final slots = await g.reference.collection('slots').get();
        allRefs.addAll(slots.docs.map((d) => d.reference));
        allRefs.add(g.reference);
      }
    } catch (e) {
      debugPrint('deleteAllData appointment_groups error: $e');
    }

    for (final sub in subcollections) {
      try {
        final snap = await sub.get();
        allRefs.addAll(snap.docs.map((d) => d.reference));
      } catch (e) {
        debugPrint('deleteAllData subcoll error: $e');
      }
    }
    for (final q in topLevel) {
      try {
        final snap = await q.get();
        allRefs.addAll(snap.docs.map((d) => d.reference));
      } catch (e) {
        debugPrint('deleteAllData query error: $e');
      }
    }

    for (var i = 0; i < allRefs.length; i += 400) {
      final batch = db.batch();
      final end = (i + 400 < allRefs.length) ? i + 400 : allRefs.length;
      for (var j = i; j < end; j++) { batch.delete(allRefs[j]); }
      await batch.commit();
    }
  }

  // ─── Ana üretici ──────────────────────────────────────────────────────────
  Future<void> generateFullTestEnvironment({Function(double)? onProgress}) async {
    if (currentUserId == null) return;
    _uid = currentUserId!;
    _now = DateTime.now();

    debugPrint('>> TestGen: Başlıyor...');
    onProgress?.call(0.02);

    await deleteAllData();
    await NotificationService().cancelAllNotifications();
    onProgress?.call(0.06);

    // XP & seviye
    await db.collection('users').doc(_uid).update({'xp': 23750, 'level': 22});
    onProgress?.call(0.08);

    // ── 1. Bütçe ────────────────────────────────────────────────────────────
    await _generateBudget();
    onProgress?.call(0.16);

    // ── 2. Alışkanlıklar ────────────────────────────────────────────────────
    await _generateHabits();
    onProgress?.call(0.24);

    // ── 3. İlaçlar ──────────────────────────────────────────────────────────
    await _generateMedications();
    onProgress?.call(0.31);

    // ── 4. Defterler & Notlar ───────────────────────────────────────────────
    await _generateNotebooks();
    onProgress?.call(0.40);

    // ── 5. Takımlar & Projeler ──────────────────────────────────────────────
    final teamIds = await _generateTeams();
    onProgress?.call(0.50);

    // ── 6. Görevler ─────────────────────────────────────────────────────────
    await _generateTasks(teamIds);
    onProgress?.call(0.60);

    // ── 7. Randevular ───────────────────────────────────────────────────────
    await _generateAppointments();
    onProgress?.call(0.68);

    // ── 8. Kitaplar ─────────────────────────────────────────────────────────
    await _generateBooks();
    onProgress?.call(0.78);

    // ── 9. Plan Panosu ──────────────────────────────────────────────────────
    await _generateCorkboard();
    onProgress?.call(0.88);

    // ── 10. Bildirimler ─────────────────────────────────────────────────────
    await _generateNotifications();
    onProgress?.call(1.0);

    debugPrint('>> TestGen: TAMAMLANDI!');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 1. BÜTÇE
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _generateBudget() async {
    final svc = BudgetService();
    await svc.generateUltimateTestData();

    for (final l in [
      BudgetLimit(userId: _uid, category: 'Market', limitAmount: 5000),
      BudgetLimit(userId: _uid, category: 'Yemek', limitAmount: 3500),
      BudgetLimit(userId: _uid, category: 'Ulaşım', limitAmount: 2000),
      BudgetLimit(userId: _uid, category: 'Eğlence', limitAmount: 1500),
      BudgetLimit(userId: _uid, category: 'Fatura', limitAmount: 3000),
      BudgetLimit(userId: _uid, category: 'Sağlık', limitAmount: 1000),
      BudgetLimit(userId: _uid, category: 'Kişisel Bakım', limitAmount: 800),
      BudgetLimit(userId: _uid, category: 'Giyim', limitAmount: 2000),
    ]) {
      await svc.addLimit(l);
    }

    for (final g in [
      SavingsGoal(
        userId: _uid, title: 'MacBook Pro M4 Max',
        targetAmount: 95000, currentAmount: 71500,
        deadline: _daysLater(55), icon: '💻',
      ),
      SavingsGoal(
        userId: _uid, title: 'Yaz Tatili — Kapadokya & Ege',
        targetAmount: 45000, currentAmount: 32000,
        deadline: _daysLater(80), icon: '🏖️',
      ),
      SavingsGoal(
        userId: _uid, title: 'Acil Durum Fonu (6 Aylık)',
        targetAmount: 300000, currentAmount: 187500,
        icon: '🏦',
      ),
      SavingsGoal(
        userId: _uid, title: 'Elektrikli Bisiklet',
        targetAmount: 28000, currentAmount: 14200,
        deadline: _daysLater(110), icon: '🚲',
      ),
      SavingsGoal(
        userId: _uid, title: 'Yatırım Fonu — Hisse',
        targetAmount: 150000, currentAmount: 68000,
        icon: '📈',
      ),
    ]) {
      await svc.addGoal(g);
    }

    // Borçlar
    for (final d in [
      Debt(
        userId: _uid,
        personName: 'Mehmet Yılmaz',
        amount: 5000,
        type: DebtType.credit,   // sen verdin
        date: _daysAgo(20),
        dueDate: _daysLater(30),
        description: 'Mayıs ayı sonuna kadar geri ödeyecek',
      ),
      Debt(
        userId: _uid,
        personName: 'Fatma Hanım',
        amount: 12000,
        type: DebtType.debt,
        date: _daysAgo(45),
        dueDate: _daysLater(60),
        description: 'Kira için annemden yardım aldım',
      ),
      Debt(
        userId: _uid,
        personName: 'Zeynep Arslan',
        amount: 3500,
        type: DebtType.credit,   // sen vermiştin, iade edildi
        date: _daysAgo(30),
        isPaid: true,
        description: 'Tatil payı — iade alındı',
      ),
    ]) {
      await svc.addDebt(d);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 2. ALIŞKANLIKLAR — 8 farklı alışkanlık, gerçekçi seri geçmişi
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _generateHabits() async {
    final habits = [
      {'title': 'Sabah Meditasyonu', 'icon': '🧘', 'streak': 42, 'breakAt': -1, 'miss': 0.05, 'color': 0xFF6366F1},
      {'title': '30 Dk Egzersiz', 'icon': '🏋️', 'streak': 18, 'breakAt': 25, 'miss': 0.15, 'color': 0xFF3B82F6},
      {'title': 'Günlük 2L Su', 'icon': '💧', 'streak': 61, 'breakAt': -1, 'miss': 0.03, 'color': 0xFF06B6D4},
      {'title': 'Kitap Okuma (30 dk)', 'icon': '📚', 'streak': 7, 'breakAt': 12, 'miss': 0.25, 'color': 0xFFF59E0B},
      {'title': 'Yabancı Dil Çalışma', 'icon': '🌍', 'streak': 31, 'breakAt': 45, 'miss': 0.20, 'color': 0xFF10B981},
      {'title': 'Sağlıklı Öğle Yemeği', 'icon': '🥗', 'streak': 14, 'breakAt': -1, 'miss': 0.10, 'color': 0xFF22C55E},
      {'title': 'Günlük Günlük Yaz', 'icon': '✍️', 'streak': 9, 'breakAt': 20, 'miss': 0.30, 'color': 0xFFEC4899},
      {'title': 'Ekran Süresini Sınırla', 'icon': '📵', 'streak': 5, 'breakAt': 8, 'miss': 0.40, 'color': 0xFF8B5CF6},
    ];

    for (final h in habits) {
      final streak = h['streak'] as int;
      final miss = h['miss'] as double;
      final lastCompleted = streak > 0 && _rng.nextDouble() > 0.2 ? _now : _daysAgo(1);
      final completedDates = <String>[];
      for (int day = 0; day < 90; day++) {
        final date = _daysAgo(day);
        final breakAt = h['breakAt'] as int;
        final isBroken = breakAt > 0 && day == breakAt;
        if (!isBroken && _rng.nextDouble() > miss) {
          completedDates.add(_dateKey(date));
        }
      }
      await db.collection('habits').add({
        'userId': _uid,
        'title': h['title'],
        'icon': h['icon'],
        'streak': streak,
        'longestStreak': streak + _rng.nextInt(25),
        'totalCompleted': completedDates.length,
        'lastCompleted': Timestamp.fromDate(lastCompleted),
        'completedDates': completedDates,
        'createdAt': Timestamp.fromDate(_daysAgo(90)),
        'reminderTime': '${7 + _rng.nextInt(5)}:${_rng.nextBool() ? '00' : '30'}',
        'color': h['color'],
        'isActive': true,
      });
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 3. İLAÇLAR — 5 ilaç, gerçekçi dozaj geçmişi
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _generateMedications() async {
    final meds = [
      {'name': 'D3 Vitamini', 'dosage': '2000 IU', 'icon': '☀️', 'color': 0xFFFEF9C3, 'times': ['08:00'], 'stock': 45, 'threshold': 10, 'notes': 'Sabah kahvaltıyla al', 'genericName': 'Cholecalciferol'},
      {'name': 'Omega-3', 'dosage': '1000 mg', 'icon': '🐟', 'color': 0xFFDBEAFE, 'times': ['09:00', '21:00'], 'stock': 30, 'threshold': 7, 'notes': 'Yemeklerle birlikte al', 'genericName': 'Fish Oil'},
      {'name': 'Magnezyum Glisin', 'dosage': '200 mg', 'icon': '💊', 'color': 0xFFD1FAE5, 'times': ['22:00'], 'stock': 60, 'threshold': 14, 'notes': 'Uyumadan önce al', 'genericName': 'Magnesium Glycinate'},
      {'name': 'B12 Vitamini', 'dosage': '1000 mcg', 'icon': '⚡', 'color': 0xFFFCE7F3, 'times': ['08:30'], 'stock': 8, 'threshold': 10, 'notes': 'Düşük stok! Yenilemek gerekiyor.', 'genericName': 'Cyanocobalamin'},
      {'name': 'Probiyotik', 'dosage': '5 Milyar CFU', 'icon': '🌿', 'color': 0xFFE0F2FE, 'times': ['07:30'], 'stock': 20, 'threshold': 5, 'notes': 'Aç karnına al', 'genericName': 'Lactobacillus Acidophilus'},
    ];

    for (final med in meds) {
      final takenHistory = <String, List<String>>{};
      for (int day = 0; day < 90; day++) {
        final date = _daysAgo(day);
        final key = _dateKey(date);
        final times = med['times'] as List<String>;
        final takenTimes = times.where((_) => _rng.nextDouble() > 0.12).toList();
        if (takenTimes.isNotEmpty) takenHistory[key] = takenTimes;
      }
      await db.collection('users').doc(_uid).collection('medications').add({
        'userId': _uid,
        'name': med['name'],
        'dosage': med['dosage'],
        'icon': med['icon'],
        'color': med['color'],
        'times': med['times'],
        'notes': med['notes'],
        'genericName': med['genericName'],
        'isActive': true,
        'reminderEnabled': true,
        'stock': med['stock'],
        'stockTracking': true,
        'stockThreshold': med['threshold'],
        'takenHistory': takenHistory,
        'frequency': 'daily',
        'startDate': Timestamp.fromDate(_daysAgo(90)),
        'createdAt': Timestamp.fromDate(_daysAgo(90)),
      });
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 4. DEFTERLER & NOTLAR — 5 defter, 20+ not
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _generateNotebooks() async {
    final notebooks = [
      {'title': 'İş & Proje Notları', 'icon': '💼', 'color': 0xFF6366F1, 'order': 0},
      {'title': 'Kişisel Günlük', 'icon': '✍️', 'color': 0xFFEC4899, 'order': 1},
      {'title': 'Öğrenme & Araştırma', 'icon': '🔬', 'color': 0xFF10B981, 'order': 2},
      {'title': 'Fikirler & Taslaklar', 'icon': '💡', 'color': 0xFFF59E0B, 'order': 3},
      {'title': 'Sağlık & Wellness', 'icon': '🌿', 'color': 0xFF22C55E, 'order': 4},
    ];

    final notesByNb = [
      // İş notları
      [
        ('Sprint #15 Retrospektif', '## Sprint #15 Özet\n\n### İyi Gidenler ✅\n- Firebase entegrasyonu tamamlandı\n- UI performansı %40 arttı\n- Test coverage %75e ulaştı\n\n### Geliştirme Alanları ⚠️\n- Stand-up toplantıları daha kısa tutulmalı\n- Code review süreci hızlandırılmalı\n\n### Aksiyon Maddeleri\n1. CI/CD pipeline güncellenmeli\n2. Staging ortamı kurulacak\n3. Onboarding dokümanı yazılacak'),
        ('API Tasarım Kararları v2', '## REST API v2 Mimari\n\n### Temel Prensipler\n- Rate limiting: 100 req/dk\n- JWT authentication + refresh\n- Pagination: cursor-based\n- Webhook desteği\n\n### Endpoint Yapısı\n```\nGET  /api/v2/tasks?cursor=xyz&limit=20\nPOST /api/v2/tasks\nPUT  /api/v2/tasks/:id\nDEL  /api/v2/tasks/:id\n```\n\n> Not: v1 endpoint\'leri 6 ay daha aktif kalacak.'),
        ('Takım Toplantısı — Haftalık OKR', '### Katılımcılar: Ardak + 3 kişi\n\n### Gündem\n1. Q2 OKR gözden geçirme → %67 tamamlandı\n2. Kitap Modülü — öncelik yükseltildi\n3. Teknik borç planlaması\n\n### Kararlar\n- Slot-based raf sistemi harika çıktı! 🎉\n- Mobil bildirimler Haziran\'a ertelendi\n- Nova AI context window genişletilecek'),
        ('Performans Optimizasyon Raporu', '## Optimizasyon Sonuçları\n\n### Stream Leak Düzeltmeleri\n- 15+ inline stream → initState\'e taşındı\n- N+1 sorgu düzeltildi (55 → 4 Firestore okuması)\n- NotebookSidebar StatefulWidget\'a çevrildi\n\n### Ölçümler\n| Metrik | Önce | Sonra |\n|--------|------|-------|\n| FCP | 3.2s | 1.4s |\n| TTI | 5.1s | 2.1s |\n| Memory | 280MB | 190MB |'),
        ('Güvenlik Audit Notları', '## Firestore Security Rules Güncellemesi\n\n### Eklenen Kurallar\n- book_prefs subcollection → isOwner check\n- task_created cross-user notification\n- book_clubs team member update rule\n\n### DevDataService Düzeltmeleri\n- kDebugMode guard eklendi\n- Production\'da erişim engellendi\n\n### Kalan Riskler\n- Admin client-side check eksik\n- Rate limiting memory-based (distributed değil)'),
      ],
      // Kişisel günlük
      [
        ('2025 Hedeflerim — Yıl Ortası Değerlendirmesi', '## 2025 Kişisel Hedefler — 6. Ay Değerlendirmesi\n\n### Sağlık & Fitness ✅\n- Haftada 4 gün spor yapıyorum\n- Meditasyon: 42 günlük seri!\n- Kilo: Hedefte 🎯\n\n### Kariyer ⚡\n- Phobes: Kitap modülü eklendi 📚\n- Flutter talk başvurusu yapıldı\n- Rust öğrenme devam ediyor\n\n### Finansal 📊\n- Acil fon: %62 (hedef %100)\n- MacBook hedefi: %75 🎯\n- Yatırım portföyü +%18 getiri\n\n### Genel Değerlendirme\nBu yıl çok üretken. Tempoyu koru!'),
        ('Haftalık Değerlendirme — 3. Hafta', '## Bu Haftanın Özeti\n\n🟢 **Başarılar**\n- Kitap rafı drag & drop çalışıyor!\n- Sprint hedeflerinin %90\'ı tamamlandı\n- 3 kitap bitirildi bu ay (42 toplam)\n\n🟡 **Dikkat Edilecekler**\n- Sosyal medya süresini azalt\n- B12 vitamini ALACAKSIN bugün\n\n🔴 **Geliştir**\n- 2 gün egzersiz atlandı\n- Uyku düzeni bozuldu (23:30\'a kadar ekran)\n\n**Gelecek Haftanın Öncelikleri:**\n1. Kitap modülü istatistikler\n2. Randevu bildirimleri\n3. Flutter conference slide\'ları'),
        ('Günlük Rutin v3.0', '## Sabah Rutini (06:30 — 09:00)\n```\n06:30 — Uyan, 500ml su\n06:45 — 20 dk meditasyon\n07:10 — Kahvaltı + vitamin\n07:30 — Podcast (teknik)\n08:00 — Günlük plan gözden geçir\n08:30 — İlk odak bloğu (deep work)\n```\n\n## Akşam Rutini (20:30 — 23:00)\n```\n20:30 — İş bitti, bilgisayar kapat\n20:45 — 30 dk yürüyüş\n21:30 — Kitap okuma 📚\n22:30 — Günlük günlük\n23:00 — Uyku (alarm: 06:30)\n```'),
      ],
      // Öğrenme notları
      [
        ('Flutter Advanced — Sliver Protocol', '## Sliver Protocol Özet\n\n### Temel Kavramlar\n- SliverList: Lazy rendering\n- SliverGrid: 2D lazy grid\n- SliverAppBar: Scroll-based header\n- SliverOverlapAbsorber: NestedScrollView için\n\n### Yaygın Hatalar\n```dart\n// ❌ Yanlış: NestedScrollView\'de\nSliverToBoxAdapter(child: CustomScrollView(...))\n\n// ✅ Doğru:\nNestedScrollView(\n  headerSliverBuilder: ...\n  body: CustomScrollView()\n)\n```\n\n### Phobes\'ta Kullanım\n- BooksScreen: NestedScrollView + SliverAppBar\n- BudgetScreen: NestedScrollView + pinned header'),
        ('Firebase Optimization Notları', '## Firestore Best Practices\n\n### Okunuyor Kuralı\n- stream: inline → initState\'de cache\n- asBroadcastStream() kullan\n- dispose\'da cancel et\n\n### N+1 Query Problemi\n```dart\n// ❌ N+1: Her proje için ayrı sorgu\nfor (final proj in projects) {\n  final tasks = await db.collection(\'tasks\')\n    .where(\'groupId\', isEqualTo: proj.id).get();\n}\n\n// ✅ Batch: whereIn ile\ndb.collection(\'tasks\')\n  .where(\'groupId\', whereIn: projectIds)\n  .get();\n```\n\n### Index Stratejisi\n- Composite index: userId + date + status\n- Limit: 1000 per query default\n- Cursor-based pagination > offset'),
        ('Rust Öğrenme Notları — Hafta 4', '## Rust — Ownership & Borrowing\n\n### 3 Kural:\n1. Her değerin bir sahibi var\n2. Aynı anda yalnızca bir sahip olabilir\n3. Sahip scope dışına çıktığında değer drop olur\n\n### Borrow Checker\n```rust\nfn main() {\n    let s1 = String::from("hello");\n    let s2 = &s1; // borrow\n    println!("{} {}", s1, s2); // ✅\n    \n    let s3 = s1; // move!\n    // println!("{}", s1); // ❌ moved!\n}\n```\n\n### Sonraki Adım\n- Lifetimes öğren\n- wasm-pack ile Flutter entegrasyonu dene'),
      ],
      // Fikirler
      [
        ('Phobes Yeni Özellik Fikirleri — v3.5', '## Ürün Fikirleri Backlog\n\n### 🔥 Yüksek Etki\n- **Kitap Kulübü** ✅ Eklendi!\n- **Okuma İstatistikleri** ✅ Eklendi!\n- **Alıntı Widget** — Ana ekran entegrasyonu\n- **AI Kitap Özeti** — Nova entegrasyonu\n\n### 💡 Orta Vadeli\n- Spotify entegrasyonu (odak müziği)\n- PDF not dışa aktarma\n- Pomodoro + alışkanlık bağlantısı\n\n### 🌱 Uzun Vade\n- AR kitaplık görünümü\n- Sosyal okuma listesi\n- Kitap takas platformu\n\n### 📊 Kullanıcı Talebi Top 3\n1. Offline mod\n2. Daha iyi widget\'lar\n3. Dark/AMOLED tema'),
        ('Hızlı Notlar & Linkler — Kitap API', '## Book API Araştırması\n\n### Kullanılan API\'ler\n- **Google Books API**: Geniş katalog, iyi metadata\n- **Open Library API**: Türkçe kitaplar için çok iyi!\n\n### Arama Stratejisi\n```dart\n// Önce ISBN dene\nif (isIsbn(query)) {\n  // Her iki API\'yi paralel çağır\n  await Future.wait([\n    searchByIsbn_Google(query),\n    searchByIsbn_OpenLibrary(query),\n  ]);\n}\n// Sonra combined search\n```\n\n### Kapak Görseli Optimizasyonu\n- wsrv.nl CORS proxy kullanıldı\n- Thumbnail → Medium kalite upgrade\n- CachedNetworkImage ile local cache'),
      ],
      // Sağlık & Wellness
      [
        ('Beslenme Planı — Mayıs 2025', '## Günlük Beslenme Hedefleri\n\n### Makrolar\n- Protein: 150g/gün\n- Karbonhidrat: 200g/gün\n- Yağ: 70g/gün\n- Kalori: ~2200 kcal\n\n### Öğün Planı\n**Kahvaltı:** Yulaf + meyve + 2 yumurta\n**Öğle:** Izgara tavuk + salata + tam buğday\n**Ara Öğün:** Kuruyemiş + muz\n**Akşam:** Sebze yoğun + protein\n\n### Kaçınılacaklar\n- İşlenmiş gıda\n- Şekerli içecekler\n- Gece 21:00\'den sonra yemek\n\n### Bu Ay Değerlendirmesi\n✅ Şimdiye kadar en iyi ay!'),
        ('Spor Programı v2', '## Haftalık Antrenman\n\n**Pazartesi:** Göğüs + Triceps\n**Salı:** Sırt + Biceps\n**Çarşamba:** REST / Hafif cardio\n**Perşembe:** Bacak + Omuz\n**Cuma:** Full body + core\n**Hafta Sonu:** Outdoor aktivite\n\n## Kişisel Rekortlar\n| Egzersiz | Ağırlık |\n|----------|--------|\n| Bench Press | 80 kg |\n| Deadlift | 110 kg |\n| Squat | 95 kg |\n\n## Hedefler (3 Ay)\n- Bench: 90 kg\n- Koşu: 5K < 25 dk'),
      ],
    ];

    for (int nb = 0; nb < notebooks.length; nb++) {
      final nbData = notebooks[nb];
      final nbDoc = await db.collection('notebooks').add({
        'userId': _uid,
        'name': nbData['title'],
        'icon': nbData['icon'],
        'color': nbData['color'],
        'order': nbData['order'],
        'createdAt': Timestamp.fromDate(_daysAgo(85)),
      });

      if (nb < notesByNb.length) {
        for (int ni = 0; ni < notesByNb[nb].length; ni++) {
          final (title, content) = notesByNb[nb][ni];
          await db.collection('notes').add({
            'userId': _uid,
            'notebookId': nbDoc.id,
            'title': title,
            'content': content,
            'date': Timestamp.fromDate(_daysAgo(ni * 4 + _rng.nextInt(3))),
            'updatedAt': Timestamp.fromDate(_daysAgo(ni)),
            'isPinned': ni == 0,
            'isFavorite': ni == 0 || _rng.nextBool(),
            'isArchived': false,
            'deletedAt': null,
            'allowedUserIds': [],
            'createdAt': Timestamp.fromDate(_daysAgo(ni * 4 + 5)),
          });
        }
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 5. TAKIMLAR & PROJELER — 3 takım, 7 proje
  // ══════════════════════════════════════════════════════════════════════════
  Future<List<String>> _generateTeams() async {
    final teamDefs = [
      {
        'name': 'Broadway Yazılım Ekibi',
        'color': 0xFF6366F1,
        'code': 'BRDW',
        'announcement': '🚀 Sprint #15 başladı! Kitap modülü ve drag-drop raf sistemi tamamlandı. Sırada: Öneri motoru & AI entegrasyonu.',
        'projects': [
          {'name': 'Phobes Flutter App v2.5', 'desc': 'Web desteği, responsive tasarım, kitap modülü.', 'color': 0xFF6366F1, 'status': 'active', 'days': 45},
          {'name': 'Nova AI — Gelişmiş Bağlam', 'desc': 'RAG mimarisi iyileştirme, kitap özeti entegrasyonu.', 'color': 0xFF8B5CF6, 'status': 'active', 'days': 30},
          {'name': 'Cloud Altyapı Göçü', 'desc': 'Firebase Functions Edge Runtime\'a geçiş.', 'color': 0xFF10B981, 'status': 'on_hold', 'days': 90},
        ],
        'resources': [
          {'title': 'Figma Tasarım Sistemi', 'url': 'https://figma.com', 'type': 'design'},
          {'title': 'Kod deposu', 'url': 'https://gitlab.com', 'type': 'code'},
          {'title': 'Firebase Console', 'url': 'https://console.firebase.google.com', 'type': 'tool'},
          {'title': 'Firestore Security Rules Docs', 'url': 'https://firebase.google.com/docs/firestore/security', 'type': 'doc'},
        ],
      },
      {
        'name': 'Kreatif Tasarım Atölyesi',
        'color': 0xFFEC4899,
        'code': 'DSGN',
        'announcement': '🎨 Kitap rafı için ahşap doku ve bookend tasarımı güncellendi. Yeni renk paleti hazır!',
        'projects': [
          {'name': 'Phobes Marka Kimliği v2', 'desc': 'Logo, renk paleti ve tipografi yenileme.', 'color': 0xFFEC4899, 'status': 'active', 'days': 20},
          {'name': 'Marketing Site Redesign', 'desc': 'Landing page ve pricing sayfaları.', 'color': 0xFFF59E0B, 'status': 'completed', 'days': 60},
        ],
        'resources': [
          {'title': 'Brand Guidelines PDF', 'url': 'https://drive.google.com', 'type': 'doc'},
          {'title': 'Color Palette — Phobes', 'url': 'https://coolors.co', 'type': 'design'},
        ],
      },
      {
        'name': 'Phobes Büyüme & Pazarlama',
        'color': 0xFFF59E0B,
        'code': 'MRKT',
        'announcement': '📊 Mayıs kampanyası raporları hazır. Dönüşüm oranı %2.3\'e çıktı! Kitap modülü tanıtım içerikleri planlandı.',
        'projects': [
          {'name': 'Q2 İçerik Kampanyası', 'desc': 'Blog yazıları, sosyal medya ve email serisi.', 'color': 0xFFF59E0B, 'status': 'active', 'days': 15},
          {'name': 'App Store Optimizasyonu (ASO)', 'desc': 'ASO analizi, yeni ekran görüntüleri, kitap özelliği tanıtımı.', 'color': 0xFF3B82F6, 'status': 'active', 'days': 25},
        ],
        'resources': [
          {'title': 'Analytics Dashboard', 'url': 'https://analytics.google.com', 'type': 'analytics'},
          {'title': 'Mailchimp Kampanyalar', 'url': 'https://mailchimp.com', 'type': 'email'},
        ],
      },
    ];

    final teamIds = <String>[];

    for (final td in teamDefs) {
      final teamDoc = await db.collection('teams').add({
        'name': td['name'],
        'ownerId': _uid,
        'memberIds': [_uid],
        'adminIds': [_uid],
        'joinCode': '${td['code']}-${1000 + _rng.nextInt(8999)}',
        'color': td['color'],
        'announcement': td['announcement'],
        'announcementBy': currentUser?.displayName ?? 'Ardak',
        'announcementDate': FieldValue.serverTimestamp(),
        'createdAt': Timestamp.fromDate(_daysAgo(90)),
      });
      teamIds.add(teamDoc.id);

      final projectDefs = td['projects'] as List<Map<String, dynamic>>;
      for (int pi = 0; pi < projectDefs.length; pi++) {
        final p = projectDefs[pi];
        final projDoc = await teamDoc.collection('projects').add({
          'teamId': teamDoc.id,
          'name': p['name'],
          'description': p['desc'],
          'managerId': _uid,
          'status': p['status'],
          'deadline': Timestamp.fromDate(_daysLater(p['days'] as int)),
          'color': p['color'],
          'createdAt': Timestamp.fromDate(_daysAgo(80)),
        });

        final taskTitles = _projectTaskTitles(p['name'] as String);
        for (int ti = 0; ti < taskTitles.length; ti++) {
          final isPast = ti < taskTitles.length ~/ 2;
          await db.collection('tasks').add({
            'userId': _uid,
            'groupId': projDoc.id,
            'teamId': teamDoc.id,
            'title': taskTitles[ti],
            'description': 'Proje görevi: ${p['name']}',
            'startTime': Timestamp.fromDate(isPast ? _daysAgo(ti * 3 + 1) : _daysLater(ti * 2 + 1)),
            'endTime': Timestamp.fromDate(isPast ? _daysAgo(ti * 3) : _daysLater(ti * 2 + 2)),
            'isCompleted': isPast && _rng.nextDouble() > 0.2,
            'status': isPast ? (_rng.nextDouble() > 0.2 ? 'done' : 'todo') : ['todo', 'in_progress', 'review'][_rng.nextInt(3)],
            'priority': _rng.nextInt(3),
            'color': p['color'],
            'assignedTo': [_uid],
            'repeatRule': 'none',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      final resources = td['resources'] as List<Map<String, dynamic>>;
      for (final res in resources) {
        await teamDoc.collection('resources').add({
          'title': res['title'],
          'url': res['url'],
          'description': '${res['type']} kaynağı',
          'color': (td['color'] as int),
          'addedBy': _uid,
          'type': res['type'],
          'createdAt': Timestamp.fromDate(_daysAgo(30 + _rng.nextInt(60))),
        });
      }

      final clubBooks = [
        ('Atomic Habits', ['James Clear'], 320, 198),
        ('Deep Work', ['Cal Newport'], 296, 142),
        ('Yaban', ['Yakup Kadri Karaosmanoğlu'], 480, 95),
      ];
      final clubIdx = (teamIds.length - 1) % clubBooks.length;
      final (bookTitle, authors, pages, progress) = clubBooks[clubIdx];
      final displayName = currentUser?.displayName ?? 'Ardak';
      await teamDoc.collection('book_clubs').add({
        'teamId': teamDoc.id,
        'name': '${td['name']} Kitap Kulübü',
        'createdBy': _uid,
        'createdAt': Timestamp.fromDate(_daysAgo(40)),
        'isActive': true,
        'bookTitle': bookTitle,
        'bookAuthors': authors,
        'bookPageCount': pages,
        'startDate': Timestamp.fromDate(_daysAgo(21)),
        'targetFinishDate': Timestamp.fromDate(_daysLater(18)),
        'memberProgress': {_uid: progress},
        'memberNames': {_uid: displayName},
      });

      final activities = [
        ('member_joined', '${currentUser?.displayName ?? 'Ardak'} ekibe katıldı'),
        ('task_created', 'Yeni görev oluşturuldu'),
        ('task_completed', 'Görev tamamlandı'),
        ('project_created', 'Yeni proje oluşturuldu'),
        ('resource_added', 'Kaynak eklendi'),
        ('announcement_updated', 'Duyuru güncellendi'),
      ];
      for (int ai = 0; ai < activities.length; ai++) {
        final (action, details) = activities[ai];
        await db.collection('activity_logs').add({
          'teamId': teamDoc.id,
          'userId': _uid,
          'userName': currentUser?.displayName ?? 'Ardak',
          'action': action,
          'details': details,
          'timestamp': Timestamp.fromDate(_daysAgo(ai * 5 + _rng.nextInt(3))),
        });
      }
    }

    await db.collection('users').doc(_uid).update({
      'joinedTeams': FieldValue.arrayUnion(teamIds),
    });

    return teamIds;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 6. GÖREVLER — 90 gün + tekrarlayan + gelecek
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _generateTasks(List<String> teamIds) async {
    // Geçmiş kişisel görevler — 90 gün
    final titles = [
      ('Doktor Randevusu Hazırlığı', 'Kan tahlili sonuçlarını topla', 0xFFEF4444),
      ('Fatura Ödemeleri', 'Elektrik, doğalgaz, internet', 0xFFF59E0B),
      ('Market Alışverişi', 'Haftalık alışveriş listesi', 0xFF10B981),
      ('Flutter Kurs Çalışması', 'Advanced animations modülü', 0xFF6366F1),
      ('Proje Raporu Hazırla', 'Aylık sprint raporu', 0xFF8B5CF6),
      ('E-posta Yanıtları', 'Birikmiş e-postaları yanıtla', 0xFF3B82F6),
      ('Egzersiz Planı Güncelle', 'Yeni program araştır', 0xFFEC4899),
      ('Kitap Özeti Yaz', 'Atomic Habits — not al', 0xFFF59E0B),
      ('Vitamin Al', 'B12 stok yenileme', 0xFF10B981),
      ('Haftalık Review', 'OKR progress kontrolü', 0xFF6366F1),
      ('Kod Review', 'Takım PR\'larını incele', 0xFF8B5CF6),
      ('Tasarım Revizyon', 'Figma güncellemeleri', 0xFFEC4899),
    ];

    for (int day = 0; day < 90; day++) {
      final date = _daysAgo(day);
      final count = 1 + _rng.nextInt(3);
      for (int i = 0; i < count; i++) {
        final (title, desc, color) = titles[(day + i) % titles.length];
        final h = 8 + _rng.nextInt(10);
        final done = _rng.nextDouble() > 0.25;
        await db.collection('tasks').add({
          'userId': _uid,
          'title': title,
          'description': desc,
          'startTime': Timestamp.fromDate(DateTime(date.year, date.month, date.day, h)),
          'endTime': Timestamp.fromDate(DateTime(date.year, date.month, date.day, h + 1)),
          'isCompleted': done,
          'status': done ? 'done' : (day < 3 ? 'in_progress' : 'todo'),
          'priority': _rng.nextInt(3),
          'color': color,
          'repeatRule': 'none',
          'assignedTo': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    // Tekrarlayan görevler
    final recurring = [
      ('Haftalık Özet Raporu', 'Sprint ve OKR durumu değerlendirmesi', 0xFF6366F1, 'weekly'),
      ('Sabah Pomodoro Seansı', 'Deep work — 2 saat kesintisiz', 0xFFEF4444, 'daily'),
      ('Günlük Stand-up', 'Ekip ile 15 dakikalık durum toplantısı', 0xFF3B82F6, 'daily'),
    ];

    for (final (title, desc, color, repeat) in recurring) {
      await db.collection('tasks').add({
        'userId': _uid,
        'title': title,
        'description': desc,
        'startTime': Timestamp.fromDate(DateTime(_now.year, _now.month, _now.day, 9)),
        'endTime': Timestamp.fromDate(DateTime(_now.year, _now.month, _now.day, 10)),
        'isCompleted': false,
        'status': 'todo',
        'priority': 2,
        'color': color,
        'repeatRule': repeat,
        'assignedTo': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Gelecek önemli görevler
    final upcoming = [
      (2, 'Kitap Modülü Öneri Motoru', 'Open Library tavsiye sistemi implementasyonu', 0xFF6366F1, 2),
      (3, 'Flutter Web Deployment', 'Production deploy kontrol listesi', 0xFF8B5CF6, 2),
      (5, 'Takım Haftalık Toplantısı', '15:00 — Zoom, OKR gözden geçirme', 0xFF3B82F6, 1),
      (7, 'Diş Hekimi Kontrol', 'Dr. Elif Şahin — saat 11:00', 0xFFEF4444, 2),
      (10, 'Vergi Beyannamesi', 'Muhasebeci randevusu — Q2 kapanışı', 0xFFF59E0B, 2),
      (14, 'B12 Vitamini Satın Al', 'Stok kritik (8 adet kaldı)', 0xFF10B981, 1),
      (15, 'Q3 OKR Planlaması', 'Ekiplerle workshop — Zoom', 0xFF10B981, 2),
      (21, 'Yıllık Sigorta Yenileme', 'Son tarih: 1 Temmuz — acil!', 0xFFEC4899, 2),
      (25, 'Kitap Kulübü — Yaban Tartışması', 'Takım kitap kulübü toplantısı', 0xFFF59E0B, 1),
      (30, 'Flutter Conference Sunumu', 'Slide hazırlama ve prova', 0xFF6366F1, 2),
      (45, 'MacBook Alım Günü 🎉', 'Hedef tutturuldu — Apple Store randevusu', 0xFF22C55E, 1),
    ];

    for (final (days, title, desc, color, priority) in upcoming) {
      final date = _daysLater(days);
      await db.collection('tasks').add({
        'userId': _uid,
        'title': title,
        'description': desc,
        'startTime': Timestamp.fromDate(DateTime(date.year, date.month, date.day, 10)),
        'endTime': Timestamp.fromDate(DateTime(date.year, date.month, date.day, 11)),
        'isCompleted': false,
        'status': days <= 7 ? 'in_progress' : 'todo',
        'priority': priority,
        'color': color,
        'repeatRule': 'none',
        'assignedTo': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 7. RANDEVULAR — hizmet grupları, müşteriler, 90 günlük geçmiş/gelecek
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _generateAppointments() async {
    final clientNames = [
      'Mehmet Yılmaz', 'Ayşe Kaya', 'Can Öztürk',
      'Zeynep Arslan', 'Ali Demir', 'Selin Çelik',
      'Burak Koç', 'Elif Şahin', 'Murat Güler', 'Deniz Aydın',
    ];

    for (int i = 0; i < clientNames.length; i++) {
      final name = clientNames[i];
      await db.collection('clients').add({
        'userId': _uid,
        'name': name,
        'email': '${name.split(' ').first.toLowerCase()}@example.com',
        'phone': '05${30 + i}${100 + _rng.nextInt(90)} ${100 + _rng.nextInt(900)} ${1000 + _rng.nextInt(9000)}',
        'note': 'Simülasyon müşterisi — danışmanlık hizmeti',
        'tags': i.isEven ? ['kurumsal', 'flutter'] : ['bireysel'],
        'totalVisits': 2 + _rng.nextInt(12),
        'totalSpent': 3000 + _rng.nextInt(18000).toDouble(),
        'lastVisit': Timestamp.fromDate(_daysAgo(_rng.nextInt(45))),
        'createdAt': Timestamp.fromDate(_daysAgo(75 + i)),
      });
    }

    final consultGroupId = await _createAppointmentGroup(
      title: 'Yazılım Danışmanlığı',
      businessName: 'Ardak Yazılım Studio',
      description: 'Freelance Flutter & Firebase danışmanlık hizmetleri',
      durationMinutes: 60,
      price: 1500,
      color: 0xFF3B82F6,
      category: 'consulting',
    );

    final healthGroupId = await _createAppointmentGroup(
      title: 'Wellness Koçluğu',
      businessName: 'Phobes Wellness',
      description: 'Beslenme, fitness ve yaşam düzeni danışmanlığı',
      durationMinutes: 45,
      price: 800,
      color: 0xFF10B981,
      category: 'health',
      startHour: 8,
      endHour: 20,
    );

    final topics = [
      'Flutter MVP geliştirme',
      'Firebase mimari danışmanlık',
      'CI/CD kurulumu',
      'Performans optimizasyonu',
      'API tasarımı',
      'State management stratejisi',
      'Web responsive layout',
    ];

    // Yönetim: geçmiş danışmanlık randevuları (90 gün)
    for (int i = 0; i < 28; i++) {
      final daysBack = 2 + i * 3 + _rng.nextInt(2);
      final date = _daysAgo(daysBack);
      final hour = 9 + (i % 5) * 2;
      final status = _rng.nextDouble() > 0.14 ? 'completed' : 'cancelled';
      final client = clientNames[i % clientNames.length];
      await _addSimulatedAppointment(
        groupId: consultGroupId,
        title: 'Danışmanlık Seansı',
        clientName: client,
        email: '${client.split(' ').first.toLowerCase()}@example.com',
        phoneNumber:
            '05${300 + _rng.nextInt(99)} ${100 + _rng.nextInt(900)} ${1000 + _rng.nextInt(9000)}',
        date: DateTime(date.year, date.month, date.day, hour),
        status: status,
        price: 1500 + (i % 4) * 250.0,
        color: 0xFF3B82F6,
        notes: topics[i % topics.length],
        createdAt: _daysAgo(daysBack + 2),
      );
    }

    // Yönetim: gelecek danışmanlık + wellness
    for (int i = 0; i < 12; i++) {
      final daysAhead = 1 + i * 2 + _rng.nextInt(2);
      final date = _daysLater(daysAhead);
      final useHealth = i.isEven;
      await _addSimulatedAppointment(
        groupId: useHealth ? healthGroupId : consultGroupId,
        title: useHealth ? 'Wellness Seansı' : 'Danışmanlık Seansı',
        clientName: clientNames[i % clientNames.length],
        email: 'future$i@example.com',
        date: DateTime(date.year, date.month, date.day, 10 + (i % 4) * 2),
        durationMinutes: useHealth ? 45 : 60,
        status: i % 5 == 0 ? 'confirmed' : 'pending',
        price: useHealth ? 800.0 : 1500.0,
        color: useHealth ? 0xFF10B981 : 0xFF3B82F6,
        notes: useHealth
            ? 'Beslenme planı ve antrenman takibi'
            : 'Flutter & Firebase proje geliştirme',
      );
    }

    // Randevularım: kişisel randevular (groupId yok → müşteri sekmesinde görünür)
    final personalAppts = [
      ('Diş Hekimi Kontrolü', 'Dr. Elif Şahin', '6 aylık kontrol — röntgen dahil', -45, 11, 45, 0xFFEF4444),
      ('Göz Muayenesi', 'Prof. Dr. Kadir Aktaş', 'Yıllık göz tansiyonu muayenesi', -30, 14, 30, 0xFF8B5CF6),
      ('Fizik Tedavi', 'Uzm. Fzt. Seda Yıldız', 'Bel ağrısı — 4. seans', -12, 9, 50, 0xFF06B6D4),
      ('Kan Tahlili', 'Medipol Lab', 'Vitamin paneli + tiroid', -8, 8, 20, 0xFFEC4899),
      ('Diş Hekimi Kontrolü', 'Dr. Elif Şahin', '6 aylık kontrol', 7, 11, 45, 0xFFEF4444),
      ('Fitness Antrenörü', 'Burak Coşkun', 'Program değerlendirme', 3, 7, 60, 0xFF10B981),
      ('Kan Tahlili', 'Medipol Lab', 'Vitamin seviyeleri kontrolü', 5, 8, 20, 0xFFEC4899),
      ('Saç Kesimi', 'Barber Shop Beyoğlu', 'Saç + sakal', 12, 10, 30, 0xFFF59E0B),
      ('Göz Muayenesi', 'Prof. Dr. Kadir Aktaş', 'Yıllık muayene', 22, 14, 30, 0xFF8B5CF6),
      ('Muhasebeci Toplantısı', 'Vergi Danışmanı Ahmet K.', 'Q2 kapanış danışmanlığı', 10, 15, 90, 0xFF6366F1),
      ('Dermatoloji', 'Dr. Pınar Aksoy', 'Cilt kontrolü', 18, 13, 30, 0xFFF472B6),
      ('Ortopedi', 'Doç. Dr. Emre Balkan', 'Diz MR sonuç değerlendirme', 35, 16, 40, 0xFF78909C),
    ];

    for (final (title, provider, notes, dayOffset, hour, duration, color)
        in personalAppts) {
      final date = dayOffset < 0
          ? _daysAgo(-dayOffset)
          : _daysLater(dayOffset);
      final isPast = dayOffset < 0;
      await _addSimulatedAppointment(
        title: title,
        clientName: provider,
        date: DateTime(date.year, date.month, date.day, hour),
        durationMinutes: duration,
        status: isPast ? 'completed' : 'confirmed',
        color: color,
        notes: notes,
        reminderMinutes: isPast ? -1 : 30,
      );
    }
  }

  Future<String> _createAppointmentGroup({
    required String title,
    required String businessName,
    required String description,
    required int durationMinutes,
    required double price,
    required int color,
    required String category,
    int startHour = 9,
    int endHour = 18,
  }) async {
    final ref = await db.collection('appointment_groups').add({
      'ownerId': _uid,
      'title': title,
      'businessName': businessName,
      'description': description,
      'durationMinutes': durationMinutes,
      'bufferMinutes': 15,
      'minCancellationHours': 24,
      'startDate': Timestamp.fromDate(_daysAgo(30)),
      'endDate': Timestamp.fromDate(_daysLater(120)),
      'startHour': startHour,
      'endHour': endHour,
      'groupCode': AppointmentGroup.generateCode(),
      'workingDays': [1, 2, 3, 4, 5],
      'breaks': [
        {'start': 12, 'end': 13},
      ],
      'color': color,
      'icon': 'calendar_today',
      'category': category,
      'isActive': true,
      'price': price,
      'currency': 'TRY',
      'businessPhone': '0532 ${100 + _rng.nextInt(899)} ${1000 + _rng.nextInt(9000)}',
      'businessAddress': 'Online (Zoom) + İstanbul ofis',
      'createdAt': Timestamp.fromDate(_daysAgo(90)),
    });
    return ref.id;
  }

  Future<void> _writeAppointmentSlot(
    String groupId,
    DateTime date,
    String status, {
    String? clientId,
  }) async {
    await db
        .collection('appointment_groups')
        .doc(groupId)
        .collection('slots')
        .doc('${date.millisecondsSinceEpoch}')
        .set({
      'date': Timestamp.fromDate(date),
      'status': status,
      'providerId': _uid,
      'clientId': clientId,
      'groupId': groupId,
    });
  }

  Future<void> _addSimulatedAppointment({
    String? groupId,
    required String title,
    required String clientName,
    String? email,
    String? phoneNumber,
    required DateTime date,
    int durationMinutes = 60,
    String status = 'pending',
    int color = 0xFF8B5CF6,
    String? notes,
    double price = 0,
    int reminderMinutes = 30,
    DateTime? createdAt,
  }) async {
    final data = <String, dynamic>{
      'userId': _uid,
      'title': title,
      'clientName': clientName,
      'date': Timestamp.fromDate(date),
      'durationMinutes': durationMinutes,
      'status': status,
      'color': color,
      'price': price,
      'currency': 'TRY',
      'reminderMinutes': reminderMinutes,
      'recurrence': 'none',
      'createdAt': Timestamp.fromDate(createdAt ?? _daysAgo(1)),
    };
    if (groupId != null) data['groupId'] = groupId;
    if (email != null) data['email'] = email;
    if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
    if (notes != null) data['notes'] = notes;

    await db.collection('appointments').add(data);

    if (groupId != null && status != 'cancelled') {
      await _writeAppointmentSlot(groupId, date, status);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 8. KİTAPLAR — Yeni modül, kapsamlı veri
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _generateBooks() async {
    // Kitap tanımları
    final bookDefs = [
      {
        'googleBooksId': 'ol_kürk_mantolu',
        'title': 'Kürk Mantolu Madonna',
        'authors': ['Sabahattin Ali'],
        'pageCount': 174,
        'categories': ['Türk Edebiyatı', 'Roman'],
        'publishedDate': '1943',
        'status': 'read',
        'startDate': _daysAgo(85),
        'finishDate': _daysAgo(78),
        'currentPage': 174,
        'rating': 5,
        'notes': 'Sabahattin Ali\'nin en güçlü eseri. Maria\'nın karakteri unutulmaz. İkinci kez okudum, her seferinde yeni detaylar fark ediyorum.',
        'acquisitionDate': _daysAgo(90),
      },
      {
        'googleBooksId': 'ol_tutunamayanlar',
        'title': 'Tutunamayanlar',
        'authors': ['Oğuz Atay'],
        'pageCount': 724,
        'categories': ['Türk Edebiyatı', 'Roman', 'Modernizm'],
        'publishedDate': '1972',
        'status': 'reading',
        'startDate': _daysAgo(21),
        'currentPage': 287,
        'rating': 0,
        'notes': 'Çok yoğun bir metin. Türk edebiyatının dönüm noktası. Yavaş yavaş, defalarca okuyarak ilerliyorum.',
        'acquisitionDate': _daysAgo(25),
      },
      {
        'googleBooksId': 'ol_ince_memed',
        'title': 'İnce Memed',
        'authors': ['Yaşar Kemal'],
        'pageCount': 416,
        'categories': ['Türk Edebiyatı', 'Roman', 'Epik'],
        'publishedDate': '1955',
        'status': 'read',
        'startDate': _daysAgo(60),
        'finishDate': _daysAgo(48),
        'currentPage': 416,
        'rating': 5,
        'notes': 'Yaşar Kemal mucizesi. Çukurova\'nın ruhu sayfalara işlenmiş.',
        'acquisitionDate': _daysAgo(65),
      },
      {
        'googleBooksId': 'ol_atomic_habits',
        'title': 'Atomic Habits',
        'authors': ['James Clear'],
        'pageCount': 285,
        'categories': ['Kişisel Gelişim', 'Psikoloji', 'Üretkenlik'],
        'publishedDate': '2018',
        'status': 'reading',
        'startDate': _daysAgo(14),
        'currentPage': 168,
        'rating': 0,
        'notes': 'Her bölümden sonra gerçek hayata uygulayabileceğim bir şey öğreniyorum. Özellikle habit stacking kavramı çok güçlü.',
        'acquisitionDate': _daysAgo(20),
      },
      {
        'googleBooksId': 'ol_sapiens',
        'title': 'Sapiens: İnsan Türünün Kısa Tarihi',
        'authors': ['Yuval Noah Harari'],
        'pageCount': 512,
        'categories': ['Tarih', 'Bilim', 'Felsefe'],
        'publishedDate': '2011',
        'status': 'read',
        'startDate': _daysAgo(75),
        'finishDate': _daysAgo(55),
        'currentPage': 512,
        'rating': 4,
        'notes': 'İnsanlık tarihine bambaşka bir perspektiften bakış. Bazı iddialar tartışmalı ama genel olarak zihin açıcı.',
        'acquisitionDate': _daysAgo(80),
      },
      {
        'googleBooksId': 'ol_deep_work',
        'title': 'Deep Work: Derin Çalışma',
        'authors': ['Cal Newport'],
        'pageCount': 296,
        'categories': ['Üretkenlik', 'İş Dünyası'],
        'publishedDate': '2016',
        'status': 'read',
        'startDate': _daysAgo(45),
        'finishDate': _daysAgo(32),
        'currentPage': 296,
        'rating': 5,
        'notes': 'Bu kitaptan sonra sabah pomodoro rutinini başlattım. Çok dönüştürücü.',
        'acquisitionDate': _daysAgo(50),
      },
      {
        'googleBooksId': 'ol_yaban',
        'title': 'Yaban',
        'authors': ['Yakup Kadri Karaosmanoğlu'],
        'pageCount': 188,
        'categories': ['Türk Edebiyatı', 'Roman'],
        'publishedDate': '1932',
        'status': 'read',
        'startDate': _daysAgo(40),
        'finishDate': _daysAgo(36),
        'currentPage': 188,
        'rating': 4,
        'notes': 'Milli Edebiyat dönemi\'nin en güçlü örneği. Kurtuluş Savaşı\'nın aydın-halk çelişkisi.',
        'acquisitionDate': _daysAgo(42),
      },
      {
        'googleBooksId': 'ol_thinking_fast',
        'title': 'Düşünme — Hızlı ve Yavaş',
        'authors': ['Daniel Kahneman'],
        'pageCount': 499,
        'categories': ['Psikoloji', 'Davranışsal Ekonomi', 'Karar Alma'],
        'publishedDate': '2011',
        'status': 'to_read',
        'currentPage': 0,
        'rating': 0,
        'notes': 'Uzun süredir okuma listesinde. Bu ay başlayacağım.',
        'acquisitionDate': _daysAgo(10),
      },
      {
        'googleBooksId': 'ol_calipi',
        'title': 'Çalıkuşu',
        'authors': ['Reşat Nuri Güntekin'],
        'pageCount': 491,
        'categories': ['Türk Edebiyatı', 'Roman'],
        'publishedDate': '1922',
        'status': 'to_read',
        'currentPage': 0,
        'rating': 0,
        'notes': 'Annem\'in tavsiyesi. Mutlaka okuyacağım.',
        'acquisitionDate': _daysAgo(5),
      },
      {
        'googleBooksId': 'ol_show_your_work',
        'title': 'Show Your Work!',
        'authors': ['Austin Kleon'],
        'pageCount': 228,
        'categories': ['Yaratıcılık', 'Kişisel Gelişim'],
        'publishedDate': '2014',
        'status': 'lent',
        'startDate': _daysAgo(30),
        'currentPage': 130,
        'rating': 4,
        'lentTo': 'Can Öztürk',
        'lentDate': _daysAgo(8),
        'notes': 'Can\'a ödünç verdim. Yaratıcı süreç hakkında çok güzel.',
        'acquisitionDate': _daysAgo(35),
      },
    ];

    final bookRefs = <String>[];
    final slotMap = <String, String>{};

    for (int i = 0; i < bookDefs.length; i++) {
      final b = bookDefs[i];
      final Map<String, dynamic> data = {
        'userId': _uid,
        'googleBooksId': b['googleBooksId'],
        'title': b['title'],
        'authors': b['authors'],
        'pageCount': b['pageCount'],
        'categories': b['categories'],
        'publishedDate': b['publishedDate'] ?? '',
        'coverUrl': null, // API'den gelecek, simülasyonda boş
        'status': b['status'],
        'currentPage': b['currentPage'] ?? 0,
        'rating': b['rating'] ?? 0,
        'notes': b['notes'] ?? '',
        'acquisitionDate': b['acquisitionDate'] != null
            ? Timestamp.fromDate(b['acquisitionDate'] as DateTime)
            : null,
        'startDate': b['startDate'] != null
            ? Timestamp.fromDate(b['startDate'] as DateTime)
            : null,
        'finishDate': b['finishDate'] != null
            ? Timestamp.fromDate(b['finishDate'] as DateTime)
            : null,
        'lentTo': b['lentTo'],
        'lentDate': b['lentDate'] != null
            ? Timestamp.fromDate(b['lentDate'] as DateTime)
            : null,
      };

      final ref = await db
          .collection('users')
          .doc(_uid)
          .collection('user_books')
          .add(data);
      bookRefs.add(ref.id);
      slotMap[i.toString()] = ref.id;
    }

    // Raf isimlendirmesi (labelKey = row * 100 + section)
    final shelfLabels = {
      '0': 'Türk Edebiyatı Klasikleri',
      '1': '2025 Okuma Listesi',
      '100': 'Kişisel Gelişim',
      '101': 'Bilim & Tarih',
    };

    // Raf süsleri — boş slotlara
    final decorations = [
      {'slotIndex': 10, 'emoji': '🪴'},
      {'slotIndex': 11, 'emoji': '🏺'},
      {'slotIndex': 16, 'emoji': '🕯️'},
      {'slotIndex': 17, 'emoji': '📸'},
      {'slotIndex': 22, 'emoji': '🌵'},
      {'slotIndex': 23, 'emoji': '🔮'},
    ];

    // Raf tercihleri kaydet (slotMap + shelfLabels)
    await db.doc('users/$_uid/book_prefs/order').set({
      'slotMap': slotMap,
      'shelfLabels': shelfLabels,
    });

    // Süsler kaydet
    for (final d in decorations) {
      await db.collection('users').doc(_uid).collection('shelf_decorations').add({
        'userId': _uid,
        'slotIndex': d['slotIndex'],
        'emoji': d['emoji'],
      });
    }

    // Okuma hedefleri
    final goals = [
      {
        'userId': _uid,
        'title': '2025\'te 24 Kitap Oku',
        'type': 'yearly_books',
        'targetValue': 24,
        'year': _now.year,
        'month': null,
        'icon': '📚',
        'color': 0xFF6366F1,
        'createdAt': Timestamp.fromDate(_daysAgo(60)),
      },
      {
        'userId': _uid,
        'title': 'Bu Ay 3 Kitap Bitir',
        'type': 'monthly_books',
        'targetValue': 3,
        'year': _now.year,
        'month': _now.month,
        'icon': '🎯',
        'color': 0xFF10B981,
        'createdAt': Timestamp.fromDate(_daysAgo(20)),
      },
      {
        'userId': _uid,
        'title': 'Yılda 10.000 Sayfa',
        'type': 'yearly_pages',
        'targetValue': 10000,
        'year': _now.year,
        'month': null,
        'icon': '📄',
        'color': 0xFFF59E0B,
        'createdAt': Timestamp.fromDate(_daysAgo(55)),
      },
      {
        'userId': _uid,
        'title': 'Bu Ay 500 Sayfa',
        'type': 'monthly_pages',
        'targetValue': 500,
        'year': _now.year,
        'month': _now.month,
        'icon': '⭐',
        'color': 0xFFEC4899,
        'createdAt': Timestamp.fromDate(_daysAgo(10)),
      },
    ];

    for (final g in goals) {
      await db.collection('users').doc(_uid).collection('reading_goals').add(g);
    }

    // Alıntılar — her kitaptan güzel cümleler
    final quotes = [
      {
        'userBookId': bookRefs[0],
        'bookTitle': 'Kürk Mantolu Madonna',
        'text': 'İnsanlar kendilerini çok iyi tanıdıklarını sanırlar. Halbuki hepimiz, içimizdeki o meçhulü taşıyoruz.',
        'page': 87,
        'color': 0xFF6366F1,
        'isPinned': true,
      },
      {
        'userBookId': bookRefs[0],
        'bookTitle': 'Kürk Mantolu Madonna',
        'text': 'Aşk, insanı kendinden çekip uzaklaştıran bir kuvvettir; fakat bazen bu uzaklaşma, insanın kendine dönüşüdür.',
        'page': 134,
        'color': 0xFF6366F1,
        'isPinned': false,
      },
      {
        'userBookId': bookRefs[3],
        'bookTitle': 'Atomic Habits',
        'text': 'You do not rise to the level of your goals. You fall to the level of your systems.',
        'page': 27,
        'color': 0xFF10B981,
        'isPinned': true,
      },
      {
        'userBookId': bookRefs[3],
        'bookTitle': 'Atomic Habits',
        'text': 'Every action you take is a vote for the type of person you wish to become.',
        'page': 38,
        'color': 0xFF10B981,
        'isPinned': false,
      },
      {
        'userBookId': bookRefs[4],
        'bookTitle': 'Sapiens',
        'text': 'Tarih, iyi insanlar için seçici değildir. Başarılı olanlar için seçicidir.',
        'page': 203,
        'color': 0xFFF59E0B,
        'isPinned': false,
      },
      {
        'userBookId': bookRefs[5],
        'bookTitle': 'Deep Work',
        'text': 'The ability to perform deep work is becoming increasingly rare at exactly the same time it is becoming increasingly valuable.',
        'page': 14,
        'color': 0xFF3B82F6,
        'isPinned': true,
      },
      {
        'userBookId': bookRefs[5],
        'bookTitle': 'Deep Work',
        'text': 'Clarity about what matters provides clarity about what does not.',
        'page': 196,
        'color': 0xFF3B82F6,
        'isPinned': false,
      },
      {
        'userBookId': bookRefs[2],
        'bookTitle': 'İnce Memed',
        'text': 'Yiğit adam korkar, ama korkmadığını gösterir. Korkak adam da korkar, ama korkmadığını gösteremez.',
        'page': 156,
        'color': 0xFFEF4444,
        'isPinned': false,
      },
    ];

    for (final q in quotes) {
      await db.collection('users').doc(_uid).collection('book_quotes').add({
        'userId': _uid,
        'userBookId': q['userBookId'],
        'bookTitle': q['bookTitle'],
        'text': q['text'],
        'page': q['page'],
        'color': q['color'],
        'isPinned': q['isPinned'],
        'createdAt': Timestamp.fromDate(_daysAgo(_rng.nextInt(30))),
      });
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 9. PLAN PANOSU — 2 pano, 14 not, 10 bağlantı
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _generateCorkboard() async {
    final mainBoard = await db.collection('corkboard_boards').add({
      'userId': _uid,
      'title': 'Ürün & Teknik',
      'sortOrder': 0,
      'createdAt': Timestamp.fromDate(_daysAgo(60)),
    });
    final ideasBoard = await db.collection('corkboard_boards').add({
      'userId': _uid,
      'title': 'Fikirler & OKR',
      'sortOrder': 1,
      'createdAt': Timestamp.fromDate(_daysAgo(45)),
    });

    const cx = 3500.0;
    const cy = 3500.0;

    final items = [
      {'content': 'Phobes v3.0 Vizyon\n\n• Yapay zeka odaklı\n• Çapraz platform\n• Kitap modülü ✅\n• Takım işbirliği\n• Gelişmiş analitik', 'posX': cx, 'posY': cy - 250, 'color': 0xFFE3F2FD, 'rotation': 0.02},
      {'content': 'Nova AI Hafıza Sistemi\n\nSorun: Kısa context window\nÇözüm önerileri:\n→ Vektör DB (Pinecone?)\n→ RAG pipeline\n→ Conversation summary\n→ Long-term memory store', 'posX': cx - 300, 'posY': cy - 180, 'color': 0xFFFFFDE7, 'rotation': -0.06},
      {'content': 'Kullanıcı Araştırması Sonuçları\n\n→ #1 istek: Offline mod\n→ #2 istek: Daha iyi widget\n→ #3 istek: Tema seçeneği\n→ Pain point: Navigasyon\n→ NPS Skoru: 74 🎯\n→ App Store: 4.6★', 'posX': cx + 300, 'posY': cy - 160, 'color': 0xFFE8F5E9, 'rotation': -0.08},
      {'content': 'Teknik Borç\n\n⚡ Kritik:\n- MainNavigation bölünmeli\n- Admin client-side check\n\n📌 Orta:\n- Distributed rate limiting\n- Offline mod\n- Performance profiling\n\n✅ Tamamlanan:\n- Stream leak\'ler\n- N+1 query fix\n- Firestore rules', 'posX': cx - 320, 'posY': cy + 120, 'color': 0xFFFCE4EC, 'rotation': 0.07},
      {'content': 'Q3 2025 OKR\n\nO: Kullanıcı büyümesini artır\n\nKR1: DAU %40 büyüme\nKR2: Churn < %3\nKR3: App Store 4.8★\nKR4: Kitap modülü MAU 1000+', 'posX': cx + 50, 'posY': cy + 100, 'color': 0xFFF3E5F5, 'rotation': -0.03},
      {'content': 'Rakip Analiz 2025\n\nNotion ✗ Mobil zayıf\nTodoist ✗ AI yok\nObsidian ✗ Karmaşık\nGoodreads ✗ Modül değil\n\nPhobes ✓ Hepsi bir arada\nPhobes ✓ AI entegre\nPhobes ✓ Türkçe önce\nPhobes ✓ Kitaplık sistemi', 'posX': cx + 330, 'posY': cy + 170, 'color': 0xFFFAFAFA, 'rotation': 0.09},
      {'content': 'Kitap Modülü Roadmap\n\nFaz 1 (Tamamlandı) ✅\n- Temel CRUD\n- Sürükle-bırak raf\n- Google Books + Open Library\n\nFaz 2 (Devam ediyor) 🔄\n- AI kitap özeti (Nova)\n- Sosyal özellikler\n- Barkod okuyucu\n\nFaz 3 (Planlı)\n- Kitap takası\n- AR raf görünümü', 'posX': cx - 280, 'posY': cy + 310, 'color': 0xFFE8EAF6, 'rotation': -0.04},
      {'content': 'Sprint Blocker\'lar\n\n🔴 BLOCKER:\n1. Firestore index hatası — çözüldü ✅\n2. AR destekli raf — araştırma aşamasında\n\n🟡 RISK:\n1. Open Library API rate limit\n2. Drag & drop mobil performans\n\n🟢 GİDEN:\nKitap raf sistemi production\'da!', 'posX': cx + 320, 'posY': cy - 300, 'color': 0xFFFFF8E1, 'rotation': 0.05},
      {'content': 'Öğrenme Notları\n\n📚 Bu Ay Okunanlar:\n1. Kürk Mantolu Madonna ★★★★★\n2. İnce Memed ★★★★★\n3. Sapiens ★★★★\n4. Deep Work ★★★★★\n\n💡 Önemli Çıkarım:\n"Deep work kapasitesi değerli\n olduğu kadar nadir."', 'posX': cx - 50, 'posY': cy + 280, 'color': 0xFFE0F7FA, 'rotation': -0.07},
      {'content': 'Motivasyon\n\n"You do not rise to the\nlevel of your goals.\nYou fall to the level\nof your systems."\n\n— James Clear, Atomic Habits\n\n🎯 Phobes = Sistem Kurucusu', 'posX': cx + 100, 'posY': cy - 320, 'color': 0xFFE8F5E9, 'rotation': 0.03},
      {'content': 'Randevu Modülü\n\n✅ Hizmet grupları\n✅ Slot yönetimi\n🔄 Web boş durum UI\n🔄 Randevularım kişisel\n\n→ Takvim entegrasyonu', 'posX': cx - 120, 'posY': cy - 400, 'color': 0xFFE1F5FE, 'rotation': 0.04},
      {'content': 'Simülasyon v2\n\n• 90 gün görev/not\n• Randevu + müşteri CRM\n• 2 plan panosu\n• Kitap kulübü verisi', 'posX': cx + 420, 'posY': cy + 40, 'color': 0xFFFFF3E0, 'rotation': -0.05},
      {'content': 'Q4 Hedef Taslağı\n\n1. Offline-first notlar\n2. Widget v2\n3. Nova kitap özeti\n4. Enterprise ekip paketi', 'posX': cx - 500, 'posY': cy - 60, 'color': 0xFFF3E5F5, 'rotation': -0.02},
    ];

    final itemIds = <String>[];
    for (int i = 0; i < items.length; i++) {
      final it = items[i];
      final boardId = i < 10 ? mainBoard.id : ideasBoard.id;
      final doc = await db.collection('corkboard_items').add({
        'userId': _uid,
        'boardId': boardId,
        'type': 'note',
        'content': it['content'],
        'posX': it['posX'],
        'posY': it['posY'],
        'rotation': it['rotation'],
        'color': it['color'],
        'size': 200.0 + (i % 3) * 20,
        'createdAt': Timestamp.fromDate(_daysAgo(_rng.nextInt(30))),
      });
      itemIds.add(doc.id);
    }

    final connections = [
      (0, 1, 0xFFE53935, 2.5),
      (0, 2, 0xFF1E88E5, 2.0),
      (0, 4, 0xFF43A047, 2.5),
      (0, 6, 0xFF8E24AA, 2.0),
      (1, 3, 0xFFFFB300, 2.0),
      (2, 5, 0xFF8E24AA, 1.5),
      (4, 3, 0xFFE53935, 1.5),
      (6, 8, 0xFF1E88E5, 1.5),
      (9, 8, 0xFF43A047, 1.5),
      (10, 0, 0xFF26A69A, 2.0),
      (11, 6, 0xFF5C6BC0, 1.5),
    ];

    for (final (fi, ti, color, thickness) in connections) {
      if (fi < itemIds.length && ti < itemIds.length) {
        final boardId = fi < 10 ? mainBoard.id : ideasBoard.id;
        await db.collection('corkboard_connections').add({
          'userId': _uid,
          'boardId': boardId,
          'fromId': itemIds[fi],
          'toId': itemIds[ti],
          'color': color,
          'thickness': thickness,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 10. BİLDİRİMLER — 25+ bildirim, çeşitli türler
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _generateNotifications() async {
    final notifs = [
      // Sistem
      (AppNotification(userId: _uid, title: '🎉 Test Verisi Hazır!', body: 'Tüm modüller için 3 aylık gerçekçi veri yüklendi. Kitaplar, bildirimler, bütçe ve daha fazlası!', type: 'system', icon: '🚀', createdAt: _now), false),
      (AppNotification(userId: _uid, title: '⭐ Yeni Seviye: 22', body: '23.750 XP ile 22. seviyeye ulaştın! Harika bir ilerleme — böyle devam!', type: 'system', icon: '⭐', createdAt: _daysAgo(2)), true),
      (AppNotification(userId: _uid, title: '🎂 Uygulama Yıldönümü!', body: 'Phobes\'i kullanmaya başladığının üzerinden 1 yıl geçti. Teşekkürler!', type: 'system', icon: '🎂', createdAt: _daysAgo(5)), true),
      (AppNotification(userId: _uid, title: '📊 Haftalık Rapor Hazır', body: 'Bu hafta 23 görev tamamlandı, bütçe hedeflerinin %87\'sindesin. İstatistikler sekmesine bak!', type: 'system', icon: '📈', createdAt: _daysAgo(3)), false),
      // Alışkanlıklar
      (AppNotification(userId: _uid, title: '🔥 42 Günlük Seri!', body: 'Sabah Meditasyonu alışkanlığında 42 gün serisi devam ediyor. Muhteşem!', type: 'habit', icon: '🧘', createdAt: _daysAgo(1)), false),
      (AppNotification(userId: _uid, title: '💧 61 Günlük Seri!', body: 'Günlük 2L Su alışkanlığında 61 gün seri! Hiç kırılmadı — inanılmaz disiplin.', type: 'habit', icon: '💧', createdAt: _daysAgo(2)), true),
      (AppNotification(userId: _uid, title: '⚠️ Seri Tehlikede!', body: '2 alışkanlık serisi risk altında. Tamamlamak için hâlâ vakit var!', type: 'habit', icon: '🔥', createdAt: _now), false),
      (AppNotification(userId: _uid, title: '🌍 30 Günlük Seri!', body: 'Yabancı Dil Çalışma alışkanlığında 30 gün seri kutlaması!', type: 'habit', icon: '🌍', createdAt: _daysAgo(4)), true),
      // İlaçlar
      (AppNotification(userId: _uid, title: '⚠️ İlaç Stok Uyarısı', body: 'B12 Vitamini stoğu kritik seviyede (8 adet). Yenilemeyi unutmayın!', type: 'medication', icon: '💊', createdAt: _daysAgo(1)), false),
      (AppNotification(userId: _uid, title: '💊 İlaç Vakti!', body: 'Saat 08:00 — D3 Vitamini alma zamanı.', type: 'medication', icon: '☀️', createdAt: _now), false),
      (AppNotification(userId: _uid, title: '💊 Akşam Dozu', body: 'Omega-3 akşam dozunu almayı unutma — saat 21:00.', type: 'medication', icon: '🐟', createdAt: _daysAgo(1)), true),
      // Görevler
      (AppNotification(userId: _uid, title: '📋 Görev Süresi Doldu', body: '"Vergi Beyannamesi" görevi bu hafta sona eriyor. Muhasebeci randevusunu ayarla!', type: 'task', icon: '📋', createdAt: _daysAgo(1)), false),
      (AppNotification(userId: _uid, title: '✅ Görev Tamamlandı', body: '"Flutter Web Deployment" görevi başarıyla tamamlandı. +50 XP!', type: 'task', icon: '✅', createdAt: _daysAgo(3)), true),
      (AppNotification(userId: _uid, title: '📋 Yeni Görev Atandı', body: '"Nova AI Context Window" görevi sana atandı — Broadway Yazılım Ekibi', type: 'task', icon: '📋', createdAt: _daysAgo(2)), true),
      // Randevular
      (AppNotification(userId: _uid, title: '📅 Yarın: Diş Hekimi', body: 'Yarın saat 11:00\'de Dr. Elif Şahin randevunuz var. 30 dk önce hatırlatıcı kuruldu.', type: 'appointment', icon: '🦷', createdAt: _now), false),
      (AppNotification(userId: _uid, title: '✅ Randevu Onaylandı', body: 'Selin Çelik Flutter danışmanlık randevusunu onayladı — yarın 14:00.', type: 'appointment', icon: '✅', createdAt: _daysAgo(1)), true),
      (AppNotification(userId: _uid, title: '❌ Randevu İptal', body: 'Burak Koç bugünkü danışmanlık randevusunu iptal etti.', type: 'appointment', icon: '❌', createdAt: _daysAgo(2)), true),
      (AppNotification(userId: _uid, title: '📅 Kan Tahlili Hatırlatması', body: '5 gün sonra Medipol Lab randevunuz var. Hazırlıkları yapın.', type: 'appointment', icon: '🏥', createdAt: _now), false),
      // Bütçe
      (AppNotification(userId: _uid, title: '⚠️ Market Limiti Aşılıyor', body: 'Market kategorisinde limitin %92\'sine ulaştın (4.600₺/5.000₺). Dikkatli ol!', type: 'budget', icon: '🛒', createdAt: _daysAgo(1)), false),
      (AppNotification(userId: _uid, title: '🎯 MacBook Hedefi: %75!', body: 'MacBook Pro M4 birikiminde 71.500₺\'ye ulaştın. Hedefe 23.500₺ kaldı!', type: 'budget', icon: '💻', createdAt: _daysAgo(3)), true),
      (AppNotification(userId: _uid, title: '💰 Aylık Maaş Geldi', body: 'Yazılım danışmanlığı geliri hesabınıza yatırıldı.', type: 'budget', icon: '💰', createdAt: _daysAgo(7)), true),
      // Takımlar
      (AppNotification(userId: _uid, title: '🚀 Sprint #15 Başladı', body: 'Broadway Yazılım Ekibi sprint\'i başladı. Kitap modülü öncelikli — koşa koşa!', type: 'team', icon: '🚀', createdAt: _daysAgo(7)), true),
      (AppNotification(userId: _uid, title: '📢 Yeni Takım Duyurusu', body: 'Kreatif Tasarım Atölyesi: Kitap rafı ahşap doku güncellemesi hazır. Kontrol et!', type: 'team', icon: '🎨', createdAt: _daysAgo(2)), true),
      // Kitaplar
      (AppNotification(userId: _uid, title: '📚 Okuma Hedefi: %58', body: '2025 yılı kitap hedefinde 14/24 kitap tamamlandı. Çok iyi gidiyor!', type: 'habit', icon: '📚', createdAt: _daysAgo(5)), true),
      (AppNotification(userId: _uid, title: '💬 Alıntı Günün', body: '"You do not rise to the level of your goals. You fall to the level of your systems." — Atomic Habits', type: 'system', icon: '💬', createdAt: _daysAgo(1)), false),
    ];

    for (final (notif, isRead) in notifs) {
      final map = notif.toMap();
      map['isRead'] = isRead;
      await db.collection('users').doc(_uid).collection('notifications').add(map);
    }
  }

  // ── Yardımcılar ───────────────────────────────────────────────────────────

  List<String> _projectTaskTitles(String projectName) {
    if (projectName.contains('Flutter') || projectName.contains('App')) {
      return ['Responsive breakpoint analizi', 'Web layout düzeltmeleri', 'Stream leak fix', 'Unit test yazma', 'Code review', 'Deploy pipeline güncelle', 'Performans profiling', 'Bug triaj toplantısı'];
    } else if (projectName.contains('Nova') || projectName.contains('AI')) {
      return ['RAG pipeline tasarımı', 'Context builder optimizasyonu', 'Kitap özeti entegrasyonu', 'Prompt mühendisliği', 'A/B test kurulumu'];
    } else if (projectName.contains('Tasarım') || projectName.contains('Marka')) {
      return ['Renk paleti belirleme', 'Logo varyantları hazırla', 'Tipografi testi', 'Figma component library', 'Kitap rafı ahşap doku'];
    } else if (projectName.contains('İçerik') || projectName.contains('Kampanya')) {
      return ['Blog yazısı — Kitap Modülü tanıtımı', 'Sosyal medya görselleri', 'Email newsletter', 'App Store ekran görüntüleri', 'YouTube demo video'];
    } else {
      return ['Proje kickoff toplantısı', 'Gereksinimleri topla', 'Zaman planı hazırla', 'Risk analizi', 'Paydaş sunumu'];
    }
  }
}
