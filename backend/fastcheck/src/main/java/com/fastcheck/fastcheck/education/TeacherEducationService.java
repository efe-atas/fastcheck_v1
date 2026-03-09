package com.fastcheck.fastcheck.education;

import com.fastcheck.fastcheck.common.ApiException;
import com.fastcheck.fastcheck.ocr.OcrJobRepository;
import com.fastcheck.fastcheck.user.Role;
import com.fastcheck.fastcheck.user.UserAccount;
import com.fastcheck.fastcheck.user.UserRepository;
import java.time.Instant;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

@Service
public class TeacherEducationService {

    private final EducationAccessService accessService;
    private final SchoolRepository schoolRepository;
    private final SchoolClassRepository schoolClassRepository;
    private final ExamRepository examRepository;
    private final ExamImageRepository examImageRepository;
    private final UserRepository userRepository;
    private final ExamFileStorageService fileStorageService;
    private final ExamOcrQueueService examOcrQueueService;
    private final PasswordEncoder passwordEncoder;
    private final OcrJobRepository ocrJobRepository;

    public TeacherEducationService(
            EducationAccessService accessService,
            SchoolRepository schoolRepository,
            SchoolClassRepository schoolClassRepository,
            ExamRepository examRepository,
            ExamImageRepository examImageRepository,
            UserRepository userRepository,
            ExamFileStorageService fileStorageService,
            ExamOcrQueueService examOcrQueueService,
            PasswordEncoder passwordEncoder,
            OcrJobRepository ocrJobRepository
    ) {
        this.accessService = accessService;
        this.schoolRepository = schoolRepository;
        this.schoolClassRepository = schoolClassRepository;
        this.examRepository = examRepository;
        this.examImageRepository = examImageRepository;
        this.userRepository = userRepository;
        this.fileStorageService = fileStorageService;
        this.examOcrQueueService = examOcrQueueService;
        this.passwordEncoder = passwordEncoder;
        this.ocrJobRepository = ocrJobRepository;
    }

    @Transactional
    public EducationDtos.ClassResponse createClass(EducationDtos.CreateClassRequest request) {
        UserAccount teacher = accessService.requireRole(Role.ROLE_TEACHER);

        School school = schoolRepository.findById(request.schoolId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "school not found"));

        if (teacher.getSchool() == null || !teacher.getSchool().getId().equals(school.getId())) {
            throw new ApiException(HttpStatus.FORBIDDEN, "teacher can only create class in own school");
        }

        SchoolClass schoolClass = new SchoolClass();
        schoolClass.setSchool(school);
        schoolClass.setTeacher(teacher);
        schoolClass.setName(request.className().trim());
        schoolClass = schoolClassRepository.save(schoolClass);

