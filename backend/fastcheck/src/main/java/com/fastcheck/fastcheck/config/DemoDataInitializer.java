package com.fastcheck.fastcheck.config;

import com.fastcheck.fastcheck.education.Exam;
import com.fastcheck.fastcheck.education.ExamImage;
import com.fastcheck.fastcheck.education.ExamImageRepository;
import com.fastcheck.fastcheck.education.ExamImageStatus;
import com.fastcheck.fastcheck.education.ExamRepository;
import com.fastcheck.fastcheck.education.ExamStatus;
import com.fastcheck.fastcheck.education.GradingStatus;
import com.fastcheck.fastcheck.education.ParentStudentLink;
import com.fastcheck.fastcheck.education.ParentStudentLinkRepository;
import com.fastcheck.fastcheck.education.Question;
import com.fastcheck.fastcheck.education.QuestionRepository;
import com.fastcheck.fastcheck.education.QuestionType;
import com.fastcheck.fastcheck.education.School;
import com.fastcheck.fastcheck.education.SchoolClass;
import com.fastcheck.fastcheck.education.SchoolClassRepository;
import com.fastcheck.fastcheck.education.SchoolRepository;
import com.fastcheck.fastcheck.education.StudentExamResult;
import com.fastcheck.fastcheck.education.StudentExamResultRepository;
import com.fastcheck.fastcheck.education.StudentMatchStatus;
import com.fastcheck.fastcheck.user.Role;
import com.fastcheck.fastcheck.user.UserAccount;
import com.fastcheck.fastcheck.user.UserRepository;
import java.time.Instant;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
public class DemoDataInitializer implements CommandLineRunner {

    private static final Logger LOG = LoggerFactory.getLogger(DemoDataInitializer.class);

    private static final String DEMO_SCHOOL_NAME = "Izmir Basari Anadolu Lisesi";
    private static final String DEMO_CLASS_NAME = "12-A Sayisal";

    private static final String ADMIN_NAME = "Sema Kaya";
    private static final String ADMIN_EMAIL = "demo.admin@fastcheck.app";
    private static final String ADMIN_PASSWORD = "Demo123!";

    private static final String TEACHER_NAME = "Mert Yildirim";
    private static final String TEACHER_EMAIL = "demo.ogretmen@fastcheck.app";
    private static final String TEACHER_PASSWORD = "Demo123!";

    private static final String PARENT_NAME = "Zeynep Aydin";
    private static final String PARENT_EMAIL = "demo.veli@fastcheck.app";
    private static final String PARENT_PASSWORD = "Demo123!";

    private static final String STUDENT_ONE_NAME = "Ayse Aydin";
    private static final String STUDENT_ONE_EMAIL = "demo.ogrenci1@fastcheck.app";
    private static final String STUDENT_ONE_PASSWORD = "Demo123!";

    private static final String STUDENT_TWO_NAME = "Can Demir";
    private static final String STUDENT_TWO_EMAIL = "demo.ogrenci2@fastcheck.app";
    private static final String STUDENT_TWO_PASSWORD = "Demo123!";

    private static final String READY_EXAM_TITLE = "TYT Matematik Deneme 1";
    private static final String DRAFT_EXAM_TITLE = "AYT Geometri Tarama 2";

