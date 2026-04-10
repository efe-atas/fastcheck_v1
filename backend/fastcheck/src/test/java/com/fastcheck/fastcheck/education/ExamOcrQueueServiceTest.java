package com.fastcheck.fastcheck.education;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fastcheck.fastcheck.auth.ServiceTokenProvider;
import com.fastcheck.fastcheck.ocr.OcrClient;
import com.fastcheck.fastcheck.ocr.OcrDtos;
import com.fastcheck.fastcheck.ocr.OcrJobRepository;
import com.fastcheck.fastcheck.user.Role;
import com.fastcheck.fastcheck.user.UserAccount;
import com.fastcheck.fastcheck.user.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.stubbing.Answer;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class ExamOcrQueueServiceTest {

    @Mock
    private ExamRepository examRepository;

    @Mock
    private ExamImageRepository examImageRepository;

    @Mock
    private OcrJobRepository ocrJobRepository;

    @Mock
    private QuestionRepository questionRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private OcrClient ocrClient;

    @Mock
    private StudentNameMatcherService studentNameMatcherService;

    @Mock
    private ExamGradingService examGradingService;

    @Mock
    private ServiceTokenProvider serviceTokenProvider;

    @Mock
    private ExamOcrEventPublisher eventPublisher;

    @Mock
    private ObjectMapper objectMapper;

    @Captor
    private ArgumentCaptor<OcrDtos.FastApiRequest> requestCaptor;

    private final ObjectMapper jsonMapper = new ObjectMapper();

    @InjectMocks
    private ExamOcrQueueService examOcrQueueService;

    @Test
    void processExamOnlySendsPendingPagesToOcr() throws Exception {
        UserAccount teacher = createTeacher(7L);
        SchoolClass schoolClass = createSchoolClass(3L, teacher);
        Exam exam = createExam(11L, teacher, schoolClass, "Incremental OCR");
        ExamImage completedImage = createImage(exam, 101L, 1, ExamImageStatus.COMPLETED);
        ExamImage pendingImage = createImage(exam, 102L, 2, ExamImageStatus.PENDING);

        when(examRepository.findById(11L)).thenReturn(Optional.of(exam));
        when(examImageRepository.findByExam_IdOrderByPageOrderAsc(11L))
                .thenReturn(List.of(completedImage, pendingImage));
        when(examRepository.save(any(Exam.class))).thenAnswer((Answer<Exam>) invocation -> invocation.getArgument(0));
        when(examImageRepository.save(any(ExamImage.class))).thenAnswer((Answer<ExamImage>) invocation -> invocation.getArgument(0));
        when(ocrJobRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(questionRepository.save(any(Question.class))).thenAnswer((Answer<Question>) invocation -> invocation.getArgument(0));
        when(objectMapper.writeValueAsString(any())).thenReturn("{}");
        when(serviceTokenProvider.createServiceToken()).thenReturn("service-token");
        when(userRepository.findBySchoolClass_IdAndRoleOrderByFullNameAsc(3L, Role.ROLE_STUDENT))
                .thenReturn(List.of());
        when(studentNameMatcherService.match(any(), anyList()))
                .thenReturn(new StudentNameMatcherService.StudentNameMatchResult(
                        "Detected Student",
                        null,
                        null,
                        0.0,
                        StudentMatchStatus.UNMATCHED,
                        List.of()
                ));
        when(ocrClient.extract(any(), eq("service-token"), eq(7L), any()))
                .thenReturn(new OcrDtos.FastApiResponse("req-1", mockOcrResult()));
        when(examGradingService.createQuestionFromOcr(any(), any(), any(), any(Integer.class)))
                .thenAnswer(invocation -> {
                    Exam examArg = invocation.getArgument(0);
                    ExamImage imageArg = invocation.getArgument(1);
                    Integer orderArg = invocation.getArgument(3);
                    Question question = new Question();
                    question.setExam(examArg);
                    question.setExamImage(imageArg);
                    question.setPageNumber(imageArg.getPageOrder());
                    question.setQuestionOrder(orderArg);
                    question.setSourceQuestionId("Q-1");
                    question.setQuestionTextRaw("Question text");
                    question.setStudentAnswerRaw("Answer");
                    question.setConfidence(0.91);
                    return question;
                });

        examOcrQueueService.processExam(11L);

        verify(ocrClient).extract(requestCaptor.capture(), eq("service-token"), eq(7L), any());
        assertEquals("http://localhost/files/page-2.jpg", requestCaptor.getValue().imageUrl());

        verify(questionRepository).deleteByExamImage_Id(102L);
        verify(questionRepository, never()).deleteByExamImage_Id(101L);
        verify(questionRepository, never()).deleteByExam_Id(11L);

        assertEquals(ExamImageStatus.COMPLETED, completedImage.getStatus());
        assertEquals(ExamImageStatus.COMPLETED, pendingImage.getStatus());
        assertEquals(ExamStatus.READY, exam.getStatus());

        ArgumentCaptor<Question> questionCaptor = ArgumentCaptor.forClass(Question.class);
        verify(questionRepository).save(questionCaptor.capture());
        assertSame(pendingImage, questionCaptor.getValue().getExamImage());
        assertEquals(2, questionCaptor.getValue().getPageNumber());
        verify(examGradingService).updateExamMetadataFromOcr(eq(exam), any());
        verify(examGradingService).recomputeStudentResults(exam);
    }

    @Test
    void processExamPropagatesMatchedStudentAcrossPagesWithoutDetectedName() throws Exception {
        UserAccount teacher = createTeacher(8L);
        SchoolClass schoolClass = createSchoolClass(4L, teacher);
        Exam exam = createExam(12L, teacher, schoolClass, "Front Back");
        ExamImage frontPage = createImage(exam, 201L, 1, ExamImageStatus.PENDING);
        ExamImage backPage = createImage(exam, 202L, 2, ExamImageStatus.PENDING);

        when(examRepository.findById(12L)).thenReturn(Optional.of(exam));
        when(examImageRepository.findByExam_IdOrderByPageOrderAsc(12L)).thenReturn(List.of(frontPage, backPage));
        mockPersistence();
        when(serviceTokenProvider.createServiceToken()).thenReturn("service-token");
        when(userRepository.findBySchoolClass_IdAndRoleOrderByFullNameAsc(4L, Role.ROLE_STUDENT))
                .thenReturn(List.of(createStudent(91L, "Ali Veli")));
        when(studentNameMatcherService.match(eq("Ali Veli"), anyList()))
                .thenReturn(matchedResult("Ali Veli", 91L, "Ali Veli", 0.98));
        when(studentNameMatcherService.match(eq(""), anyList()))
                .thenReturn(unmatchedResult(""));
        when(ocrClient.extract(any(), eq("service-token"), eq(8L), any()))
                .thenReturn(new OcrDtos.FastApiResponse("req-1", mockOcrResult("Ali Veli")))
                .thenReturn(new OcrDtos.FastApiResponse("req-2", mockOcrResult("")));
        when(examGradingService.createQuestionFromOcr(any(), any(), any(), any(Integer.class)))
                .thenAnswer(invocation -> createQuestion(invocation.getArgument(0), invocation.getArgument(1), invocation.getArgument(3)));

        examOcrQueueService.processExam(12L);

        assertEquals(91L, frontPage.getMatchedStudentId());
        assertEquals("Ali Veli", frontPage.getMatchedStudentName());
        assertEquals(StudentMatchStatus.MATCHED, frontPage.getStudentMatchStatus());

        assertEquals(91L, backPage.getMatchedStudentId());
        assertEquals("Ali Veli", backPage.getMatchedStudentName());
        assertEquals(StudentMatchStatus.MATCHED, backPage.getStudentMatchStatus());
        assertNull(backPage.getDetectedStudentName());
    }

    @Test
    void processExamClearsPropagatedPagesWhenConflictingTrustedMatchesAppear() throws Exception {
        UserAccount teacher = createTeacher(9L);
        SchoolClass schoolClass = createSchoolClass(5L, teacher);
        Exam exam = createExam(13L, teacher, schoolClass, "Conflict");
        ExamImage firstPage = createImage(exam, 301L, 1, ExamImageStatus.PENDING);
        ExamImage secondPage = createImage(exam, 302L, 2, ExamImageStatus.PENDING);
        ExamImage thirdPage = createImage(exam, 303L, 3, ExamImageStatus.PENDING);

        when(examRepository.findById(13L)).thenReturn(Optional.of(exam));
        when(examImageRepository.findByExam_IdOrderByPageOrderAsc(13L))
                .thenReturn(List.of(firstPage, secondPage, thirdPage));
        mockPersistence();
        when(serviceTokenProvider.createServiceToken()).thenReturn("service-token");
        when(userRepository.findBySchoolClass_IdAndRoleOrderByFullNameAsc(5L, Role.ROLE_STUDENT))
                .thenReturn(List.of(
                        createStudent(101L, "Ali Veli"),
                        createStudent(102L, "Ayse Demir")
                ));
        when(studentNameMatcherService.match(eq("Ali Veli"), anyList()))
                .thenReturn(matchedResult("Ali Veli", 101L, "Ali Veli", 0.99));
        when(studentNameMatcherService.match(eq("Ayse Demir"), anyList()))
                .thenReturn(matchedResult("Ayse Demir", 102L, "Ayse Demir", 0.97));
        when(studentNameMatcherService.match(eq(""), anyList()))
                .thenReturn(unmatchedResult(""));
        when(ocrClient.extract(any(), eq("service-token"), eq(9L), any()))
                .thenReturn(new OcrDtos.FastApiResponse("req-1", mockOcrResult("Ali Veli")))
                .thenReturn(new OcrDtos.FastApiResponse("req-2", mockOcrResult("")))
                .thenReturn(new OcrDtos.FastApiResponse("req-3", mockOcrResult("Ayse Demir")));
        when(examGradingService.createQuestionFromOcr(any(), any(), any(), any(Integer.class)))
                .thenAnswer(invocation -> createQuestion(invocation.getArgument(0), invocation.getArgument(1), invocation.getArgument(3)));

        examOcrQueueService.processExam(13L);

        assertEquals(101L, firstPage.getMatchedStudentId());
        assertEquals(102L, thirdPage.getMatchedStudentId());
        assertNull(secondPage.getMatchedStudentId());
        assertNull(secondPage.getMatchedStudentName());
        assertEquals(StudentMatchStatus.UNMATCHED, secondPage.getStudentMatchStatus());
    }

    @Test
    void processExamKeepsManualStudentMatchAndPropagatesIt() throws Exception {
        UserAccount teacher = createTeacher(10L);
        SchoolClass schoolClass = createSchoolClass(6L, teacher);
        Exam exam = createExam(14L, teacher, schoolClass, "Manual Match");
        ExamImage manualPage = createImage(exam, 401L, 1, ExamImageStatus.PENDING);
        manualPage.setMatchedStudentId(201L);
        manualPage.setMatchedStudentName("Ali Veli");
        manualPage.setStudentMatchConfidence(1.0);
        manualPage.setStudentMatchStatus(StudentMatchStatus.MANUAL);

        ExamImage backPage = createImage(exam, 402L, 2, ExamImageStatus.PENDING);

        when(examRepository.findById(14L)).thenReturn(Optional.of(exam));
        when(examImageRepository.findByExam_IdOrderByPageOrderAsc(14L))
                .thenReturn(List.of(manualPage, backPage));
        mockPersistence();
        when(serviceTokenProvider.createServiceToken()).thenReturn("service-token");
        when(userRepository.findBySchoolClass_IdAndRoleOrderByFullNameAsc(6L, Role.ROLE_STUDENT))
                .thenReturn(List.of(
                        createStudent(201L, "Ali Veli"),
                        createStudent(202L, "Ayse Demir")
                ));
        when(studentNameMatcherService.match(eq("Ayse Demir"), anyList()))
                .thenReturn(matchedResult("Ayse Demir", 202L, "Ayse Demir", 0.95));
        when(studentNameMatcherService.match(eq(""), anyList()))
                .thenReturn(unmatchedResult(""));
        when(ocrClient.extract(any(), eq("service-token"), eq(10L), any()))
                .thenReturn(new OcrDtos.FastApiResponse("req-1", mockOcrResult("Ayse Demir")))
                .thenReturn(new OcrDtos.FastApiResponse("req-2", mockOcrResult("")));
        when(examGradingService.createQuestionFromOcr(any(), any(), any(), any(Integer.class)))
                .thenAnswer(invocation -> createQuestion(invocation.getArgument(0), invocation.getArgument(1), invocation.getArgument(3)));

        examOcrQueueService.processExam(14L);

        assertEquals(201L, manualPage.getMatchedStudentId());
        assertEquals("Ali Veli", manualPage.getMatchedStudentName());
        assertEquals(StudentMatchStatus.MANUAL, manualPage.getStudentMatchStatus());

        assertEquals(201L, backPage.getMatchedStudentId());
        assertEquals("Ali Veli", backPage.getMatchedStudentName());
        assertEquals(StudentMatchStatus.MATCHED, backPage.getStudentMatchStatus());
    }

    private void mockPersistence() throws Exception {
        when(examRepository.save(any(Exam.class))).thenAnswer((Answer<Exam>) invocation -> invocation.getArgument(0));
        when(examImageRepository.save(any(ExamImage.class))).thenAnswer((Answer<ExamImage>) invocation -> invocation.getArgument(0));
        when(ocrJobRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(questionRepository.save(any(Question.class))).thenAnswer((Answer<Question>) invocation -> invocation.getArgument(0));
        when(objectMapper.writeValueAsString(any())).thenReturn("{}");
    }

    private UserAccount createTeacher(Long teacherId) {
        UserAccount teacher = new UserAccount();
        ReflectionTestUtils.setField(teacher, "id", teacherId);
        teacher.setRole(Role.ROLE_TEACHER);
        teacher.setFullName("Teacher");
        teacher.setEmail("teacher@fastcheck.local");
        return teacher;
    }

    private UserAccount createStudent(Long studentId, String fullName) {
        UserAccount student = new UserAccount();
        ReflectionTestUtils.setField(student, "id", studentId);
        student.setRole(Role.ROLE_STUDENT);
        student.setFullName(fullName);
        student.setEmail("student-" + studentId + "@fastcheck.local");
        return student;
    }

    private SchoolClass createSchoolClass(Long classId, UserAccount teacher) {
        SchoolClass schoolClass = new SchoolClass();
        ReflectionTestUtils.setField(schoolClass, "id", classId);
        schoolClass.setTeacher(teacher);
        schoolClass.setName("7-A");
        return schoolClass;
    }

    private Exam createExam(Long examId, UserAccount teacher, SchoolClass schoolClass, String title) {
        Exam exam = new Exam();
        ReflectionTestUtils.setField(exam, "id", examId);
        exam.setTeacher(teacher);
        exam.setSchoolClass(schoolClass);
        exam.setTitle(title);
        exam.setStatus(ExamStatus.PROCESSING);
        return exam;
    }

    private ExamImage createImage(Exam exam, Long imageId, int pageOrder, ExamImageStatus status) {
        ExamImage image = new ExamImage();
        ReflectionTestUtils.setField(image, "id", imageId);
        image.setExam(exam);
        image.setPageOrder(pageOrder);
        image.setImageUrl("http://localhost/files/page-" + pageOrder + ".jpg");
        image.setStatus(status);
        return image;
    }

    private StudentNameMatcherService.StudentNameMatchResult matchedResult(
            String detectedStudentName,
            Long matchedStudentId,
            String matchedStudentName,
            double confidence
    ) {
        return new StudentNameMatcherService.StudentNameMatchResult(
                detectedStudentName,
                matchedStudentId,
                matchedStudentName,
                confidence,
                StudentMatchStatus.MATCHED,
                List.of(matchedStudentId)
        );
    }

    private StudentNameMatcherService.StudentNameMatchResult unmatchedResult(String detectedStudentName) {
        return new StudentNameMatcherService.StudentNameMatchResult(
                detectedStudentName,
                null,
                null,
                0.0,
                StudentMatchStatus.UNMATCHED,
                List.of()
        );
    }

    private Question createQuestion(Exam exam, ExamImage image, Integer order) {
        Question question = new Question();
        question.setExam(exam);
        question.setExamImage(image);
        question.setPageNumber(image.getPageOrder());
        question.setQuestionOrder(order);
        question.setSourceQuestionId("Q-1");
        question.setQuestionTextRaw("Question text");
        question.setStudentAnswerRaw("Answer");
        question.setConfidence(0.91);
        return question;
    }

    private ObjectNode mockOcrResult() {
        return mockOcrResult("Detected Student");
    }

    private ObjectNode mockOcrResult(String detectedStudentName) {
        ObjectNode question = jsonMapper.createObjectNode();
        question.put("question_id", "Q-1");
        question.put("question_text_raw", "Question text");
        question.put("student_answer_raw", "Answer");
        question.put("confidence", 0.91);

        ArrayNode questions = jsonMapper.createArrayNode();
        questions.add(question);

        ObjectNode page = jsonMapper.createObjectNode();
        page.put("page_number", 1);
        page.put("detected_student_name", detectedStudentName);
        page.put("name_confidence", detectedStudentName.isBlank() ? 0.0 : 0.88);
        page.set("questions", questions);

        ArrayNode pages = jsonMapper.createArrayNode();
        pages.add(page);

        ObjectNode result = jsonMapper.createObjectNode();
        result.set("pages", pages);
        return result;
    }
}