        return new EducationDtos.ClassResponse(
                schoolClass.getId(),
                school.getId(),
                teacher.getId(),
                schoolClass.getName(),
                schoolClass.getCreatedAt()
        );
    }

    @Transactional
    public EducationDtos.StudentResponse createStudent(Long classId, EducationDtos.CreateStudentRequest request) {
        UserAccount teacher = accessService.requireRole(Role.ROLE_TEACHER);
        SchoolClass schoolClass = getTeacherClassOrThrow(classId, teacher.getId());

        String fullName = request.fullName().trim();
        if (fullName.isEmpty()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "fullName cannot be empty");
        }

        String email = request.email();
        if (email == null || email.isBlank()) {
            String slug = fullName.toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9]+", ".").replaceAll("(^\\.|\\.$)", "");
            email = slug + "." + UUID.randomUUID().toString().substring(0, 8) + "@fastcheck.local";
        }
        email = email.trim().toLowerCase(Locale.ROOT);

        if (userRepository.existsByEmail(email)) {
            throw new ApiException(HttpStatus.CONFLICT, "email already exists");
        }

        String password = request.password();
        boolean generatedPassword = false;
        if (password == null || password.isBlank()) {
            password = "Temp#" + UUID.randomUUID().toString().substring(0, 8);
            generatedPassword = true;
        }

        UserAccount student = new UserAccount();
        student.setFullName(fullName);
        student.setEmail(email);
        student.setPasswordHash(passwordEncoder.encode(password));
        student.setRole(Role.ROLE_STUDENT);
        student.setSchool(schoolClass.getSchool());
        student.setSchoolClass(schoolClass);
        student.setUpdatedAt(Instant.now());
        student = userRepository.save(student);

        return new EducationDtos.StudentResponse(
                student.getId(),
                student.getFullName(),
                student.getEmail(),
                student.getRole().name(),
                schoolClass.getId(),
                generatedPassword ? password : null
        );
    }

    @Transactional
    public EducationDtos.ExamResponse createExam(Long classId, EducationDtos.CreateExamRequest request) {
        UserAccount teacher = accessService.requireRole(Role.ROLE_TEACHER);
        SchoolClass schoolClass = getTeacherClassOrThrow(classId, teacher.getId());

        Exam exam = new Exam();
        exam.setSchoolClass(schoolClass);
        exam.setTeacher(teacher);
        exam.setTitle(request.title().trim());
        exam.setStatus(ExamStatus.DRAFT);
        exam = examRepository.save(exam);

        return toExamResponse(exam);
    }

    @Transactional
    public EducationDtos.UploadExamImagesResponse uploadExamImages(Long examId, List<MultipartFile> images) {
        UserAccount teacher = accessService.requireRole(Role.ROLE_TEACHER);
        Exam exam = examRepository.findById(examId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "exam not found"));
        if (!exam.getTeacher().getId().equals(teacher.getId())) {
            throw new ApiException(HttpStatus.FORBIDDEN, "forbidden");
        }
        if (images == null || images.isEmpty()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "at least one image is required");
        }

        int startOrder = examImageRepository.findTopByExam_IdOrderByPageOrderDesc(examId)
                .map(existing -> existing.getPageOrder() + 1)
                .orElse(1);

        int order = startOrder;
        for (MultipartFile file : images) {
            ExamImage image = new ExamImage();
            image.setExam(exam);
            image.setPageOrder(order++);
            image.setImageUrl(fileStorageService.save(file));
            image.setStatus(ExamImageStatus.PENDING);
            examImageRepository.save(image);
        }

        exam.setStatus(ExamStatus.PROCESSING);
        examRepository.save(exam);
        examOcrQueueService.enqueueExam(examId);

        List<EducationDtos.ExamImageResponse> payload = examImageRepository.findByExam_IdOrderByPageOrderAsc(examId)
                .stream()
                .map(this::toExamImageResponse)
                .toList();
        return new EducationDtos.UploadExamImagesResponse(examId, exam.getStatus().name(), payload);
    }

    @Transactional(readOnly = true)
    public EducationDtos.TeacherExamStatusResponse getExamStatus(Long examId) {
        UserAccount teacher = accessService.requireRole(Role.ROLE_TEACHER);
        Exam exam = examRepository.findByIdAndTeacher_Id(examId, teacher.getId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "exam not found"));

        List<EducationDtos.ExamImageResponse> images = examImageRepository.findByExam_IdOrderByPageOrderAsc(examId)
                .stream()
                .map(this::toExamImageResponse)
                .toList();

        List<EducationDtos.OcrJobStatusResponse> jobs = ocrJobRepository.findByExamImage_Exam_IdOrderByCreatedAtAsc(examId)
                .stream()
                .map(job -> new EducationDtos.OcrJobStatusResponse(
                        job.getJobId(),
                        job.getRequestId(),
                        job.getStatus().name(),
                        job.getRetryCount(),
                        job.getErrorMessage(),
                        job.getCreatedAt()
                ))
                .toList();

        return new EducationDtos.TeacherExamStatusResponse(
                exam.getId(),
                exam.getSchoolClass().getId(),
                exam.getTitle(),
                exam.getStatus().name(),
                images,
                jobs
        );
    }

    @Transactional(readOnly = true)
    public List<EducationDtos.ClassWithExamCountResponse> listMyClasses() {
        UserAccount teacher = accessService.requireRole(Role.ROLE_TEACHER);
        return schoolClassRepository.findByTeacher_Id(teacher.getId())
                .stream()
                .map(this::toClassListItem)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<EducationDtos.ExamResponse> listClassExams(Long classId) {
        UserAccount teacher = accessService.requireRole(Role.ROLE_TEACHER);
        SchoolClass schoolClass = getTeacherClassOrThrow(classId, teacher.getId());
        return examRepository.findBySchoolClass_IdOrderByCreatedAtDesc(schoolClass.getId())
                .stream()
                .map(this::toExamResponse)
                .toList();
    }

        @Transactional(readOnly = true)
            public EducationDtos.PagedResponse<EducationDtos.TeacherStudentRosterResponse> listClassStudents(
                Long classId,
                int page,
                int size,
                String name
            ) {
        UserAccount teacher = accessService.requireRole(Role.ROLE_TEACHER);
        SchoolClass schoolClass = getTeacherClassOrThrow(classId, teacher.getId());
            Pageable pageable = PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), 100));
            String query = name == null ? "" : name.trim();

            Page<UserAccount> roster = userRepository
                .findBySchoolClass_IdAndRoleAndFullNameContainingIgnoreCaseOrderByFullNameAsc(
                    schoolClass.getId(),
                    Role.ROLE_STUDENT,
                    query,
                    pageable
                );

            List<EducationDtos.TeacherStudentRosterResponse> items = roster.getContent()
            .stream()
            .map(student -> new EducationDtos.TeacherStudentRosterResponse(
                    student.getId(),
                    student.getFullName(),
                    student.getEmail(),
                    schoolClass.getId()
                ))
                .toList();

            return new EducationDtos.PagedResponse<>(
                items,
                roster.getNumber(),
                roster.getSize(),
                roster.getTotalElements(),
                roster.getTotalPages()
            );
            }

    private SchoolClass getTeacherClassOrThrow(Long classId, Long teacherId) {
        SchoolClass schoolClass = schoolClassRepository.findById(classId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "class not found"));
        if (!schoolClass.getTeacher().getId().equals(teacherId)) {
            throw new ApiException(HttpStatus.FORBIDDEN, "teacher can only manage own classes");
        }
        return schoolClass;
    }

    private EducationDtos.ExamResponse toExamResponse(Exam exam) {
        return new EducationDtos.ExamResponse(
                exam.getId(),
                exam.getSchoolClass().getId(),
                exam.getTitle(),
                exam.getStatus().name(),
                exam.getCreatedAt()
        );
    }

    private EducationDtos.ExamImageResponse toExamImageResponse(ExamImage image) {
        return new EducationDtos.ExamImageResponse(
                image.getId(),
                image.getPageOrder(),
                image.getImageUrl(),
                image.getStatus().name(),
                image.getErrorMessage()
        );
    }

    private EducationDtos.ClassWithExamCountResponse toClassListItem(SchoolClass schoolClass) {
        long examCount = examRepository.countBySchoolClass_Id(schoolClass.getId());
        return new EducationDtos.ClassWithExamCountResponse(
                schoolClass.getId(),
                schoolClass.getSchool().getId(),
                schoolClass.getName(),
                examCount,
                schoolClass.getCreatedAt()
        );
    }
}
