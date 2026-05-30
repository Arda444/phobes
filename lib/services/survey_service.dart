import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/survey_model.dart';

class SurveyService {
  final _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<SurveyModel?> fetchSurvey(String surveyId) async {
    final doc = await _db.collection('surveys').doc(surveyId).get();
    if (!doc.exists) return null;
    return SurveyModel.fromFirestore(doc);
  }

  Future<bool> hasResponded(String surveyId) async {
    final uid = _uid;
    if (uid == null) return false;
    final doc = await _db
        .collection('surveyResponses')
        .doc(surveyId)
        .collection('responses')
        .doc(uid)
        .get();
    return doc.exists;
  }

  Future<void> submitResponse(
    String surveyId,
    Map<String, dynamic> answers,
  ) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not signed in');

    final ref = _db
        .collection('surveyResponses')
        .doc(surveyId)
        .collection('responses')
        .doc(uid);

    final existing = await ref.get();
    if (existing.exists) {
      throw StateError('Already responded');
    }

    await ref.set({
      'userId': uid,
      'answers': answers,
      'submittedAt': FieldValue.serverTimestamp(),
    });
    // responseCount is incremented server-side (onSurveyResponseCreated).
  }
}