    private final SchoolRepository schoolRepository;
    private final SchoolClassRepository schoolClassRepository;
    private final ExamRepository examRepository;
    private final ExamImageRepository examImageRepository;
    private final QuestionRepository questionRepository;
    private final StudentExamResultRepository studentExamResultRepository;
    private final ParentStudentLinkRepository parentStudentLinkRepository;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public DemoDataInitializer(
            SchoolRepository schoolRepository,
            SchoolClassRepository schoolClassRepository,
            ExamRepository examRepository,
            ExamImageRepository examImageRepository,
            QuestionRepository questionRepository,
            StudentExamResultRepository studentExamResultRepository,
            ParentStudentLinkRepository parentStudentLinkRepository,
            UserRepository userRepository,
            PasswordEncoder passwordEncoder
    ) {
        this.schoolRepository = schoolRepository;
        this.schoolClassRepository = schoolClassRepository;
        this.examRepository = examRepository;
        this.examImageRepository = examImageRepository;
        this.questionRepository = questionRepository;
        this.studentExamResultRepository = studentExamResultRepository;
        this.parentStudentLinkRepository = parentStudentLinkRepository;
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional
    public void run(String... args) {
        School school = schoolRepository.findByNameIgnoreCase(DEMO_SCHOOL_NAME).orElseGet(() -> {
            School created = new School();
            created.setName(DEMO_SCHOOL_NAME);
            School saved = schoolRepository.save(created);
            LOG.info("Demo school created: {} (id={})", DEMO_SCHOOL_NAME, saved.getId());
            return saved;
        });

        UserAccount admin = upsertUser(ADMIN_EMAIL, ADMIN_NAME, ADMIN_PASSWORD, Role.ROLE_ADMIN, school, null);
        UserAccount teacher = upsertUser(TEACHER_EMAIL, TEACHER_NAME, TEACHER_PASSWORD, Role.ROLE_TEACHER, school, null);

        if (teacher.getRole() != Role.ROLE_TEACHER) {
            LOG.warn("Demo teacher email exists with non-teacher role: {}", TEACHER_EMAIL);
            return;
        }

        SchoolClass schoolClass = schoolClassRepository
                .findFirstByTeacher_IdAndSchool_IdAndNameIgnoreCase(teacher.getId(), school.getId(), DEMO_CLASS_NAME)
                .orElseGet(() -> {
                    SchoolClass created = new SchoolClass();
                    created.setSchool(school);
                    created.setTeacher(teacher);
                    created.setName(DEMO_CLASS_NAME);
                    SchoolClass saved = schoolClassRepository.save(created);
                    LOG.info("Demo class created: {} (id={})", DEMO_CLASS_NAME, saved.getId());
                    return saved;
                });

        UserAccount parent = upsertUser(PARENT_EMAIL, PARENT_NAME, PARENT_PASSWORD, Role.ROLE_PARENT, school, null);
        UserAccount studentOne = upsertUser(
                STUDENT_ONE_EMAIL,
                STUDENT_ONE_NAME,
                STUDENT_ONE_PASSWORD,
                Role.ROLE_STUDENT,
                school,
                schoolClass
        );
        UserAccount studentTwo = upsertUser(
                STUDENT_TWO_EMAIL,
                STUDENT_TWO_NAME,
                STUDENT_TWO_PASSWORD,
                Role.ROLE_STUDENT,
                school,
                schoolClass
        );

        ensureParentLink(parent, studentOne);
        ensureParentLink(parent, studentTwo);

        Exam readyExam = upsertExam(
                READY_EXAM_TITLE,
                ExamStatus.READY,
                "4 soru, toplam 40 puan. Her soru 10 puan. OCR ve manuel kontrol tamamlandi.",
                40.0,
                schoolClass,
                teacher
        );
        ensureReadyExamArtifacts(readyExam, studentOne, studentTwo);

        upsertExam(
                DRAFT_EXAM_TITLE,
                ExamStatus.DRAFT,
                "3 sayfa yuklenecek geometri tarama sinavi. Henuz islenmedi.",
                30.0,
                schoolClass,
                teacher
        );

        LOG.info(
                "Demo dataset ready for presentation. admin={}, teacher={}, parent={}, students={} + {}",
                admin.getEmail(),
                teacher.getEmail(),
                parent.getEmail(),
                studentOne.getEmail(),
                studentTwo.getEmail()
        );
    }

    private UserAccount upsertUser(
            String email,
            String fullName,
            String rawPassword,
            Role role,
            School school,
            SchoolClass schoolClass
    ) {
        UserAccount user = userRepository.findByEmailIgnoreCase(email).orElse(null);
        if (user == null) {
            user = new UserAccount();
            user.setEmail(email);
            user.setPasswordHash(passwordEncoder.encode(rawPassword));
        } else if (user.getRole() != role) {
            LOG.warn("Demo user email exists with non-matching role: {} expected={} actual={}", email, role, user.getRole());
            return user;
        }

        user.setFullName(fullName);
        user.setRole(role);
        user.setSchool(school);
        user.setSchoolClass(role == Role.ROLE_STUDENT ? schoolClass : null);
        user.setUpdatedAt(Instant.now());
        UserAccount saved = userRepository.save(user);
        LOG.info("Demo user ready: {} ({})", saved.getEmail(), saved.getRole());
        return saved;
    }

    private void ensureParentLink(UserAccount parent, UserAccount student) {
        if (!parentStudentLinkRepository.existsByParent_IdAndStudent_Id(parent.getId(), student.getId())) {
            ParentStudentLink link = new ParentStudentLink();
            link.setParent(parent);
            link.setStudent(student);
            parentStudentLinkRepository.save(link);
            LOG.info("Demo parent link created: parent={} student={}", parent.getEmail(), student.getEmail());
        }
    }

    private Exam upsertExam(
            String title,
            ExamStatus status,
            String gradingSummary,
            Double totalMaxPoints,
            SchoolClass schoolClass,
            UserAccount teacher
    ) {
        Exam exam = examRepository.findFirstBySchoolClass_IdAndTitleIgnoreCase(schoolClass.getId(), title).orElse(null);
        if (exam == null) {
            exam = new Exam();
            exam.setSchoolClass(schoolClass);
            exam.setTeacher(teacher);
            exam.setTitle(title);
        }

        exam.setStatus(status);
        exam.setGradingSystemSummary(gradingSummary);
        exam.setTotalMaxPoints(totalMaxPoints);
        Exam saved = examRepository.save(exam);
        LOG.info("Demo exam ready: {} status={}", saved.getTitle(), saved.getStatus());
        return saved;
    }

    private void ensureReadyExamArtifacts(Exam exam, UserAccount studentOne, UserAccount studentTwo) {
        List<ExamImage> existingImages = examImageRepository.findByExam_IdOrderByPageOrderAsc(exam.getId());
        ExamImage imageOne = existingImages.size() >= 1 ? existingImages.get(0) : createExamImage(
                exam,
                1,
                "https://api.efeatas.dev/api/files/demo-ayse-tyt-matematik-sayfa-1.jpg"
        );
        ExamImage imageTwo = existingImages.size() >= 2 ? existingImages.get(1) : createExamImage(
                exam,
                2,
                "https://api.efeatas.dev/api/files/demo-can-tyt-matematik-sayfa-1.jpg"
        );

        String candidateIds = studentOne.getId() + "," + studentTwo.getId();
        syncExamImage(imageOne, studentOne, "Ayse Aydin", candidateIds);
        syncExamImage(imageTwo, studentTwo, "Can Demir", candidateIds);

        ensureQuestions(exam, imageOne, List.of(
                new DemoQuestion("Q1", "Bir fonksiyonun tanim kumesi nedir?", "Fonksiyonun girdi olarak alabildigi degerlerdir.", "Girdi degerleri kumesi", 10.0, 10.0, true, "Tam ve dogru tanim verdi."),
                new DemoQuestion("Q2", "x^2 - 5x + 6 = 0 denkleminin koklerini bulun.", "x=2 ve x=3", "2 ve 3", 10.0, 9.0, true, "Kokleri dogru buldu, yazim bicimi kismen eksik.")
        ));
        ensureQuestions(exam, imageTwo, List.of(
                new DemoQuestion("Q3", "Bir ucgenin ic acilar toplami kac derecedir?", "180 derecedir.", "180", 10.0, 10.0, true, "Dogru cevap."),
                new DemoQuestion("Q4", "2, 4, 8, 16 dizisinin genel kurali nedir?", "2 ussu n seklindedir.", "2^n", 10.0, 8.0, false, "Geometrik artis fikri dogru, ifade daha net olabilir.")
        ));

        ensureStudentResult(
                exam,
                studentOne,
                2,
                2,
                20.0,
                19.0,
                0.96,
                "Ayse sinavin genelinde yuksek dogruluk gosterdi; ikinci soruda kismi puan uygulandi."
        );
        ensureStudentResult(
                exam,
                studentTwo,
                2,
                2,
                20.0,
                18.0,
                0.91,
                "Can temel kavramlarda basarili; son soruda ifade netligi nedeniyle kismi puan aldi."
        );
    }

    private ExamImage createExamImage(Exam exam, int pageOrder, String imageUrl) {
        ExamImage image = new ExamImage();
        image.setExam(exam);
        image.setPageOrder(pageOrder);
        image.setImageUrl(imageUrl);
        ExamImage saved = examImageRepository.save(image);
        LOG.info("Demo exam image created: exam={} pageOrder={}", exam.getTitle(), pageOrder);
        return saved;
    }

    private void syncExamImage(ExamImage image, UserAccount student, String detectedStudentName, String candidateIds) {
        image.setStatus(ExamImageStatus.COMPLETED);
        image.setDetectedStudentName(detectedStudentName);
        image.setDetectedStudentNameConfidence(0.99);
        image.setMatchedStudentId(student.getId());
        image.setMatchedStudentName(student.getFullName());
        image.setStudentMatchConfidence(0.98);
        image.setStudentMatchStatus(StudentMatchStatus.MATCHED);
        image.setCandidateStudentIds(candidateIds);
        image.setProcessingStartedAt(Instant.now());
        image.setProcessingCompletedAt(Instant.now());
        examImageRepository.save(image);
    }

    private void ensureQuestions(Exam exam, ExamImage image, List<DemoQuestion> demoQuestions) {
        List<Question> existing = questionRepository.findByExamImage_IdOrderByQuestionOrderAsc(image.getId());
        if (!existing.isEmpty()) {
            return;
        }

        int order = 1;
        for (DemoQuestion demoQuestion : demoQuestions) {
            Question question = new Question();
            question.setExam(exam);
            question.setExamImage(image);
            question.setSourceQuestionId(demoQuestion.sourceQuestionId());
            question.setPageNumber(image.getPageOrder());
            question.setQuestionOrder(order++);
            question.setQuestionTextRaw(demoQuestion.questionText());
            question.setStudentAnswerRaw(demoQuestion.studentAnswer());
            question.setQuestionType(QuestionType.OPEN_ENDED);
            question.setExpectedAnswerRaw(demoQuestion.expectedAnswer());
            question.setGradingRubricRaw("Tam dogru cevap 10 puan, eksik gerekce veya ifade kaybi durumunda kismi puan.");
            question.setMaxPoints(demoQuestion.maxPoints());
            question.setAwardedPoints(demoQuestion.awardedPoints());
            question.setGradingConfidence(0.94);
            question.setGradingStatus(GradingStatus.GRADED);
            question.setEvaluationSummary(demoQuestion.evaluationSummary());
            question.setCorrect(demoQuestion.correct());
            question.setConfidence(0.97);
            questionRepository.save(question);
        }
    }

    private void ensureStudentResult(
            Exam exam,
            UserAccount student,
            int totalQuestions,
            int scoredQuestions,
            double maxPoints,
            double awardedPoints,
            double gradingConfidence,
            String gradingSummary
    ) {
        StudentExamResult result = studentExamResultRepository.findByExam_IdAndStudentId(exam.getId(), student.getId())
                .orElseGet(StudentExamResult::new);
        result.setExam(exam);
        result.setStudentId(student.getId());
        result.setStudentName(student.getFullName());
        result.setTotalQuestions(totalQuestions);
        result.setScoredQuestions(scoredQuestions);
        result.setMaxPoints(maxPoints);
        result.setAwardedPoints(awardedPoints);
        result.setGradingConfidence(gradingConfidence);
        result.setGradingStatus(GradingStatus.GRADED);
        result.setGradingSummary(gradingSummary);
        result.setUpdatedAt(Instant.now());
        studentExamResultRepository.save(result);
    }

    private record DemoQuestion(
            String sourceQuestionId,
            String questionText,
            String studentAnswer,
            String expectedAnswer,
            Double maxPoints,
            Double awardedPoints,
            Boolean correct,
            String evaluationSummary
    ) {
    }
}
