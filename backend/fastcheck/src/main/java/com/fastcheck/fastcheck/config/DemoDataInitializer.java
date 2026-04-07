package com.fastcheck.fastcheck.config;

import com.fastcheck.fastcheck.education.Exam;
import com.fastcheck.fastcheck.education.ExamRepository;
import com.fastcheck.fastcheck.education.ExamStatus;
import com.fastcheck.fastcheck.education.School;
import com.fastcheck.fastcheck.education.SchoolClass;
import com.fastcheck.fastcheck.education.SchoolClassRepository;
import com.fastcheck.fastcheck.education.SchoolRepository;
import com.fastcheck.fastcheck.user.Role;
import com.fastcheck.fastcheck.user.UserAccount;
import com.fastcheck.fastcheck.user.UserRepository;
import java.time.Instant;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
public class DemoDataInitializer implements CommandLineRunner {

    private static final Logger LOG = LoggerFactory.getLogger(DemoDataInitializer.class);

    private static final String DEMO_SCHOOL_NAME = "FastCheck Demo Okulu";
    private static final String DEMO_CLASS_NAME = "12-A";
    private static final String DEMO_TEACHER_NAME = "Demo Ogretmen";
    private static final String DEMO_TEACHER_EMAIL = "ogretmen@yopmail.com";
    private static final String DEMO_TEACHER_PASSWORD = "deneme123";
    private static final String DEMO_STUDENT_NAME = "Demo Ogrenci";
    private static final String DEMO_STUDENT_EMAIL = "ogrenci@yopmail.com";
    private static final String DEMO_STUDENT_PASSWORD = "deneme123";
    private static final String DEMO_EXAM_TITLE = "Demo OCR Sinavi";

    private final SchoolRepository schoolRepository;
    private final SchoolClassRepository schoolClassRepository;
    private final ExamRepository examRepository;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public DemoDataInitializer(
            SchoolRepository schoolRepository,
            SchoolClassRepository schoolClassRepository,
            ExamRepository examRepository,
            UserRepository userRepository,
            PasswordEncoder passwordEncoder
    ) {
        this.schoolRepository = schoolRepository;
        this.schoolClassRepository = schoolClassRepository;
        this.examRepository = examRepository;
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional
    public void run(String... args) {
        School school = schoolRepository.findByNameIgnoreCase(DEMO_SCHOOL_NAME)
                .orElseGet(this::createSchool);

        UserAccount teacher = userRepository.findByEmailIgnoreCase(DEMO_TEACHER_EMAIL)
                .orElseGet(() -> createTeacher(school));

        if (teacher.getRole() != Role.ROLE_TEACHER) {
            LOG.warn("Demo teacher email exists with non-teacher role: {}", DEMO_TEACHER_EMAIL);
            return;
        }

        boolean teacherUpdated = false;
        if (teacher.getSchool() == null || !teacher.getSchool().getId().equals(school.getId())) {
            teacher.setSchool(school);
            teacher.setUpdatedAt(Instant.now());
            teacher = userRepository.save(teacher);
            teacherUpdated = true;
        }

        if (teacherUpdated) {
            LOG.info("Demo teacher school assignment updated: {}", DEMO_TEACHER_EMAIL);
        }

        SchoolClass schoolClass = schoolClassRepository
                .findFirstByTeacher_IdAndSchool_IdAndNameIgnoreCase(teacher.getId(), school.getId(), DEMO_CLASS_NAME)
                .orElse(null);
        if (schoolClass == null) {
            schoolClass = createClass(school, teacher);
        }

        UserAccount student = userRepository.findByEmailIgnoreCase(DEMO_STUDENT_EMAIL)
                .orElse(null);
        if (student == null) {
            student = createStudent(school, schoolClass);
        }

        boolean studentUpdated = false;
        if (student.getRole() == Role.ROLE_STUDENT) {
            if (student.getSchool() == null || !student.getSchool().getId().equals(school.getId())) {
                student.setSchool(school);
                studentUpdated = true;
            }
            if (student.getSchoolClass() == null || !student.getSchoolClass().getId().equals(schoolClass.getId())) {
                student.setSchoolClass(schoolClass);
                studentUpdated = true;
            }
            if (studentUpdated) {
                student.setUpdatedAt(Instant.now());
                userRepository.save(student);
                LOG.info("Demo student assignment updated: {}", DEMO_STUDENT_EMAIL);
            }
        } else {
            LOG.warn("Demo student email exists with non-student role: {}", DEMO_STUDENT_EMAIL);
        }

        Exam existingExam = examRepository.findFirstBySchoolClass_IdAndTitleIgnoreCase(schoolClass.getId(), DEMO_EXAM_TITLE)
                .orElse(null);
        if (existingExam == null) {
            createExam(schoolClass, teacher);
        }
    }

    private School createSchool() {
        School school = new School();
        school.setName(DEMO_SCHOOL_NAME);
        School saved = schoolRepository.save(school);
        LOG.info("Demo school created: {} (id={})", DEMO_SCHOOL_NAME, saved.getId());
        return saved;
    }

    private UserAccount createTeacher(School school) {
        UserAccount teacher = new UserAccount();
        teacher.setFullName(DEMO_TEACHER_NAME);
        teacher.setEmail(DEMO_TEACHER_EMAIL);
        teacher.setPasswordHash(passwordEncoder.encode(DEMO_TEACHER_PASSWORD));
        teacher.setRole(Role.ROLE_TEACHER);
        teacher.setSchool(school);
        teacher.setUpdatedAt(Instant.now());
        UserAccount saved = userRepository.save(teacher);
        LOG.info("Demo teacher created: {} (id={})", DEMO_TEACHER_EMAIL, saved.getId());
        return saved;
    }

    private SchoolClass createClass(School school, UserAccount teacher) {
        SchoolClass schoolClass = new SchoolClass();
        schoolClass.setSchool(school);
        schoolClass.setTeacher(teacher);
        schoolClass.setName(DEMO_CLASS_NAME);
        SchoolClass saved = schoolClassRepository.save(schoolClass);
        LOG.info("Demo class created: {} (id={})", DEMO_CLASS_NAME, saved.getId());
        return saved;
    }

    private UserAccount createStudent(School school, SchoolClass schoolClass) {
        UserAccount student = new UserAccount();
        student.setFullName(DEMO_STUDENT_NAME);
        student.setEmail(DEMO_STUDENT_EMAIL);
        student.setPasswordHash(passwordEncoder.encode(DEMO_STUDENT_PASSWORD));
        student.setRole(Role.ROLE_STUDENT);
        student.setSchool(school);
        student.setSchoolClass(schoolClass);
        student.setUpdatedAt(Instant.now());
        UserAccount saved = userRepository.save(student);
        LOG.info("Demo student created: {} (id={})", DEMO_STUDENT_EMAIL, saved.getId());
        return saved;
    }

    private Exam createExam(SchoolClass schoolClass, UserAccount teacher) {
        Exam exam = new Exam();
        exam.setSchoolClass(schoolClass);
        exam.setTeacher(teacher);
        exam.setTitle(DEMO_EXAM_TITLE);
        exam.setStatus(ExamStatus.DRAFT);
        Exam saved = examRepository.save(exam);
        LOG.info("Demo exam created: {} (id={})", DEMO_EXAM_TITLE, saved.getId());
        return saved;
    }
}
