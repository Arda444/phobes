import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/corkboard_board_model.dart';
import '../models/corkboard_item_model.dart';
import '../models/corkboard_connection_model.dart';
import 'base_firebase_service.dart';

class CorkboardService extends BaseFirebaseService {
  static final CorkboardService _instance = CorkboardService._internal();
  factory CorkboardService() => _instance;
  CorkboardService._internal();

  Future<bool> _canModifyScopedData(Map<String, dynamic>? data) async {
    if (data == null || currentUserId == null) return false;
    if (data['userId'] == currentUserId) return true;
    final teamId = data['teamId'] as String?;
    if (teamId == null) return false;
    try {
      final team = await db.collection('teams').doc(teamId).get();
      if (!team.exists) return false;
      final members =
          List<String>.from(team.data()?['memberIds'] ?? <dynamic>[]);
      return members.contains(currentUserId);
    } catch (_) {
      return false;
    }
  }

  T? _safeMap<T>(T Function() parse) {
    try {
      return parse();
    } catch (_) {
      return null;
    }
  }

  Query<Map<String, dynamic>> _scopedQuery(
    String collection, {
    String? teamId,
  }) {
    Query<Map<String, dynamic>> query = db.collection(collection);
    if (teamId != null) {
      query = query.where('teamId', isEqualTo: teamId);
    } else {
      query = query.where('userId', isEqualTo: currentUserId);
    }
    return query;
  }

  // ── Boards (pages) ─────────────────────────────────────────────────────────

