import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/budget_model.dart';
import 'notification_service.dart';

/// Handles debts, budget limits and savings goals.
class BudgetDebtService {
  static final BudgetDebtService _instance = BudgetDebtService._internal();
  factory BudgetDebtService() => _instance;
  BudgetDebtService._internal();

  final _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ── Debts ────────────────────────────────────────────────────────────────────

  Stream<List<Debt>> getDebtsStream() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection('budget_debts')
        .where('userId', isEqualTo: _uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Debt.fromFirestore(d)).toList());
  }

  Future<void> addDebt(Debt debt) async {
    if (_uid == null) return;
    await _db.collection('budget_debts').add(debt.toMap());
  }

  Future<void> updateDebt(Debt debt) async {
    if (debt.id == null || _uid == null) return;
    final doc = await _db.collection('budget_debts').doc(debt.id).get();
    if (!doc.exists || doc.data()?['userId'] != _uid) return;
    await _db.collection('budget_debts').doc(debt.id).update({
      'personName': debt.personName,
      'type': debt.type.name,
      'date': Timestamp.fromDate(debt.date),
      'dueDate': debt.dueDate != null ? Timestamp.fromDate(debt.dueDate!) : null,
      'isPaid': debt.isPaid,
      'description': debt.description,
    });
  }

  Future<void> deleteDebt(String debtId) async {
    await _db.collection('budget_debts').doc(debtId).delete();
  }

  // ── Budget Limits ────────────────────────────────────────────────────────────

  Stream<List<BudgetLimit>> getLimitsStream() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection('budget_limits')
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((s) => s.docs.map((d) => BudgetLimit.fromFirestore(d)).toList());
  }

  Future<void> addLimit(BudgetLimit limit) async {
    if (_uid == null) return;
    await _db.collection('budget_limits').add(limit.toMap());
  }

  Future<void> updateLimit(BudgetLimit limit) async {
    if (limit.id != null) {
      await _db
          .collection('budget_limits')
          .doc(limit.id)
          .update(limit.toMap());
    }
  }

  Future<void> deleteLimit(String id) async {
    await _db.collection('budget_limits').doc(id).delete();
  }

  // ── Savings Goals ────────────────────────────────────────────────────────────

  Stream<List<SavingsGoal>> getGoalsStream() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection('savings_goals')
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((s) => s.docs.map((d) => SavingsGoal.fromFirestore(d)).toList());
  }

  Future<void> addGoal(SavingsGoal goal) async {
    if (_uid == null) return;
    await _db.collection('savings_goals').add(goal.toMap());
  }

  Future<void> updateGoalMetadata(SavingsGoal goal) async {
    if (goal.id == null || _uid == null) return;
    final doc = await _db.collection('savings_goals').doc(goal.id).get();
    if (!doc.exists || doc.data()?['userId'] != _uid) return;
    await _db.collection('savings_goals').doc(goal.id).update({
      'title': goal.title,
      'targetAmount': goal.targetAmount,
      'deadline': goal.deadline != null ? Timestamp.fromDate(goal.deadline!) : null,
      'icon': goal.icon,
    });
  }

  Future<void> updateGoalProgress(SavingsGoal goal) async {
    if (goal.id == null || _uid == null) return;
    final doc = await _db.collection('savings_goals').doc(goal.id).get();
    if (!doc.exists || doc.data()?['userId'] != _uid) return;
    await _db.collection('savings_goals').doc(goal.id).update({
      'currentAmount': goal.currentAmount,
    });
  }

  Future<void> updateGoal(
    SavingsGoal goal, {
    String? goalCompleteTitle,
    String? goalCompleteBody,
    String? goalAlmostTitle,
    String? goalAlmostBody,
    String? goalHalfwayTitle,
    String? goalHalfwayBody,
  }) async {
    if (goal.id == null) return;
    final existing = await _db.collection('savings_goals').doc(goal.id).get();
    if (!existing.exists) return;
    final prev = SavingsGoal.fromFirestore(existing);
    final metaChanged = goal.title != prev.title ||
        goal.targetAmount != prev.targetAmount ||
        goal.deadline != prev.deadline ||
        goal.icon != prev.icon;
    if (metaChanged) {
      await updateGoalMetadata(goal);
    }
    if (goal.currentAmount != prev.currentAmount) {
      await updateGoalProgress(goal);
    }

    final ratio =
        goal.targetAmount > 0 ? goal.currentAmount / goal.targetAmount : 0.0;
    final pct = (ratio * 100).toStringAsFixed(0);

    if (ratio >= 1.0) {
      await NotificationService().sendNotification(
        title: goalCompleteTitle ?? 'Savings Goal Reached! 🎉',
        body: goalCompleteBody ?? '${goal.title} goal achieved!',
        type: 'budget',
        icon: '🏆',
        color: 0xFF4CAF50,
        prefKey: 'notif_budget_goal',
      );
    } else if (ratio >= 0.75) {
      await NotificationService().sendNotification(
        title: goalAlmostTitle ?? 'Almost There! 💪',
        body: goalAlmostBody ?? '${goal.title} — $pct% complete',
        type: 'budget',
        icon: '💪',
        color: 0xFFFF9800,
        prefKey: 'notif_budget_goal',
      );
    } else if (ratio >= 0.5) {
      await NotificationService().sendNotification(
        title: goalHalfwayTitle ?? 'Halfway There! 🚀',
        body: goalHalfwayBody ?? '${goal.title} — $pct% complete',
        type: 'budget',
        icon: '🚀',
        color: 0xFF2196F3,
        prefKey: 'notif_budget_goal',
      );
    }
  }

  Future<void> deleteGoal(String id) async {
    await _db.collection('savings_goals').doc(id).delete();
  }
}
