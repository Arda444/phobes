import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/budget_model.dart';
import 'currency_service.dart';

/// Handles bank/cash accounts and investment assets.
class BudgetAccountService {
  static final BudgetAccountService _instance =
      BudgetAccountService._internal();
  factory BudgetAccountService() => _instance;
  BudgetAccountService._internal();

  final _db = FirebaseFirestore.instance;
  final _currencyService = CurrencyService();
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ── Accounts ─────────────────────────────────────────────────────────────────

  Stream<List<Account>> getAccountsStream() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection('budget_accounts')
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((s) => s.docs.map((d) => Account.fromFirestore(d)).toList());
  }

  Future<void> addAccount(Account account) async {
    if (_uid == null) return;
    await _db.collection('budget_accounts').add(account.toMap());
  }

  Future<void> updateAccount(Account account) async {
    if (account.id == null || _uid == null) return;
    final doc = await _db.collection('budget_accounts').doc(account.id).get();
    if (!doc.exists || doc.data()?['userId'] != _uid) return;
    await _db.collection('budget_accounts').doc(account.id).update({
      'name': account.name,
      'type': account.type.name,
      'currency': account.currency,
      'color': account.color,
      'icon': account.icon,
    });
  }

  Future<void> deleteAccount(String accountId) async {
    if (_uid == null) return;
    final doc = await _db.collection('budget_accounts').doc(accountId).get();
    if (!doc.exists || doc.data()?['userId'] != _uid) return;
    await _db.collection('budget_accounts').doc(accountId).delete();
  }

  // ── Assets ───────────────────────────────────────────────────────────────────

  Stream<List<Asset>> getAssetsStream() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection('budget_assets')
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((s) => s.docs.map((d) => Asset.fromFirestore(d)).toList());
  }

  Future<void> addAsset(Asset asset) async {
    if (_uid == null) return;
    await _db.collection('budget_assets').add(asset.toMap());
  }

  Future<void> updateAsset(Asset asset) async {
    if (asset.id == null || _uid == null) return;
    final doc = await _db.collection('budget_assets').doc(asset.id).get();
    if (!doc.exists || doc.data()?['userId'] != _uid) return;
    await _db.collection('budget_assets').doc(asset.id).update({
      'name': asset.name,
      'symbol': asset.symbol,
      'type': asset.type.name,
      'amount': asset.amount,
      'purchasePrice': asset.purchasePrice,
    });
  }

  Future<void> refreshAssetMarketValue(Asset asset) async {
    if (asset.id == null || _uid == null) return;
    await _db.collection('budget_assets').doc(asset.id).update({
      'currentValue': asset.currentValue,
      'lastUpdated': Timestamp.fromDate(asset.lastUpdated),
    });
  }

  Future<void> deleteAsset(String assetId) async {
    await _db.collection('budget_assets').doc(assetId).delete();
  }

  Future<void> refreshAssetValues() async {
    if (_uid == null) return;
    final snapshot = await _db
        .collection('budget_assets')
        .where('userId', isEqualTo: _uid)
        .get();

    for (final doc in snapshot.docs) {
      final asset = Asset.fromFirestore(doc);
      if (asset.symbol.isEmpty) continue;
      final livePrice =
          await _currencyService.getLivePrice(asset.symbol, asset.type.name);
      if (livePrice != null) {
        await refreshAssetMarketValue(asset.copyWith(
          currentValue: asset.amount * livePrice,
          lastUpdated: DateTime.now(),
        ),);
      }
    }
  }
}
