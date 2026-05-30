import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/budget_period_utils.dart';
import '../models/budget_model.dart';
import 'notification_service.dart';

/// Handles all transaction CRUD + atomic account balance updates + limit checks.
class BudgetTransactionService {
  static final BudgetTransactionService _instance =
      BudgetTransactionService._internal();
  factory BudgetTransactionService() => _instance;
  BudgetTransactionService._internal();

  final _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ── CRUD ────────────────────────────────────────────────────────────────────

  Future<void> addTransaction(BudgetTransaction tx,
      {String? limitExceededTitle,
      String? limitApproachingTitle,
      String? currencyLabel,}) async {
    if (_uid == null) return;

    if (tx.type == TransactionType.expense) {
      final blocked = await _wouldExceedBudgetLimit(tx.category, tx.amount);
      if (blocked) {
        throw Exception('BUDGET_LIMIT_EXCEEDED');
      }
    }

    if (tx.accountId != null) {
      await _db.runTransaction((t) async {
        final accountRef = _db.collection('budget_accounts').doc(tx.accountId);
        final accountDoc = await t.get(accountRef);
        if (!accountDoc.exists) {
          throw Exception('Hesap bulunamadı: ${tx.accountId}');
        }
        if (accountDoc.data()?['userId'] != _uid) {
          throw Exception('Bu hesaba işlem ekleme yetkiniz yok.');
        }
        final account = Account.fromFirestore(accountDoc);
        double newBalance = account.balance;
        if (tx.type == TransactionType.income) {
          newBalance += tx.amount;
        } else if (tx.type == TransactionType.expense) {
          newBalance -= tx.amount;
        } else if (tx.type == TransactionType.transfer &&
            tx.toAccountId != null) {
          newBalance -= tx.amount;
          final toRef = _db.collection('budget_accounts').doc(tx.toAccountId);
          final toDoc = await t.get(toRef);
          if (!toDoc.exists) {
            throw Exception('Hedef hesap bulunamadı: ${tx.toAccountId}');
          }
          if (toDoc.data()?['userId'] != _uid) {
            throw Exception('Hedef hesaba transfer yetkiniz yok.');
          }
          final toAccount = Account.fromFirestore(toDoc);
          t.update(toRef, {'balance': toAccount.balance + tx.amount});
        }
        t.update(accountRef, {'balance': newBalance});
        t.set(_db.collection('budget_transactions').doc(), tx.toMap());
      });
    } else {
      await _db.collection('budget_transactions').add(tx.toMap());
    }

    if (tx.type == TransactionType.expense) {
      await _checkBudgetLimit(tx.category,
          limitExceededTitle: limitExceededTitle,
          limitApproachingTitle: limitApproachingTitle,
          currencyLabel: currencyLabel,);
    }
  }

