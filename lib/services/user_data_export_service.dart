import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:share_plus/share_plus.dart';

/// Exports the signed-in user's Firestore data as JSON (backup / portability).
class UserDataExportService {
  UserDataExportService._();
  static final UserDataExportService instance = UserDataExportService._();

  final _db = FirebaseFirestore.instance;

  Future<void> exportAndShare() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in');

    final payload = <String, dynamic>{
      'exportedAt': DateTime.now().toIso8601String(),
      'userId': uid,
      'collections': <String, dynamic>{},
    };

    final queries = <String, Query<Map<String, dynamic>>>{
      'tasks': _db.collection('tasks').where('userId', isEqualTo: uid),
      'notes': _db.collection('notes').where('userId', isEqualTo: uid),
      'notebooks': _db.collection('notebooks').where('userId', isEqualTo: uid),
      'habits': _db.collection('habits').where('userId', isEqualTo: uid),
      'appointments':
          _db.collection('appointments').where('userId', isEqualTo: uid),
      'budget_transactions':
          _db.collection('budget_transactions').where('userId', isEqualTo: uid),
      'budget_accounts':
          _db.collection('budget_accounts').where('userId', isEqualTo: uid),
    };

    for (final entry in queries.entries) {
      try {
        final snap = await entry.value.get();
        (payload['collections'] as Map<String, dynamic>)[entry.key] =
            snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      } catch (e) {
        debugPrint('[UserDataExportService] ${entry.key}: $e');
      }
    }

    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        payload['profile'] = {'id': userDoc.id, ...?userDoc.data()};
      }
    } catch (e) {
      debugPrint('[UserDataExportService] profile: $e');
    }

    final json = const JsonEncoder.withIndent('  ').convert(payload);
    await Share.share(
      json,
      subject: 'Phobes backup ${DateTime.now().toIso8601String().substring(0, 10)}',
    );
  }
}
