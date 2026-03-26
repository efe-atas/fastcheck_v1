package com.fastcheck.fastcheck;

import com.fastcheck.fastcheck.auth.JwtTokenProvider;
import com.fastcheck.fastcheck.education.Exam;
import com.fastcheck.fastcheck.education.ExamImage;
import com.fastcheck.fastcheck.education.ExamImageStatus;
import com.fastcheck.fastcheck.education.ExamImageRepository;
import com.fastcheck.fastcheck.education.ExamRepository;
import com.fastcheck.fastcheck.education.ExamStatus;
import com.fastcheck.fastcheck.education.School;
import com.fastcheck.fastcheck.education.SchoolClass;
import com.fastcheck.fastcheck.education.SchoolClassRepository;
import com.fastcheck.fastcheck.education.SchoolRepository;
import com.fastcheck.fastcheck.ocr.OcrJob;
import com.fastcheck.fastcheck.ocr.OcrJobRepository;
import com.fastcheck.fastcheck.ocr.OcrJobStatus;
import com.fastcheck.fastcheck.user.Role;
import com.fastcheck.fastcheck.user.UserAccount;
import com.fastcheck.fastcheck.user.UserRepository;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class EducationControllerIntegrationTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwtTokenProvider jwtTokenProvider;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SchoolRepository schoolRepository;

    @Autowired
    private SchoolClassRepository schoolClassRepository;

    @Autowired
    private ExamRepository examRepository;

    @Autowired
    private ExamImageRepository examImageRepository;

    @Autowired
    private OcrJobRepository ocrJobRepository;

    @Test
    void adminCanCreateParentStudentLink() throws Exception {
        UserAccount admin = saveUser("admin@fastcheck.local", "Admin User", Role.ROLE_ADMIN);
        UserAccount parent = saveUser("parent@fastcheck.local", "Parent User", Role.ROLE_PARENT);
        UserAccount student = saveUser("student@fastcheck.local", "Student User", Role.ROLE_STUDENT);

        String token = bearerToken(admin);
        String body = """
                {
                  "parentUserId": %d,
                  "studentUserId": %d
                }
                """.formatted(parent.getId(), student.getId());

        mockMvc.perform(post("/v1/admin/parent-student-links")
                        .header("Authorization", token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.parentUserId").value(parent.getId()))
                .andExpect(jsonPath("$.studentUserId").value(student.getId()));
    }

    @Test
    void nonAdminCannotCreateParentStudentLink() throws Exception {
        UserAccount parentActor = saveUser("actor-parent@fastcheck.local", "Actor Parent", Role.ROLE_PARENT);
        UserAccount parent = saveUser("parent2@fastcheck.local", "Parent 2", Role.ROLE_PARENT);
        UserAccount student = saveUser("student2@fastcheck.local", "Student 2", Role.ROLE_STUDENT);

        String token = bearerToken(parentActor);
        String body = """
                {
                  "parentUserId": %d,
                  "studentUserId": %d
                }
                """.formatted(parent.getId(), student.getId());

        mockMvc.perform(post("/v1/admin/parent-student-links")
                        .header("Authorization", token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isForbidden());
    }

    @Test
    void teacherCanFetchExamAndOcrStatus() throws Exception {
        UserAccount teacher = saveUser("teacher@fastcheck.local", "Teacher User", Role.ROLE_TEACHER);
        School school = new School();
        school.setName("Test School");
        school = schoolRepository.save(school);
        teacher.setSchool(school);
        teacher = userRepository.save(teacher);

        SchoolClass schoolClass = new SchoolClass();
        schoolClass.setName("7-A");
        schoolClass.setSchool(school);
        schoolClass.setTeacher(teacher);
        schoolClass = schoolClassRepository.save(schoolClass);

        Exam exam = new Exam();
        exam.setTitle("Math Quiz");
        exam.setTeacher(teacher);
        exam.setSchoolClass(schoolClass);
        exam.setStatus(ExamStatus.PROCESSING);
        exam = examRepository.save(exam);

        ExamImage image = new ExamImage();
        image.setExam(exam);
        image.setPageOrder(1);
        image.setImageUrl("http://localhost:8080/files/page-1.png");
        image.setStatus(ExamImageStatus.COMPLETED);
        image = examImageRepository.save(image);

        OcrJob job = new OcrJob();
        job.setUser(teacher);
        job.setExamImage(image);
        job.setImageUrl(image.getImageUrl());
        job.setSourceId("exam-1-page-1");
        job.setRequestId(UUID.randomUUID());
        job.setStatus(OcrJobStatus.COMPLETED);
        job.setRetryCount(1);
        job.setOcrResultJson("{}");
        ocrJobRepository.save(job);

        mockMvc.perform(get("/v1/teacher/exams/{examId}", exam.getId())
                        .header("Authorization", bearerToken(teacher)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.examId").value(exam.getId()))
                .andExpect(jsonPath("$.examStatus").value("PROCESSING"))
                .andExpect(jsonPath("$.images[0].status").value("COMPLETED"))
                .andExpect(jsonPath("$.ocrJobs[0].status").value("COMPLETED"))
                .andExpect(jsonPath("$.ocrJobs[0].retryCount").value(1));
    }

    @Test
    void studentCannotFetchTeacherExamStatusEndpoint() throws Exception {
        UserAccount student = saveUser("viewer-student@fastcheck.local", "Viewer Student", Role.ROLE_STUDENT);

        mockMvc.perform(get("/v1/teacher/exams/123")
                        .header("Authorization", bearerToken(student)))
                .andExpect(status().isForbidden());
    }

        @Test
        void teacherCanListOwnClassesAndClassExams() throws Exception {
        UserAccount teacher = saveUser("teacher-list@fastcheck.local", "Teacher List", Role.ROLE_TEACHER);
        School school = new School();
        school.setName("List School");
        school = schoolRepository.save(school);
        teacher.setSchool(school);
        teacher = userRepository.save(teacher);

        SchoolClass schoolClass = new SchoolClass();
        schoolClass.setName("8-B");
        schoolClass.setSchool(school);
        schoolClass.setTeacher(teacher);
        schoolClass = schoolClassRepository.save(schoolClass);

        Exam exam = new Exam();
        exam.setTitle("Science Quiz");
        exam.setTeacher(teacher);
        exam.setSchoolClass(schoolClass);
        exam.setStatus(ExamStatus.DRAFT);
        exam = examRepository.save(exam);

        mockMvc.perform(get("/v1/teacher/classes")
                .header("Authorization", bearerToken(teacher)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$[0].classId").value(schoolClass.getId()))
            .andExpect(jsonPath("$[0].examCount").value(1));

        mockMvc.perform(get("/v1/teacher/classes/{classId}/exams", schoolClass.getId())
                .header("Authorization", bearerToken(teacher)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$[0].examId").value(exam.getId()))
            .andExpect(jsonPath("$[0].status").value("DRAFT"));
        }

        @Test
        void adminCanListStudentsOfParent() throws Exception {
        UserAccount admin = saveUser("admin-list@fastcheck.local", "Admin List", Role.ROLE_ADMIN);
        UserAccount parent = saveUser("parent-list@fastcheck.local", "Parent List", Role.ROLE_PARENT);
        UserAccount student = saveUser("student-list@fastcheck.local", "Student List", Role.ROLE_STUDENT);

        String linkBody = """
            {
              "parentUserId": %d,
              "studentUserId": %d
            }
            """.formatted(parent.getId(), student.getId());

        mockMvc.perform(post("/v1/admin/parent-student-links")
                .header("Authorization", bearerToken(admin))
                .contentType(MediaType.APPLICATION_JSON)
                .content(linkBody))
            .andExpect(status().isCreated());

        mockMvc.perform(get("/v1/admin/parents/{parentUserId}/students", parent.getId())
                .header("Authorization", bearerToken(admin)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$[0].userId").value(student.getId()))
            .andExpect(jsonPath("$[0].fullName").value("Student List"));
        }

    @Test
    void adminCanSearchUsersAndSchools() throws Exception {
        UserAccount admin = saveUser("admin-search@fastcheck.local", "Admin Search", Role.ROLE_ADMIN);
        UserAccount teacher = saveUser("teacher-search@fastcheck.local", "Alpha Teacher", Role.ROLE_TEACHER);
        saveUser("student-search@fastcheck.local", "Beta Student", Role.ROLE_STUDENT);

        School schoolA = new School();
        schoolA.setName("Ankara Campus");
        schoolA = schoolRepository.save(schoolA);
        School schoolB = new School();
        schoolB.setName("Izmir Campus");
        schoolRepository.save(schoolB);

        teacher.setSchool(schoolA);
        userRepository.save(teacher);

        mockMvc.perform(get("/v1/admin/users")
                        .param("role", "ROLE_TEACHER")
                        .param("q", "alpha")
                        .header("Authorization", bearerToken(admin)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[0].email").value("teacher-search@fastcheck.local"))
                .andExpect(jsonPath("$.items[0].schoolId").value(schoolA.getId()));

        mockMvc.perform(get("/v1/admin/schools")
                        .param("q", "campus")
                        .header("Authorization", bearerToken(admin)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[0].schoolName").exists())
                .andExpect(jsonPath("$.totalElements").value(2));
    }

    @Test
    void adminCanBulkAssignUsersAndLinkParentStudentsWithPartialFailures() throws Exception {
        UserAccount admin = saveUser("admin-bulk@fastcheck.local", "Admin Bulk", Role.ROLE_ADMIN);
        UserAccount student = saveUser("student-bulk@fastcheck.local", "Student Bulk", Role.ROLE_STUDENT);
        UserAccount parent = saveUser("parent-bulk@fastcheck.local", "Parent Bulk", Role.ROLE_PARENT);

        School school = new School();
        school.setName("Bulk School");
        school = schoolRepository.save(school);

        MockMultipartFile assignCsv = new MockMultipartFile(
                "file",
                "assign.csv",
                "text/csv",
                ("""
                        userEmail,schoolName
                        student-bulk@fastcheck.local,Bulk School
                        missing@fastcheck.local,Bulk School
                        """).getBytes()
        );

        mockMvc.perform(multipart("/v1/admin/users/schools/bulk")
                        .file(assignCsv)
                        .header("Authorization", bearerToken(admin)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.processed").value(2))
                .andExpect(jsonPath("$.success").value(1))
                .andExpect(jsonPath("$.failed").value(1))
                .andExpect(jsonPath("$.errors[0].rowNumber").value(3));

        MockMultipartFile linkCsv = new MockMultipartFile(
                "file",
                "links.csv",
                "text/csv",
                ("""
                        parentEmail,studentEmail
                        parent-bulk@fastcheck.local,student-bulk@fastcheck.local
                        parent-bulk@fastcheck.local,missing-student@fastcheck.local
                        """).getBytes()
        );

        mockMvc.perform(multipart("/v1/admin/parent-student-links/bulk")
                        .file(linkCsv)
                        .header("Authorization", bearerToken(admin)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.processed").value(2))
                .andExpect(jsonPath("$.success").value(1))
                .andExpect(jsonPath("$.failed").value(1))
                .andExpect(jsonPath("$.errors[0].rowNumber").value(3));
    }

    @Test
    void teacherCanListClassRoster() throws Exception {
        UserAccount teacher = saveUser("teacher-roster@fastcheck.local", "Teacher Roster", Role.ROLE_TEACHER);
        School school = new School();
        school.setName("Roster School");
        school = schoolRepository.save(school);
        teacher.setSchool(school);
        teacher = userRepository.save(teacher);

        SchoolClass schoolClass = new SchoolClass();
        schoolClass.setName("9-C");
        schoolClass.setSchool(school);
        schoolClass.setTeacher(teacher);
        schoolClass = schoolClassRepository.save(schoolClass);

        UserAccount studentA = saveUser("a-student@fastcheck.local", "Alice Student", Role.ROLE_STUDENT);
        studentA.setSchool(school);
        studentA.setSchoolClass(schoolClass);
        userRepository.save(studentA);

        UserAccount studentB = saveUser("b-student@fastcheck.local", "Bob Student", Role.ROLE_STUDENT);
        studentB.setSchool(school);
        studentB.setSchoolClass(schoolClass);
        userRepository.save(studentB);

        mockMvc.perform(get("/v1/teacher/classes/{classId}/students", schoolClass.getId())
                        .header("Authorization", bearerToken(teacher)))
                .andExpect(status().isOk())
            .andExpect(jsonPath("$.items[0].classId").value(schoolClass.getId()))
            .andExpect(jsonPath("$.items[0].fullName").value("Alice Student"))
            .andExpect(jsonPath("$.items[1].fullName").value("Bob Student"))
            .andExpect(jsonPath("$.totalElements").value(2));
    }

    @Test
    void studentCanListOwnClassExams() throws Exception {
        UserAccount teacher = saveUser("teacher-student-exam@fastcheck.local", "Teacher For Student", Role.ROLE_TEACHER);
        UserAccount student = saveUser("student-exam-list@fastcheck.local", "Student Exam List", Role.ROLE_STUDENT);

        School school = new School();
        school.setName("Student Exam School");
        school = schoolRepository.save(school);

        teacher.setSchool(school);
        teacher = userRepository.save(teacher);

        SchoolClass schoolClass = new SchoolClass();
        schoolClass.setName("10-A");
        schoolClass.setSchool(school);
        schoolClass.setTeacher(teacher);
        schoolClass = schoolClassRepository.save(schoolClass);

        student.setSchool(school);
        student.setSchoolClass(schoolClass);
        student = userRepository.save(student);

        Exam exam = new Exam();
        exam.setTitle("History Midterm");
        exam.setTeacher(teacher);
        exam.setSchoolClass(schoolClass);
        exam.setStatus(ExamStatus.READY);
        exam = examRepository.save(exam);

        mockMvc.perform(get("/v1/student/exams")
                        .header("Authorization", bearerToken(student)))
                .andExpect(status().isOk())
            .andExpect(jsonPath("$.items[0].examId").value(exam.getId()))
            .andExpect(jsonPath("$.items[0].status").value("READY"))
            .andExpect(jsonPath("$.items[0].classId").value(schoolClass.getId()))
            .andExpect(jsonPath("$.totalElements").value(1));

        mockMvc.perform(get("/v1/student/exams")
                .param("examStatus", "READY")
                .header("Authorization", bearerToken(student)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.items[0].status").value("READY"));
    }

    private UserAccount saveUser(String email, String fullName, Role role) {
        UserAccount user = new UserAccount();
        user.setEmail(email);
        user.setFullName(fullName);
        user.setPasswordHash("noop-password");
        user.setRole(role);
        return userRepository.save(user);
    }

    private String bearerToken(UserAccount user) {
        return "Bearer " + jwtTokenProvider.createAccessToken(user.getId(), user.getEmail(), user.getRole().name());
    }
}
