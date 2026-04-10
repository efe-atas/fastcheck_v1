package com.fastcheck.fastcheck.education;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fastcheck.fastcheck.ocr.OcrJobRepository;
import com.fastcheck.fastcheck.user.Role;
import com.fastcheck.fastcheck.user.UserAccount;
import com.fastcheck.fastcheck.user.UserRepository;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.stubbing.Answer;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

@ExtendWith(MockitoExtension.class)
class TeacherEducationServiceTest {

    @Mock
    private EducationAccessService accessService;

    @Mock
    private SchoolClassRepository schoolClassRepository;

    @Mock
    private ExamRepository examRepository;

    @Mock
    private ExamImageRepository examImageRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private ExamFileStorageService fileStorageService;

    @Mock
    private ExamOcrQueueService examOcrQueueService;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private OcrJobRepository ocrJobRepository;

    @Mock
    private QuestionRepository questionRepository;

    @Mock
    private StudentExamResultRepository studentExamResultRepository;

    @Mock
    private ExamGradingService examGradingService;

    @InjectMocks
    private TeacherEducationService teacherEducationService;

    @AfterEach
    void tearDownSynchronization() {
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.clearSynchronization();
        }
    }

    @Test
    void uploadExamImagesEnqueuesOcrAfterTransactionCommit() {
        UserAccount teacher = teacher();
        Exam exam = exam(teacher);
        MockMultipartFile file = new MockMultipartFile("images", "page-3.png", "image/png", new byte[] {1, 2, 3});
        List<ExamImage> persistedImages = new ArrayList<>();

        when(accessService.requireRole(Role.ROLE_TEACHER)).thenReturn(teacher);
        when(examRepository.findById(77L)).thenReturn(Optional.of(exam));
        when(examImageRepository.findTopByExam_IdOrderByPageOrderDesc(77L)).thenReturn(Optional.of(existingImage(exam, 2)));
        when(fileStorageService.save(file)).thenReturn("http://localhost/files/page-3.png");
        when(examRepository.save(any(Exam.class))).thenAnswer((Answer<Exam>) invocation -> invocation.getArgument(0));
        when(examImageRepository.save(any(ExamImage.class))).thenAnswer((Answer<ExamImage>) invocation -> {
            ExamImage image = invocation.getArgument(0);
            if (image.getId() == null) {
                ReflectionTestUtils.setField(image, "id", 303L + persistedImages.size());
            }
            persistedImages.add(image);
            return image;
        });
        when(examImageRepository.findByExam_IdOrderByPageOrderAsc(77L)).thenAnswer(invocation -> List.copyOf(persistedImages));

        TransactionSynchronizationManager.initSynchronization();

        EducationDtos.UploadExamImagesResponse response = teacherEducationService.uploadExamImages(77L, List.of(file));

        assertEquals("PROCESSING", response.status());
        assertEquals(1, response.images().size());
        assertEquals("PENDING", response.images().get(0).status());
        assertEquals(3, response.images().get(0).pageOrder());
        assertEquals(ExamStatus.PROCESSING, exam.getStatus());
        verify(examOcrQueueService, never()).enqueueExam(77L);

        runAfterCommitCallbacks();

        verify(examOcrQueueService).enqueueExam(77L);
    }

    @Test
    void reprocessExamEnqueuesOcrAfterTransactionCommit() {
        UserAccount teacher = teacher();
        SchoolClass schoolClass = schoolClass(teacher);
        Exam exam = exam(teacher);
        exam.setSchoolClass(schoolClass);

        ExamImage image = existingImage(exam, 1);
        image.setStatus(ExamImageStatus.COMPLETED);
        image.setErrorMessage("old error");
        image.setDetectedStudentName("Ali");
        image.setMatchedStudentId(100L);
        image.setMatchedStudentName("Ali Veli");
        image.setStudentMatchConfidence(0.9);
        image.setStudentMatchStatus(StudentMatchStatus.MATCHED);
        image.setCandidateStudentIds("100");

        when(accessService.requireRole(Role.ROLE_TEACHER)).thenReturn(teacher);
        when(examRepository.findByIdAndTeacher_Id(77L, 15L)).thenReturn(Optional.of(exam));
        when(examRepository.save(any(Exam.class))).thenAnswer((Answer<Exam>) invocation -> invocation.getArgument(0));
        when(examImageRepository.findByExam_IdOrderByPageOrderAsc(77L)).thenReturn(List.of(image));
        when(examImageRepository.save(any(ExamImage.class))).thenAnswer((Answer<ExamImage>) invocation -> invocation.getArgument(0));
        when(userRepository.findBySchoolClass_IdAndRoleOrderByFullNameAsc(9L, Role.ROLE_STUDENT)).thenReturn(List.of());
        when(ocrJobRepository.findByExamImage_Exam_IdOrderByCreatedAtAsc(77L)).thenReturn(List.of());
        when(questionRepository.findByExam_IdOrderByPageNumberAscQuestionOrderAsc(77L)).thenReturn(List.of());

        TransactionSynchronizationManager.initSynchronization();

        EducationDtos.TeacherExamStatusResponse response = teacherEducationService.reprocessExam(77L);

        assertNotNull(response);
        assertEquals("PROCESSING", response.examStatus());
        assertEquals(ExamImageStatus.PENDING, image.getStatus());
        assertEquals(ExamStatus.PROCESSING, exam.getStatus());
        verify(examOcrQueueService, never()).enqueueExam(77L);

        runAfterCommitCallbacks();

        verify(examOcrQueueService).enqueueExam(77L);
    }

    @Test
    void updateQuestionOverrideMarksQuestionAsOverriddenAndRecomputesResults() {
        UserAccount teacher = teacher();
        Exam exam = exam(teacher);
        Question question = new Question();
        ReflectionTestUtils.setField(question, "id", 501L);
        question.setExam(exam);
        question.setMaxPoints(10.0);
        question.setAwardedPoints(6.0);
        question.setGradingStatus(GradingStatus.GRADED);

        when(accessService.requireRole(Role.ROLE_TEACHER)).thenReturn(teacher);
        when(examRepository.findByIdAndTeacher_Id(77L, 15L)).thenReturn(Optional.of(exam));
        when(questionRepository.findByIdAndExam_Id(501L, 77L)).thenReturn(Optional.of(question));
        when(questionRepository.save(any(Question.class))).thenAnswer((Answer<Question>) invocation -> invocation.getArgument(0));
        when(userRepository.findBySchoolClass_IdAndRoleOrderByFullNameAsc(9L, Role.ROLE_STUDENT)).thenReturn(List.of());
        when(ocrJobRepository.findByExamImage_Exam_IdOrderByCreatedAtAsc(77L)).thenReturn(List.of());
        when(questionRepository.findByExam_IdOrderByPageNumberAscQuestionOrderAsc(77L)).thenReturn(List.of(question));
        when(studentExamResultRepository.findByExam_IdOrderByAwardedPointsDescStudentNameAsc(77L)).thenReturn(List.of());

        EducationDtos.TeacherExamStatusResponse response = teacherEducationService.updateQuestionOverride(
                77L,
                501L,
                new EducationDtos.UpdateQuestionOverrideRequest(
                        8.5,
                        10.0,
                        "Dogru cevap",
                        "Temel kavramlar yer almali",
                        "Ogretmen tarafindan guncellendi",
                        null
                )
        );

        assertNotNull(response);
        assertEquals(8.5, question.getAwardedPoints());
        assertEquals(10.0, question.getMaxPoints());
        assertEquals("Dogru cevap", question.getExpectedAnswerRaw());
        assertEquals("Temel kavramlar yer almali", question.getGradingRubricRaw());
        assertEquals("Ogretmen tarafindan guncellendi", question.getEvaluationSummary());
        assertEquals(GradingStatus.OVERRIDDEN, question.getGradingStatus());
        assertEquals(1.0, question.getGradingConfidence());
        verify(examGradingService).recomputeStudentResults(exam);
    }

    @Test
    void getExamStatusBuildsStudentClustersIncludingUnmatchedPages() {
        UserAccount teacher = teacher();
        UserAccount matchedStudent = new UserAccount();
        ReflectionTestUtils.setField(matchedStudent, "id", 101L);
        matchedStudent.setRole(Role.ROLE_STUDENT);
        matchedStudent.setFullName("Ayse Kaya");
        matchedStudent.setEmail("ayse@fastcheck.local");
        matchedStudent.setSchoolClass(schoolClass(teacher));

        Exam exam = exam(teacher);

        ExamImage matchedImage = existingImage(exam, 1);
        matchedImage.setStatus(ExamImageStatus.COMPLETED);
        matchedImage.setMatchedStudentId(101L);
        matchedImage.setMatchedStudentName("Ayse Kaya");
        matchedImage.setStudentMatchStatus(StudentMatchStatus.MATCHED);

        ExamImage unmatchedImage = existingImage(exam, 2);
        unmatchedImage.setStatus(ExamImageStatus.COMPLETED);
        unmatchedImage.setStudentMatchStatus(StudentMatchStatus.UNMATCHED);

        Question matchedQuestion = new Question();
        ReflectionTestUtils.setField(matchedQuestion, "id", 700L);
        matchedQuestion.setExam(exam);
        matchedQuestion.setExamImage(matchedImage);
        matchedQuestion.setPageNumber(1);
        matchedQuestion.setQuestionOrder(1);
        matchedQuestion.setQuestionTextRaw("Soru 1");
        matchedQuestion.setAwardedPoints(8.0);
        matchedQuestion.setMaxPoints(10.0);
        matchedQuestion.setConfidence(0.9);
        matchedQuestion.setQuestionType(QuestionType.OPEN_ENDED);
        matchedQuestion.setGradingStatus(GradingStatus.GRADED);

        Question unmatchedQuestion = new Question();
        ReflectionTestUtils.setField(unmatchedQuestion, "id", 701L);
        unmatchedQuestion.setExam(exam);
        unmatchedQuestion.setExamImage(unmatchedImage);
        unmatchedQuestion.setPageNumber(2);
        unmatchedQuestion.setQuestionOrder(1);
        unmatchedQuestion.setQuestionTextRaw("Soru 2");
        unmatchedQuestion.setAwardedPoints(0.0);
        unmatchedQuestion.setMaxPoints(5.0);
        unmatchedQuestion.setConfidence(0.4);
        unmatchedQuestion.setQuestionType(QuestionType.OPEN_ENDED);
        unmatchedQuestion.setGradingStatus(GradingStatus.NEEDS_REVIEW);

        StudentExamResult result = new StudentExamResult();
        result.setExam(exam);
        result.setStudentId(101L);
        result.setStudentName("Ayse Kaya");
        result.setTotalQuestions(1);
        result.setScoredQuestions(1);
        result.setAwardedPoints(8.0);
        result.setMaxPoints(10.0);
        result.setGradingStatus(GradingStatus.GRADED);
        result.setGradingSummary("8 / 10 puan");

        when(accessService.requireRole(Role.ROLE_TEACHER)).thenReturn(teacher);
        when(examRepository.findByIdAndTeacher_Id(77L, 15L)).thenReturn(Optional.of(exam));
        when(userRepository.findBySchoolClass_IdAndRoleOrderByFullNameAsc(9L, Role.ROLE_STUDENT))
                .thenReturn(List.of(matchedStudent));
        when(examImageRepository.findByExam_IdOrderByPageOrderAsc(77L))
                .thenReturn(List.of(matchedImage, unmatchedImage));
        when(ocrJobRepository.findByExamImage_Exam_IdOrderByCreatedAtAsc(77L)).thenReturn(List.of());
        when(questionRepository.findByExam_IdOrderByPageNumberAscQuestionOrderAsc(77L))
                .thenReturn(List.of(matchedQuestion, unmatchedQuestion));
        when(studentExamResultRepository.findByExam_IdOrderByAwardedPointsDescStudentNameAsc(77L))
                .thenReturn(List.of(result));

        EducationDtos.TeacherExamStatusResponse response = teacherEducationService.getExamStatus(77L);

        assertEquals(2, response.studentClusters().size());
        assertTrue(response.studentClusters().get(0).unmatched());
        assertEquals("Atanmamis Kagitlar", response.studentClusters().get(0).studentName());
        assertEquals(1, response.studentClusters().get(0).pageCount());
        assertEquals(101L, response.studentClusters().get(1).studentId());
        assertEquals("Ayse Kaya", response.studentClusters().get(1).studentName());
        assertEquals(1, response.studentClusters().get(1).questionCount());
        assertEquals(80.0, response.studentClusters().get(1).scorePercentage());
    }

    private void runAfterCommitCallbacks() {
        List<TransactionSynchronization> synchronizations = List.copyOf(
                TransactionSynchronizationManager.getSynchronizations()
        );
        synchronizations.forEach(TransactionSynchronization::afterCommit);
        TransactionSynchronizationManager.clearSynchronization();
    }

    private UserAccount teacher() {
        UserAccount teacher = new UserAccount();
        ReflectionTestUtils.setField(teacher, "id", 15L);
        teacher.setRole(Role.ROLE_TEACHER);
        teacher.setFullName("Teacher User");
        teacher.setEmail("teacher@fastcheck.local");
        return teacher;
    }

    private SchoolClass schoolClass(UserAccount teacher) {
        SchoolClass schoolClass = new SchoolClass();
        ReflectionTestUtils.setField(schoolClass, "id", 9L);
        schoolClass.setTeacher(teacher);
        schoolClass.setName("7-A");
        return schoolClass;
    }

    private Exam exam(UserAccount teacher) {
        Exam exam = new Exam();
        ReflectionTestUtils.setField(exam, "id", 77L);
        exam.setTeacher(teacher);
        exam.setSchoolClass(schoolClass(teacher));
        exam.setTitle("OCR Exam");
        exam.setStatus(ExamStatus.READY);
        return exam;
    }

    private ExamImage existingImage(Exam exam, int pageOrder) {
        ExamImage image = new ExamImage();
        ReflectionTestUtils.setField(image, "id", 200L + pageOrder);
        image.setExam(exam);
        image.setPageOrder(pageOrder);
        image.setImageUrl("http://localhost/files/page-" + pageOrder + ".png");
        return image;
    }
}
