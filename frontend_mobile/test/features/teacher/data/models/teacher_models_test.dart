import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_mobile/features/teacher/data/models/teacher_models.dart';

void main() {
  group('ExamStatusModel', () {
    test('parses grading and student result fields', () {
      final model = ExamStatusModel.fromJson({
        'examId': 10,
        'classId': 5,
        'title': 'Matematik',
        'examStatus': 'READY',
        'gradingSystemSummary': 'Her soru esit puanlidir.',
        'totalMaxPoints': 20,
        'images': const [],
        'students': const [],
        'ocrJobs': const [],
        'questionCount': 2,
        'studentResults': [
          {
            'studentId': 101,
            'studentName': 'Ayse Yilmaz',
            'totalQuestions': 2,
            'scoredQuestions': 2,
            'awardedPoints': 18,
            'maxPoints': 20,
            'gradingConfidence': 0.91,
            'gradingStatus': 'GRADED',
            'gradingSummary': '18 / 20 puan',
            'scorePercentage': 90,
          },
        ],
        'questions': [
          {
            'id': 1,
            'pageNumber': 1,
            'questionOrder': 1,
            'sourceQuestionId': 'Q-1',
            'questionText': '2 + 2 kac eder?',
            'studentAnswer': '4',
            'confidence': 0.95,
            'questionType': 'NUMERIC',
            'expectedAnswer': '4',
            'gradingRubric': '',
            'maxPoints': 10,
            'awardedPoints': 10,
            'gradingConfidence': 0.93,
            'gradingStatus': 'GRADED',
            'evaluationSummary': 'Dogru cevap.',
            'correct': true,
            'studentId': 101,
            'studentName': 'Ayse Yilmaz',
            'matchingStatus': 'MATCHED',
          },
        ],
        'studentClusters': [
          {
            'studentId': 101,
            'studentName': 'Ayse Yilmaz',
            'studentEmail': 'ayse@test.com',
            'unmatched': false,
            'matchingStatus': 'MATCHED',
            'pageCount': 1,
            'questionCount': 1,
            'awardedPoints': 10,
            'maxPoints': 10,
            'scorePercentage': 100,
            'gradingStatus': 'GRADED',
            'gradingSummary': 'Tam puan',
            'images': [
              {
                'imageId': 11,
                'pageOrder': 1,
                'imageUrl': 'https://example.com/page-1.png',
                'status': 'COMPLETED',
              },
            ],
            'questions': [
              {
                'id': 1,
                'pageNumber': 1,
                'questionOrder': 1,
                'questionText': '2 + 2 kac eder?',
                'studentAnswer': '4',
                'confidence': 0.95,
                'questionType': 'NUMERIC',
                'maxPoints': 10,
                'awardedPoints': 10,
                'gradingStatus': 'GRADED',
              },
            ],
          },
          {
            'studentId': null,
            'studentName': 'Atanmamis Kagitlar',
            'unmatched': true,
            'matchingStatus': 'UNMATCHED',
            'pageCount': 1,
            'questionCount': 0,
            'awardedPoints': 0,
            'maxPoints': 0,
            'scorePercentage': 0,
            'images': const [],
            'questions': const [],
          },
        ],
      });

      expect(model.totalMaxPoints, 20);
      expect(model.studentResults, hasLength(1));
      expect(model.studentResults.first.studentName, 'Ayse Yilmaz');
      expect(model.questions.first.expectedAnswer, '4');
      expect(model.questions.first.awardedPoints, 10);
      expect(model.questions.first.correct, isTrue);
      expect(model.studentClusters, hasLength(2));
      expect(model.studentClusters.first.studentEmail, 'ayse@test.com');
      expect(model.studentClusters.first.images, hasLength(1));
      expect(model.studentClusters[1].unmatched, isTrue);
    });
  });
}
