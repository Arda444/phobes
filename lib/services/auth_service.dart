import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_access_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'base_firebase_service.dart';

class AuthService extends BaseFirebaseService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final GoogleSignIn? _googleSignIn = kIsWeb ? null : GoogleSignIn();

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String surname,
    required DateTime birthDate,
  }) async {
    final cred = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (cred.user != null) {
      await _saveUserToFirestore(cred.user!, name, surname, birthDate);
      await cred.user!.updateDisplayName('$name $surname');
    }
    return cred;
  }

  Future<UserCredential> signIn(String email, String password) async {
    return auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential?> signInWithGoogle() async {
    UserCredential cred;
    if (kIsWeb) {
      cred = await auth.signInWithPopup(GoogleAuthProvider());
    } else {
      final googleUser = await _googleSignIn!.signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      cred = await auth.signInWithCredential(GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      ),);
    }
    if (cred.user != null) {
      final userDoc = await db.collection('users').doc(cred.user!.uid).get();
      if (!userDoc.exists) {
        final names = (cred.user!.displayName ?? 'Misafir').split(' ');
        await _saveUserToFirestore(cred.user!, names.first,
            names.length > 1 ? names.sublist(1).join(' ') : '', DateTime.now(),);
      }
    }
    return cred;
  }

  Future<UserCredential?> signInWithApple() async {
    try {
      final cred = await auth.signInWithProvider(AppleAuthProvider());
      if (cred.user != null) {
        final userDoc = await db.collection('users').doc(cred.user!.uid).get();
        if (!userDoc.exists) {
          String name = 'Apple', surname = 'User';
          if (cred.user!.displayName?.isNotEmpty == true) {
            final names = cred.user!.displayName!.split(' ');
            name = names.first;
            surname = names.length > 1 ? names.sublist(1).join(' ') : '';
          }
          await _saveUserToFirestore(cred.user!, name, surname, DateTime.now());
        }
      }
      return cred;
    } catch (e) {
      debugPrint('Apple Sign In Error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn?.signOut();
    await auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await auth.sendPasswordResetEmail(email: email);
  }

  /// E-posta+şifre ile tekrar kimlik doğrulama — hassas işlemler öncesi zorunlu.
  /// Firebase, son girişten >5 dk geçmişse delete/updateEmail için bu işlemi ister.
  Future<void> reAuthenticate(String password) async {
    final user = auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('Oturum bulunamadı');
    }
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  /// Google hesabı için tekrar kimlik doğrulama.
  Future<void> reAuthenticateWithGoogle() async {
    final user = auth.currentUser;
    if (user == null) throw Exception('Oturum bulunamadı');
    if (kIsWeb) {
      await user.reauthenticateWithProvider(GoogleAuthProvider());
    } else {
      final googleUser = await _googleSignIn?.signIn();
      if (googleUser == null) throw Exception('Google girişi iptal edildi');
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await user.reauthenticateWithCredential(credential);
    }
  }

  /// Kullanıcı verilerini siler; hesap ve profil dokümanı kalır.
  Future<void> clearAllUserData() async {
    final uid = currentUserId;
    if (uid == null) return;
    await _deleteAllUserData(uid, deleteUserDoc: false);
  }

  /// Hesabı tamamen siler: önce tüm Firestore verileri, sonra Auth kaydı.
  Future<void> deleteAccount() async {
    final user = auth.currentUser;
    if (user == null) return;
    await _deleteAllUserData(user.uid, deleteUserDoc: true);
    try {
      await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('deleteUserAccount')
          .call();
    } catch (e) {
      debugPrint('[AuthService.deleteAccount] CF fallback to client: $e');
      await user.delete();
    }
  }

  Future<void> _deleteAllUserData(String uid, {required bool deleteUserDoc}) async {
    final collections = [
      db.collection('tasks').where('userId', isEqualTo: uid),
      db.collection('notes').where('userId', isEqualTo: uid),
      db.collection('notebooks').where('userId', isEqualTo: uid),
      db.collection('habits').where('userId', isEqualTo: uid),
      db.collection('appointments').where('userId', isEqualTo: uid),
      db.collection('appointment_groups').where('ownerId', isEqualTo: uid),
      db.collection('budget_transactions').where('userId', isEqualTo: uid),
      db.collection('budget_accounts').where('userId', isEqualTo: uid),
      db.collection('budget_debts').where('userId', isEqualTo: uid),
      db.collection('budget_limits').where('userId', isEqualTo: uid),
      db.collection('savings_goals').where('userId', isEqualTo: uid),
      db.collection('budget_assets').where('userId', isEqualTo: uid),
      db.collection('corkboard_items').where('userId', isEqualTo: uid),
      db.collection('corkboard_connections').where('userId', isEqualTo: uid),
      db.collection('corkboard_boards').where('userId', isEqualTo: uid),
      db.collection('clients').where('userId', isEqualTo: uid),
      db.collection('feedback').where('userId', isEqualTo: uid),
      db.collection('activity_logs').where('userId', isEqualTo: uid),
    ];

    final userSubcollections = [
      db.collection('users').doc(uid).collection('medications'),
      db.collection('users').doc(uid).collection('notifications'),
      db.collection('users').doc(uid).collection('user_books'),
      db.collection('users').doc(uid).collection('book_quotes'),
      db.collection('users').doc(uid).collection('reading_goals'),
      db.collection('users').doc(uid).collection('shelf_decorations'),
      db.collection('users').doc(uid).collection('shelf_config'),
      db.collection('users').doc(uid).collection('book_prefs'),
    ];

    try {
      final teamsSnap = await db
          .collection('teams')
          .where('memberIds', arrayContains: uid)
          .get();
      for (final t in teamsSnap.docs) {
        final isOwner = t.data()['ownerId'] == uid;
        if (isOwner) {
          for (final col in ['projects', 'resources', 'book_clubs']) {
            final sub = await t.reference.collection(col).get();
            for (final d in sub.docs) {
              await d.reference.delete();
            }
          }
          try {
            final teamActivity = await db
                .collection('activity_logs')
                .where('teamId', isEqualTo: t.id)
                .get();
            for (final d in teamActivity.docs) {
              await d.reference.delete();
            }
          } catch (e) {
            debugPrint('[AuthService._deleteAllUserData] activity_logs: $e');
          }
          await t.reference.delete();
        } else {
          // Sadece üyelikten çık
          await t.reference.update({
            'memberIds': FieldValue.arrayRemove([uid]),
            'adminIds': FieldValue.arrayRemove([uid]),
          });
        }
      }
    } catch (e) {
      debugPrint('[AuthService._deleteAllUserData] teams error: $e');
    }

    final allRefs = <DocumentReference>[];
    for (final q in collections) {
      try {
        final snap = await q.get();
        allRefs.addAll(snap.docs.map((d) => d.reference));
      } catch (e) {
        debugPrint('[AuthService._deleteAllUserData] fetch error: $e');
      }
    }
    for (final sub in userSubcollections) {
      try {
        final snap = await sub.get();
        allRefs.addAll(snap.docs.map((d) => d.reference));
      } catch (e) {
        debugPrint('[AuthService._deleteAllUserData] subcoll error: $e');
      }
    }

    try {
      await db.doc('users/$uid/book_prefs/order').delete();
    } catch (_) {}

    for (var i = 0; i < allRefs.length; i += 400) {
      final batch = db.batch();
      final end = (i + 400 < allRefs.length) ? i + 400 : allRefs.length;
      for (var j = i; j < end; j++) {
        batch.delete(allRefs[j]);
      }
      await batch.commit();
    }

    if (deleteUserDoc) {
      try {
        await db.collection('users').doc(uid).delete();
      } catch (e) {
        debugPrint('[AuthService._deleteAllUserData] user doc error: $e');
      }
    }
  }

  /// Login telemetry + ban/blacklist check (Spark: Firestore only, no Cloud Functions).
  Future<bool> recordSessionStart() async {
    final access = AdminAccessService.instance;
    await access.recordLoginActivity();
    return access.checkAccountAccessAllowed();
  }

  Future<bool> checkAccountAccessAllowed() =>
      AdminAccessService.instance.checkAccountAccessAllowed();

  Future<void> _saveUserToFirestore(
      User user, String name, String surname, DateTime birthDate,) async {
    await db.collection('users').doc(user.uid).set({
      'email': user.email,
      'name': name,
      'surname': surname,
      'birthDate': Timestamp.fromDate(birthDate),
      'createdAt': FieldValue.serverTimestamp(),
      'joinedTeams': [],
      'xp': 0,
      'level': 1,
      'photoUrl': null,
    }, SetOptions(merge: true),);
  }

  Stream<DocumentSnapshot> getUserDataStream() {
    if (currentUserId == null) return const Stream.empty();
    return db.collection('users').doc(currentUserId).snapshots();
  }

  Future<DocumentSnapshot> getUserDoc(String uid) =>
      db.collection('users').doc(uid).get();

  Future<void> updateUserName(String name, String surname) async {
    if (currentUserId == null) return;
    await db
        .collection('users')
        .doc(currentUserId)
        .update({'name': name, 'surname': surname});
    await currentUser?.updateDisplayName('$name $surname');
  }

  Future<void> updateAvatar(String avatarSeed) async {
    if (currentUserId == null) return;
    final url = 'https://api.dicebear.com/9.x/micah/png?seed=$avatarSeed';
    await db.collection('users').doc(currentUserId).update({'photoUrl': url});
    try {
      await currentUser?.updatePhotoURL(url);
    } catch (e) {
      debugPrint('Auth foto güncelleme uyarısı: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUsersByIds(
    List<String> userIds, {
    String? teamId,
  }) async {
    if (userIds.isEmpty) return [];

    if (teamId != null && teamId.isNotEmpty) {
      try {
        final result = await FirebaseFunctions.instanceFor(
          region: 'europe-west1',
        ).httpsCallable('fetchTeamMemberProfiles').call<Map<String, dynamic>>({
          'teamId': teamId,
          'userIds': userIds,
        });
        final raw = result.data['profiles'];
        if (raw is List) {
          return raw
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
        }
      } catch (e) {
        debugPrint('[AuthService.getUsersByIds] team profiles: $e');
      }
    }

    if (currentUserId == null) return [];
    final users = <Map<String, dynamic>>[];
    for (var i = 0; i < userIds.length; i += 10) {
      final sub = userIds.sublist(
        i,
        i + 10 < userIds.length ? i + 10 : userIds.length,
      );
      if (!sub.contains(currentUserId)) continue;
      final doc = await db.collection('users').doc(currentUserId).get();
      if (doc.exists) {
        users.add({...doc.data()!, 'id': doc.id});
      }
    }
    return users;
  }
}
