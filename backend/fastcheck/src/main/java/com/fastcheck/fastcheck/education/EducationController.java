package com.fastcheck.fastcheck.education;

import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/v1")
public class EducationController {

    private final AdminEducationService adminEducationService;
    private final TeacherEducationService teacherEducationService;
    private final StudentEducationService studentEducationService;

    public EducationController(
            AdminEducationService adminEducationService,
            TeacherEducationService teacherEducationService,
            StudentEducationService studentEducationService
    ) {
        this.adminEducationService = adminEducationService;
        this.teacherEducationService = teacherEducationService;
        this.studentEducationService = studentEducationService;
    }

    @PostMapping("/admin/schools")
    @ResponseStatus(HttpStatus.CREATED)
    public EducationDtos.SchoolResponse createSchool(@Valid @RequestBody EducationDtos.CreateSchoolRequest request) {
        return adminEducationService.createSchool(request);
    }

    @PostMapping("/admin/users/{userId}/schools/{schoolId}")
    public EducationDtos.StudentResponse assignUserToSchool(@PathVariable Long userId, @PathVariable Long schoolId) {
        return adminEducationService.assignUserToSchool(userId, schoolId);
    }

    @GetMapping("/admin/users")
    public EducationDtos.PagedResponse<EducationDtos.AdminUserSummary> listAdminUsers(
            @RequestParam(name = "role", required = false) String role,
            @RequestParam(name = "q", required = false) String q,
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "20") int size
    ) {
        return adminEducationService.listUsers(role, q, page, size);
    }

    @GetMapping("/admin/schools")
    public EducationDtos.PagedResponse<EducationDtos.AdminSchoolSummary> listSchools(
            @RequestParam(name = "q", required = false) String q,
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "20") int size
    ) {
        return adminEducationService.listSchools(q, page, size);
    }

    @PostMapping("/admin/users/schools/bulk")
    public EducationDtos.BulkOperationResponse bulkAssignUsersToSchools(
            @RequestParam("file") MultipartFile file
    ) {
        return adminEducationService.bulkAssignUsersToSchools(file);
    }

    @PostMapping("/admin/parent-student-links")
    @ResponseStatus(HttpStatus.CREATED)
    public EducationDtos.ParentStudentLinkResponse linkParentStudent(
            @Valid @RequestBody EducationDtos.ParentStudentLinkRequest request
    ) {
        return adminEducationService.linkParentStudent(request);
    }

    @PostMapping("/admin/parent-student-links/bulk")
    public EducationDtos.BulkOperationResponse bulkLinkParentStudents(
            @RequestParam("file") MultipartFile file
    ) {
        return adminEducationService.bulkLinkParentStudents(file);
    }

    @GetMapping("/admin/parents/{parentUserId}/students")
    public List<EducationDtos.ParentStudentView> listParentStudents(@PathVariable Long parentUserId) {
        return adminEducationService.listParentStudents(parentUserId);
    }

    @PostMapping("/teacher/classes")
    @ResponseStatus(HttpStatus.CREATED)
    public EducationDtos.ClassResponse createClass(@Valid @RequestBody EducationDtos.CreateClassRequest request) {
        return teacherEducationService.createClass(request);
    }

    @PostMapping("/teacher/classes/{classId}/students")
    @ResponseStatus(HttpStatus.CREATED)
    public EducationDtos.StudentResponse createStudent(
            @PathVariable Long classId,
            @Valid @RequestBody EducationDtos.CreateStudentRequest request
    ) {
        return teacherEducationService.createStudent(classId, request);
    }

    @PostMapping("/teacher/classes/{classId}/exams")
    @ResponseStatus(HttpStatus.CREATED)
    public EducationDtos.ExamResponse createExam(
            @PathVariable Long classId,
            @Valid @RequestBody EducationDtos.CreateExamRequest request
    ) {
        return teacherEducationService.createExam(classId, request);
    }

    @PostMapping("/teacher/exams/{examId}/images")
    public EducationDtos.UploadExamImagesResponse uploadImages(
            @PathVariable Long examId,
            @RequestParam("images") List<MultipartFile> images
    ) {
        return teacherEducationService.uploadExamImages(examId, images);
    }

    @GetMapping("/teacher/exams/{examId}")
    public EducationDtos.TeacherExamStatusResponse getTeacherExamStatus(@PathVariable Long examId) {
        return teacherEducationService.getExamStatus(examId);
    }

    @PostMapping("/teacher/exams/{examId}/reprocess")
    public EducationDtos.TeacherExamStatusResponse reprocessExam(@PathVariable Long examId) {
        return teacherEducationService.reprocessExam(examId);
    }

    @PatchMapping("/teacher/exams/{examId}/images/{imageId}/student-match")
    public EducationDtos.TeacherExamStatusResponse updateExamImageStudentMatch(
            @PathVariable Long examId,
            @PathVariable Long imageId,
            @Valid @RequestBody EducationDtos.UpdateExamImageStudentMatchRequest request
    ) {
        return teacherEducationService.updateExamImageStudentMatch(examId, imageId, request);
    }

    @PatchMapping("/teacher/exams/{examId}/questions/{questionId}/override")
    public EducationDtos.TeacherExamStatusResponse updateQuestionOverride(
            @PathVariable Long examId,
            @PathVariable Long questionId,
            @Valid @RequestBody EducationDtos.UpdateQuestionOverrideRequest request
    ) {
        return teacherEducationService.updateQuestionOverride(examId, questionId, request);
    }

    @GetMapping("/teacher/classes")
    public List<EducationDtos.ClassWithExamCountResponse> listTeacherClasses() {
        return teacherEducationService.listMyClasses();
    }

    @GetMapping("/teacher/dashboard")
    public EducationDtos.TeacherDashboardSummary getTeacherDashboard() {
        return teacherEducationService.getDashboardSummary();
    }

    @GetMapping("/teacher/classes/{classId}/exams")
    public List<EducationDtos.ExamResponse> listClassExams(@PathVariable Long classId) {
        return teacherEducationService.listClassExams(classId);
    }

    @GetMapping("/teacher/classes/{classId}/students")
    public EducationDtos.PagedResponse<EducationDtos.TeacherStudentRosterResponse> listClassStudents(
            @PathVariable Long classId,
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "20") int size,
            @RequestParam(name = "name", required = false) String name
    ) {
        return teacherEducationService.listClassStudents(classId, page, size, name);
    }

    @GetMapping("/student/exams")
    public EducationDtos.PagedResponse<EducationDtos.StudentExamListItem> listStudentExams(
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "20") int size,
            @RequestParam(name = "examStatus", required = false) String examStatus
    ) {
        return studentEducationService.listStudentExams(page, size, examStatus);
    }

    @GetMapping("/student/exams/{examId}/questions")
    public List<EducationDtos.QuestionResponse> getStudentQuestions(@PathVariable Long examId) {
        return studentEducationService.getQuestionsForStudent(examId);
    }

    @GetMapping("/student/dashboard")
    public EducationDtos.StudentDashboardSummary getStudentDashboard() {
        return studentEducationService.getStudentDashboardSummary();
    }

    @GetMapping("/parent/students/{studentId}/exams")
    public EducationDtos.PagedResponse<EducationDtos.StudentExamListItem> listParentStudentExams(
            @PathVariable Long studentId,
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "20") int size,
            @RequestParam(name = "examStatus", required = false) String examStatus
    ) {
        return studentEducationService.listStudentExamsForParent(studentId, page, size, examStatus);
    }

    @GetMapping("/parent/students/{studentId}/exams/{examId}/questions")
    public List<EducationDtos.QuestionResponse> getParentQuestions(@PathVariable Long studentId, @PathVariable Long examId) {
        return studentEducationService.getQuestionsForParent(studentId, examId);
    }

    @GetMapping("/parent/dashboard")
    public EducationDtos.ParentDashboardSummary getParentDashboard() {
        return studentEducationService.getParentDashboardSummary();
    }
}
