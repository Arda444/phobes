import 'package:cloud_firestore/cloud_firestore.dart';

enum SurveyQuestionType { single, multi, text }

class SurveyQuestion {
  final String id;
  final String text;
  final SurveyQuestionType type;
  final List<String> options;

  const SurveyQuestion({
    required this.id,
    required this.text,
    required this.type,
    this.options = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'type': type.name,
        if (options.isNotEmpty) 'options': options,
      };

  factory SurveyQuestion.fromMap(Map<String, dynamic> map) {
    final typeStr = map['type'] as String? ?? 'single';
    return SurveyQuestion(
      id: map['id'] as String? ?? '',
      text: map['text'] as String? ?? '',
      type: SurveyQuestionType.values.firstWhere(
        (t) => t.name == typeStr,
        orElse: () => SurveyQuestionType.single,
      ),
      options: (map['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

class SurveyModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final List<SurveyQuestion> questions;
  final int responseCount;
  final DateTime? createdAt;
  final DateTime? publishedAt;

  const SurveyModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.questions = const [],
    this.responseCount = 0,
    this.createdAt,
    this.publishedAt,
  });

  bool get isActive => status == 'active';

  factory SurveyModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawQuestions = data['questions'] as List<dynamic>? ?? [];
    return SurveyModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      status: data['status'] as String? ?? 'draft',
      questions: rawQuestions
          .whereType<Map>()
          .map((q) => SurveyQuestion.fromMap(Map<String, dynamic>.from(q)))
          .toList(),
      responseCount: (data['responseCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate(),
    );
  }
}
