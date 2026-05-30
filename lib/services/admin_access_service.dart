import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Admin & access checks; ban/blacklist via Cloud Function when available.
class AdminAccessService {
  AdminAccessService._();
  static final AdminAccessService instance = AdminAccessService._();

  final _db = FirebaseFirestore.instance;

  /// Custom claim (admin-cli) OR Firestore `users/{uid}.role == 'Admin'`.
  Future<bool> isCurrentUserAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      final token = await user.getIdTokenResult();
      if (token.claims?['admin'] == true) return true;
    } catch (_) {}
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      return doc.data()?['role'] == 'Admin';
    } catch (e) {
      debugPrint('[AdminAccessService.isCurrentUserAdmin] $e');
      return false;
    }
  }

  /// Ban + blacklist via server (IP-aware). Fail-closed on errors.
  Future<bool> checkAccountAccessAllowed() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final result = await FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('checkAccountAccess').call<Map<String, dynamic>>();
      final allowed = result.data['allowed'] == true;
      return allowed;
    } catch (e) {
      debugPrint('[AdminAccessService.checkAccountAccessAllowed] CF: $e');
      return _checkAccountAccessClientFallback();
    }
  }

  /// Firestore-only fallback when Cloud Functions unavailable.
  Future<bool> _checkAccountAccessClientFallback() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final uid = user.uid;

    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.data()?['banned'] == true) return false;

      final email = user.email?.toLowerCase();
      if (email != null && email.isNotEmpty) {
        final emailBan = await _db
            .collection('blacklist')
            .where('type', isEqualTo: 'email')
            .where('value', isEqualTo: email)
            .limit(1)
            .get();
        if (emailBan.docs.isNotEmpty) return false;
      }

      final uidBan = await _db
          .collection('blacklist')
          .where('type', isEqualTo: 'uid')
          .where('value', isEqualTo: uid)
          .limit(1)
          .get();
      if (uidBan.docs.isNotEmpty) return false;

      await _db.collection('users').doc(uid).set(
        {'lastLogin': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      return true;
    } catch (e) {
      debugPrint('[AdminAccessService._checkAccountAccessClientFallback] $e');
      return false;
    }
  }

  Future<void> recordLoginActivity() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.collection('activityLogs').add({
        'userId': uid,
        'action': 'login',
        'timestamp': FieldValue.serverTimestamp(),
        'details': '',
      });
    } catch (e) {
      debugPrint('[AdminAccessService.recordLoginActivity] $e');
    }
  }
}