  Stream<List<CorkboardBoard>> getBoardsStream({String? teamId}) {
    if (currentUserId == null) return Stream.value([]);
    return _scopedQuery('corkboard_boards', teamId: teamId)
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => _safeMap(() => CorkboardBoard.fromFirestore(d)))
            .whereType<CorkboardBoard>()
            .toList());
  }

  Future<String> createBoard({
    required String title,
    String? teamId,
    int sortOrder = 0,
  }) async {
    if (currentUserId == null) throw StateError('Not signed in');
    final ref = await db.collection('corkboard_boards').add({
      'userId': currentUserId,
      'teamId': teamId,
      'title': title,
      'sortOrder': sortOrder,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> renameBoard(String boardId, String title) async {
    if (currentUserId == null) return;
    final doc = await db.collection('corkboard_boards').doc(boardId).get();
    if (!doc.exists || !await _canModifyScopedData(doc.data())) return;
    await doc.reference.update({'title': title});
  }

  Future<void> deleteBoard(String boardId, {String? teamId}) async {
    if (currentUserId == null) {
      throw StateError('Not signed in');
    }

    Query<Map<String, dynamic>> itemsQuery = db
        .collection('corkboard_items')
        .where('boardId', isEqualTo: boardId);
    Query<Map<String, dynamic>> connsQuery = db
        .collection('corkboard_connections')
        .where('boardId', isEqualTo: boardId);

    if (teamId != null) {
      itemsQuery = itemsQuery.where('teamId', isEqualTo: teamId);
      connsQuery = connsQuery.where('teamId', isEqualTo: teamId);
    } else {
      itemsQuery = itemsQuery.where('userId', isEqualTo: currentUserId);
      connsQuery = connsQuery.where('userId', isEqualTo: currentUserId);
    }

    final items = await itemsQuery.get();
    final conns = await connsQuery.get();
    final refs = [
      ...items.docs.map((d) => d.reference),
      ...conns.docs.map((d) => d.reference),
      db.collection('corkboard_boards').doc(boardId),
    ];

    const chunkSize = 450;
    for (var i = 0; i < refs.length; i += chunkSize) {
      final batch = db.batch();
      final end = math.min(i + chunkSize, refs.length);
      for (var j = i; j < end; j++) {
        batch.delete(refs[j]);
      }
      await batch.commit();
    }
  }

  /// Assigns legacy items/connections (no [boardId]) to [boardId].
  Future<void> migrateLegacyItems(String boardId, {String? teamId}) async {
    const chunkSize = 400;
    await _migrateLegacyCollection(
      'corkboard_items',
      boardId,
      teamId: teamId,
      chunkSize: chunkSize,
    );
    await _migrateLegacyCollection(
      'corkboard_connections',
      boardId,
      teamId: teamId,
      chunkSize: chunkSize,
    );
  }

  Future<void> _migrateLegacyCollection(
    String collection,
    String boardId, {
    String? teamId,
    required int chunkSize,
  }) async {
    while (true) {
      final legacy = await _scopedQuery(collection, teamId: teamId).get();
      final batch = db.batch();
      var count = 0;

      for (final doc in legacy.docs) {
        final data = doc.data();
        if (data['boardId'] != null) continue;
        batch.update(doc.reference, {'boardId': boardId});
        count++;
        if (count >= chunkSize) break;
      }

      if (count == 0) return;
      await batch.commit();
      if (count < chunkSize) return;
    }
  }

  // ── Items ──────────────────────────────────────────────────────────────────

  Stream<List<CorkboardItem>> getItemsStream({
    String? teamId,
    String? boardId,
  }) {
    if (currentUserId == null) return Stream.value([]);

    var query = _scopedQuery('corkboard_items', teamId: teamId);
    if (boardId != null) {
      query = query.where('boardId', isEqualTo: boardId);
    }
    return query.snapshots()
        .map((snap) =>
            snap.docs.map((doc) => CorkboardItem.fromFirestore(doc)).toList());
  }

  Future<void> addItem(CorkboardItem item) async {
    if (currentUserId == null) return;
    final itemMap = item.toMap();
    itemMap['userId'] = currentUserId;
    await db.collection('corkboard_items').add(itemMap);
  }

  Future<void> updateItem(CorkboardItem item) async {
    if (item.id == null || currentUserId == null) return;

    final doc = await db.collection('corkboard_items').doc(item.id).get();
    if (!doc.exists || !await _canModifyScopedData(doc.data())) return;

    final map = item.toMap();
    map.remove('createdAt');
    await db.collection('corkboard_items').doc(item.id).update(map);
  }

  Future<void> deleteItem(String itemId, {String? teamId}) async {
    if (currentUserId == null) return;

    final doc = await db.collection('corkboard_items').doc(itemId).get();
    final data = doc.data();
    if (!doc.exists || !await _canModifyScopedData(data)) return;

    await _deleteConnectionsForItem(itemId, teamId: teamId ?? data?['teamId']);
    await db.collection('corkboard_items').doc(itemId).delete();
  }

  Future<void> _deleteConnectionsForItem(
    String itemId, {
    String? teamId,
  }) async {
    final fromSnap = await _scopedQuery('corkboard_connections', teamId: teamId)
        .where('fromId', isEqualTo: itemId)
        .get();
    final toSnap = await _scopedQuery('corkboard_connections', teamId: teamId)
        .where('toId', isEqualTo: itemId)
        .get();

    final refs = <DocumentReference<Map<String, dynamic>>>{
      ...fromSnap.docs.map((d) => d.reference),
      ...toSnap.docs.map((d) => d.reference),
    };

    if (refs.isEmpty) return;

    const chunkSize = 450;
    final list = refs.toList();
    for (var i = 0; i < list.length; i += chunkSize) {
      final batch = db.batch();
      final end = math.min(i + chunkSize, list.length);
      for (var j = i; j < end; j++) {
        batch.delete(list[j]);
      }
      await batch.commit();
    }
  }

  Future<void> updatePosition(
    String id,
    double x,
    double y,
    double rotation,
  ) async {
    if (currentUserId == null) return;
    final doc = await db.collection('corkboard_items').doc(id).get();
    if (!doc.exists || !await _canModifyScopedData(doc.data())) return;
    await doc.reference.update({
      'posX': x,
      'posY': y,
      'rotation': rotation,
    });
  }

  Future<void> updateSize(String id, double size) async {
    if (currentUserId == null) return;
    final doc = await db.collection('corkboard_items').doc(id).get();
    if (!doc.exists || !await _canModifyScopedData(doc.data())) return;
    await doc.reference.update({'size': size});
  }

  // ── Connections ────────────────────────────────────────────────────────────

  Stream<List<CorkboardConnection>> getConnectionsStream({
    String? teamId,
    String? boardId,
  }) {
    if (currentUserId == null) return Stream.value([]);

    var query = _scopedQuery('corkboard_connections', teamId: teamId);
    if (boardId != null) {
      query = query.where('boardId', isEqualTo: boardId);
    }
    return query.snapshots()
        .map((snap) => snap.docs
            .map((doc) => CorkboardConnection.fromFirestore(doc))
            .toList());
  }

  Future<bool> addConnection(
    String fromId,
    String toId,
    int color, {
    String? teamId,
    required String boardId,
  }) async {
    if (currentUserId == null) return false;
    if (fromId == toId) return false;

    var boardConnections = db
        .collection('corkboard_connections')
        .where('boardId', isEqualTo: boardId);
    if (teamId != null) {
      boardConnections =
          boardConnections.where('teamId', isEqualTo: teamId);
    } else {
      boardConnections =
          boardConnections.where('userId', isEqualTo: currentUserId);
    }
    final connSnap = await boardConnections.get();

    final duplicate = connSnap.docs.any((d) {
      final data = d.data();
      final a = data['fromId'] as String?;
      final b = data['toId'] as String?;
      if (a == null || b == null) return false;
      return (a == fromId && b == toId) || (a == toId && b == fromId);
    });
    if (duplicate) return false;

    await db.collection('corkboard_connections').add({
      'fromId': fromId,
      'toId': toId,
      'color': color,
      'thickness': 2.5,
      'userId': currentUserId,
      'teamId': teamId,
      'boardId': boardId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  Future<void> deleteConnection(String connectionId) async {
    if (currentUserId == null) return;
    final doc =
        await db.collection('corkboard_connections').doc(connectionId).get();
    if (!doc.exists || !await _canModifyScopedData(doc.data())) return;
    await doc.reference.delete();
  }
}