  Stream<List<BudgetTransaction>> getTransactionsStream() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection('budget_transactions')
        .where('userId', isEqualTo: _uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => BudgetTransaction.fromFirestore(d)).toList(),);
  }

  Future<void> updateTransaction(BudgetTransaction tx) async {
    if (tx.id == null || _uid == null) return;
    final doc = await _db.collection('budget_transactions').doc(tx.id).get();
    if (!doc.exists) return;
    final old = BudgetTransaction.fromFirestore(doc);
    if (old.userId != _uid) return;
    await replaceTransaction(old, tx.copyWith(id: old.id));
  }

  /// Atomically deletes a transaction and reverses its effect on account balance.
  Future<void> deleteTransaction(String txId) async {
    final txRef = _db.collection('budget_transactions').doc(txId);
    await _db.runTransaction((t) async {
      final txDoc = await t.get(txRef);
      if (!txDoc.exists) return;
      final tx = BudgetTransaction.fromFirestore(txDoc);
      if (tx.userId != _uid) return;
      if (tx.accountId != null) {
        final accRef = _db.collection('budget_accounts').doc(tx.accountId);
        final accDoc = await t.get(accRef);
        if (!accDoc.exists || accDoc.data()?['userId'] != _uid) return;
        final account = Account.fromFirestore(accDoc);
        double reversed = account.balance;
        if (tx.type == TransactionType.income) {
          reversed -= tx.amount;
        } else if (tx.type == TransactionType.expense) {
          reversed += tx.amount;
        } else if (tx.type == TransactionType.transfer &&
            tx.toAccountId != null) {
          reversed += tx.amount;
          final toRef = _db.collection('budget_accounts').doc(tx.toAccountId);
          final toDoc = await t.get(toRef);
          if (!toDoc.exists || toDoc.data()?['userId'] != _uid) return;
          final toAcc = Account.fromFirestore(toDoc);
          t.update(toRef, {'balance': toAcc.balance - tx.amount});
        }
        t.update(accRef, {'balance': reversed});
      }
      t.delete(txRef);
    });
  }

  Future<void> replaceTransaction(BudgetTransaction old, BudgetTransaction updated,
      {String? limitExceededTitle,
      String? limitApproachingTitle,
      String? currencyLabel,}) async {
    if (old.id == null || _uid == null) return;

    if (updated.type == TransactionType.expense) {
      final delta = updated.amount - (old.type == TransactionType.expense ? old.amount : 0);
      if (delta > 0) {
        final blocked =
            await _wouldExceedBudgetLimit(updated.category, delta);
        if (blocked) throw Exception('BUDGET_LIMIT_EXCEEDED');
      }
    }

    // Atomik: sil + ekle tek bir Firestore transaction içinde yapılır.
    // İki ayrı çağrı kullanıldığında, silme başarılı olup ekleme başarısız olursa veri kaybolur.
    await _db.runTransaction((t) async {
      final oldRef = _db.collection('budget_transactions').doc(old.id);
      final oldDoc = await t.get(oldRef);
      if (!oldDoc.exists) return;

      // Eski işlemin hesap üzerindeki etkisini geri al
      if (old.userId != _uid) return;

      if (old.accountId != null) {
        final accRef = _db.collection('budget_accounts').doc(old.accountId);
        final accDoc = await t.get(accRef);
        if (accDoc.exists && accDoc.data()?['userId'] == _uid) {
          final account = Account.fromFirestore(accDoc);
          double bal = account.balance;
          if (old.type == TransactionType.income) {
            bal -= old.amount;
          } else if (old.type == TransactionType.expense) {
            bal += old.amount;
          } else if (old.type == TransactionType.transfer && old.toAccountId != null) {
            bal += old.amount;
            final toRef = _db.collection('budget_accounts').doc(old.toAccountId);
            final toDoc = await t.get(toRef);
            if (toDoc.exists) {
              final toAcc = Account.fromFirestore(toDoc);
              t.update(toRef, {'balance': toAcc.balance - old.amount});
            }
          }
          t.update(accRef, {'balance': bal});
        }
      }

      // Yeni işlemin hesap üzerindeki etkisini uygula
      if (updated.accountId != null) {
        final accRef = _db.collection('budget_accounts').doc(updated.accountId);
        final accDoc = await t.get(accRef);
        if (!accDoc.exists || accDoc.data()?['userId'] != _uid) {
          throw Exception('Geçersiz hesap.');
        }
        if (accDoc.exists) {
          final account = Account.fromFirestore(accDoc);
          double bal = account.balance;
          if (updated.type == TransactionType.income) {
            bal += updated.amount;
          } else if (updated.type == TransactionType.expense) {
            bal -= updated.amount;
          } else if (updated.type == TransactionType.transfer && updated.toAccountId != null) {
            bal -= updated.amount;
            final toRef = _db.collection('budget_accounts').doc(updated.toAccountId);
            final toDoc = await t.get(toRef);
            if (toDoc.exists) {
              final toAcc = Account.fromFirestore(toDoc);
              t.update(toRef, {'balance': toAcc.balance + updated.amount});
            }
          }
          t.update(accRef, {'balance': bal});
        }
      }

      // Eski dokümanı güncelle (silip yeni eklemek yerine güncelle)
      t.update(oldRef, updated.copyWith(id: old.id).toMap());
    });

    if (updated.type == TransactionType.expense) {
      await _checkBudgetLimit(updated.category,
          limitExceededTitle: limitExceededTitle,
          limitApproachingTitle: limitApproachingTitle,
          currencyLabel: currencyLabel,);
    }
  }

  Future<Map<String, double>> getCategoryTotals(TransactionType type) async {
    if (_uid == null) return {};
    final snapshot = await _db
        .collection('budget_transactions')
        .where('userId', isEqualTo: _uid)
        .where('type', isEqualTo: type.name)
        .get();
    final totals = <String, double>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final category = data['category'] ?? 'Genel';
      totals[category] =
          (totals[category] ?? 0) + (data['amount'] as num).toDouble();
    }
    return totals;
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  /// Returns true if adding [amount] would meet or exceed the monthly limit.
  Future<bool> _wouldExceedBudgetLimit(String category, double amount) async {
    if (_uid == null || amount <= 0) return false;
    try {
      final limitsSnap = await _db
          .collection('budget_limits')
          .where('userId', isEqualTo: _uid)
          .where('category', isEqualTo: category)
          .limit(1)
          .get();
      if (limitsSnap.docs.isEmpty) return false;
      final limit = BudgetLimit.fromFirestore(limitsSnap.docs.first);
      final periodStart =
          BudgetPeriodUtils.periodStart(limit.period);
      final txSnap = await _db
          .collection('budget_transactions')
          .where('userId', isEqualTo: _uid)
          .where('type', isEqualTo: TransactionType.expense.name)
          .where('category', isEqualTo: category)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(periodStart),)
          .get();
      var totalSpent = 0.0;
      for (final doc in txSnap.docs) {
        totalSpent += (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
      }
      return totalSpent + amount > limit.limitAmount;
    } catch (e) {
      debugPrint('[BudgetTransactionService] limit precheck error: $e');
      return true;
    }
  }

  Future<void> _checkBudgetLimit(String category,
      {String? limitExceededTitle,
      String? limitApproachingTitle,
      String? currencyLabel,}) async {
    if (_uid == null) return;
    try {
      final limitsSnap = await _db
          .collection('budget_limits')
          .where('userId', isEqualTo: _uid)
          .where('category', isEqualTo: category)
          .get();
      if (limitsSnap.docs.isEmpty) return;

      final limit = BudgetLimit.fromFirestore(limitsSnap.docs.first);
      final periodStart =
          BudgetPeriodUtils.periodStart(limit.period);
      final txSnap = await _db
          .collection('budget_transactions')
          .where('userId', isEqualTo: _uid)
          .where('type', isEqualTo: TransactionType.expense.name)
          .where('category', isEqualTo: category)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(periodStart),)
          .get();

      double totalSpent = 0;
      for (final doc in txSnap.docs) {
        totalSpent += (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
      }
      final ratio = limit.limitAmount > 0 ? totalSpent / limit.limitAmount : 0.0;
      if (ratio >= 1.0) {
        await NotificationService().sendNotification(
          title: limitExceededTitle ?? 'Budget Limit Exceeded! 🚨',
          body:
              '$category: ${totalSpent.toStringAsFixed(0)} / ${limit.limitAmount.toStringAsFixed(0)} ${currencyLabel ?? 'TL'}',
          type: 'budget',
          icon: '🚨',
          color: 0xFFF44336,
          prefKey: 'notif_budget_limit',
        );
      } else if (ratio >= 0.8) {
        await NotificationService().sendNotification(
          title: limitApproachingTitle ?? 'Approaching Budget Limit! ⚠️',
          body:
              '$category: ${totalSpent.toStringAsFixed(0)} / ${limit.limitAmount.toStringAsFixed(0)} ${currencyLabel ?? 'TL'} (%${(ratio * 100).toStringAsFixed(0)})',
          type: 'budget',
          icon: '⚠️',
          color: 0xFFFF9800,
          prefKey: 'notif_budget_limit',
        );
      }
    } catch (e) {
      debugPrint('[BudgetTransactionService] limit check error: $e');
    }
  }
}
