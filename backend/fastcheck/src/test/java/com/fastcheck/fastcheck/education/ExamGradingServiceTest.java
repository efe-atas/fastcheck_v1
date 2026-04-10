package com.fastcheck.fastcheck.education;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class ExamGradingServiceTest {

    @Mock
    private ExamRepository examRepository;

    @Mock
    private QuestionRepository questionRepository;

    @Mock
    private StudentExamResultRepository studentExamResultRepository;

    @InjectMocks
    private ExamGradingService examGradingService;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void createQuestionFromOcrAppliesDeterministicScoringForMultipleChoice() {
        Exam exam = new Exam();
        ExamImage image = new ExamImage();
        image.setPageOrder(1);

        ObjectNode questionNode = objectMapper.createObjectNode();
        questionNode.put("question_id", "Q-1");
        questionNode.put("question_text_raw", "Dogru secenegi isaretleyiniz.");
        questionNode.put("student_answer_raw", "B");
        questionNode.put("confidence", 0.97);
        questionNode.put("question_type", "multiple_choice");
        questionNode.put("expected_answer_raw", "B");
        questionNode.put("grading_rubric_raw", "");
        questionNode.put("max_points", 5);
        questionNode.putNull("awarded_points");
        questionNode.put("grading_confidence", 0.82);
        questionNode.put("evaluation_summary", "");
        questionNode.put("needs_review", false);
        questionNode.putNull("is_correct");

        Question question = examGradingService.createQuestionFromOcr(exam, image, questionNode, 1);

        assertEquals(QuestionType.MULTIPLE_CHOICE, question.getQuestionType());
        assertEquals(5.0, question.getAwardedPoints());
        assertEquals(5.0, question.getMaxPoints());
        assertTrue(Boolean.TRUE.equals(question.getCorrect()));
        assertEquals(GradingStatus.GRADED, question.getGradingStatus());
    }

    @Test
    void recomputeStudentResultsAggregatesQuestionScoresPerMatchedStudent() {
        Exam exam = new Exam();
        ReflectionTestUtils.setField(exam, "id", 22L);

        ExamImage frontPage = new ExamImage();
        frontPage.setPageOrder(1);
        frontPage.setMatchedStudentId(9L);
        frontPage.setMatchedStudentName("Ali Veli");

        ExamImage backPage = new ExamImage();
        backPage.setPageOrder(2);
        backPage.setMatchedStudentId(9L);
        backPage.setMatchedStudentName("Ali Veli");

        Question firstQuestion = new Question();
        firstQuestion.setExam(exam);
        firstQuestion.setExamImage(frontPage);
        firstQuestion.setPageNumber(1);
        firstQuestion.setMaxPoints(10.0);
        firstQuestion.setAwardedPoints(7.5);
        firstQuestion.setGradingConfidence(0.9);
        firstQuestion.setGradingStatus(GradingStatus.PARTIALLY_GRADED);
        firstQuestion.setConfidence(0.95);

        Question secondQuestion = new Question();
        secondQuestion.setExam(exam);
        secondQuestion.setExamImage(backPage);
        secondQuestion.setPageNumber(2);
        secondQuestion.setMaxPoints(5.0);
        secondQuestion.setAwardedPoints(5.0);
        secondQuestion.setGradingConfidence(0.8);
        secondQuestion.setGradingStatus(GradingStatus.GRADED);
        secondQuestion.setConfidence(0.88);

        when(questionRepository.findByExam_IdOrderByPageNumberAscQuestionOrderAsc(22L))
                .thenReturn(List.of(firstQuestion, secondQuestion));
        when(examRepository.save(any(Exam.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(studentExamResultRepository.saveAll(any())).thenAnswer(invocation -> invocation.getArgument(0));

        examGradingService.recomputeStudentResults(exam);

        ArgumentCaptor<List<StudentExamResult>> resultsCaptor = ArgumentCaptor.forClass(List.class);
        verify(studentExamResultRepository).saveAll(resultsCaptor.capture());
        StudentExamResult result = resultsCaptor.getValue().getFirst();

        assertEquals(9L, result.getStudentId());
        assertEquals("Ali Veli", result.getStudentName());
        assertEquals(2, result.getTotalQuestions());
        assertEquals(2, result.getScoredQuestions());
        assertEquals(12.5, result.getAwardedPoints());
        assertEquals(15.0, result.getMaxPoints());
        assertEquals(GradingStatus.PARTIALLY_GRADED, result.getGradingStatus());
        assertFalse(result.getGradingSummary().isBlank());
    }

    @Test
    void recomputeStudentResultsUpdatesExistingStudentResultInsteadOfDuplicating() {
        Exam exam = new Exam();
        ReflectionTestUtils.setField(exam, "id", 22L);

        ExamImage page = new ExamImage();
        page.setPageOrder(1);
        page.setMatchedStudentId(9L);
        page.setMatchedStudentName("Ali Veli");

        Question question = new Question();
        question.setExam(exam);
        question.setExamImage(page);
        question.setPageNumber(1);
        question.setMaxPoints(10.0);
        question.setAwardedPoints(9.0);
        question.setGradingConfidence(0.92);
        question.setGradingStatus(GradingStatus.GRADED);
        question.setConfidence(0.95);

        StudentExamResult existing = new StudentExamResult();
        ReflectionTestUtils.setField(existing, "id", 44L);
        existing.setExam(exam);
        existing.setStudentId(9L);
        existing.setStudentName("Ali Veli");
        existing.setTotalQuestions(1);
        existing.setScoredQuestions(1);
        existing.setMaxPoints(5.0);
        existing.setAwardedPoints(4.0);
        existing.setGradingStatus(GradingStatus.PARTIALLY_GRADED);
        existing.setGradingSummary("old");

        when(questionRepository.findByExam_IdOrderByPageNumberAscQuestionOrderAsc(22L))
                .thenReturn(List.of(question));
        when(studentExamResultRepository.findByExam_IdOrderByAwardedPointsDescStudentNameAsc(22L))
                .thenReturn(List.of(existing));
        when(examRepository.save(any(Exam.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(studentExamResultRepository.saveAll(any())).thenAnswer(invocation -> invocation.getArgument(0));

        examGradingService.recomputeStudentResults(exam);

        ArgumentCaptor<List<StudentExamResult>> resultsCaptor = ArgumentCaptor.forClass(List.class);
        verify(studentExamResultRepository).saveAll(resultsCaptor.capture());
        verify(studentExamResultRepository, never()).deleteByExam_Id(any());
        StudentExamResult saved = resultsCaptor.getValue().getFirst();

        assertEquals(44L, saved.getId());
        assertEquals(9L, saved.getStudentId());
        assertEquals(9.0, saved.getAwardedPoints());
        assertEquals(10.0, saved.getMaxPoints());
        assertEquals(GradingStatus.PARTIALLY_GRADED, saved.getGradingStatus());
    }
}
