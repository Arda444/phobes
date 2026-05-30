import 'package:flutter_test/flutter_test.dart';
import 'package:phobes/models/survey_model.dart';

void main() {
  test('SurveyModel isActive and responseCount', () {
    const model = SurveyModel(
      id: 's1',
      title: 'Feedback',
      description: 'Help us improve',
      status: 'active',
      responseCount: 42,
    );
    expect(model.responseCount, 42);
    expect(model.isActive, isTrue);
    expect(model.title, 'Feedback');
  });

  test('SurveyQuestion.fromMap parses options', () {
    final q = SurveyQuestion.fromMap({
      'id': 'q1',
      'text': 'Rate us',
      'type': 'single',
      'options': ['1', '2', '3'],
    });
    expect(q.options, ['1', '2', '3']);
    expect(q.type, SurveyQuestionType.single);
  });
}
