package com.fastcheck.fastcheck.education;

import com.fastcheck.fastcheck.common.ApiException;
import com.fastcheck.fastcheck.ocr.OcrJob;
import com.fastcheck.fastcheck.ocr.OcrJobRepository;
import com.fastcheck.fastcheck.user.Role;
import com.fastcheck.fastcheck.user.UserAccount;
import com.fastcheck.fastcheck.user.UserRepository;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.web.multipart.MultipartFile;

@Service
public class TeacherEducationService {

    private final EducationAccessService accessService;
    private final SchoolClassRepository schoolClassRepository;
    private final ExamRepository examRepository;
    private final ExamImageRepository examImageRepository;
    private final UserRepository userRepository;
    private final ExamFileStorageService fileStorageService;
    private final ExamOcrQueueService examOcrQueueService;
    private final PasswordEncoder passwordEncoder;
    private final OcrJobRepository ocrJobRepository;
    private final QuestionRepository questionRepository;
    private final StudentExamResultRepository studentExamResultRepository;
    private final ExamGradingService examGradingService;

    public TeacherEducationService(
            EducationAccessService accessService,
            SchoolClassRepository schoolClassRepository,
            ExamRepository examRepository,
            ExamImageRepository examImageRepository,
            UserRepository userRepository,
            ExamFileStorageService fileStorageService,
            ExamOcrQueueService examOcrQueueService,
            PasswordEncoder passwordEncoder,
            OcrJobRepository ocrJobRepository,
            QuestionRepository questionRepository,
            StudentExamResultRepository studentExamResultRepository,
            ExamGradingService examGradingService
    ) {
        this.accessService = accessService;
        this.schoolClassRepository = schoolClassRepository;
        this.examRepository = examRepository;
        this.examImageRepository = examImageRepository;
        this.userRepository = userRepository;
        this.fileStorageService = fileStorageService;
        this.examOcrQueueService = examOcrQueueService;
        this.passwordEncoder = passwordEncoder;
        this.ocrJobRepository = ocrJobRepository;
        this.questionRepository = questionRepository;
        this.studentExamResultRepository = studentExamResultRepository;
        this.examGradingService = examGradingService;
    }

    @Transactional
    public EducationDtos.ClassResponse createClass(EducationDtos.CreateClassRequest request) {
        UserAccount teacher = accessService.requireRole(Role.ROLE_TEACHER);

        School school = teacher.getSchool();
        if (school == null) {
            throw new ApiException(HttpStatus.CONFLICT, "teacher must be assigned to a school");
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
            if (file == null || file.isEmpty()) {
                throw new ApiException(HttpStatus.BAD_REQUEST, "image file is required");
            }
            String contentType = file.getContentType();
            if (contentType != null && !contentType.toLowerCase().startsWith("image/")) {
                throw new ApiException(HttpStatus.BAD_REQUEST, "only image content types are accepted");
            }
            ExamImage image = new ExamImage();
            image.setExam(exam);
            image.setPageOrder(order++);
            image.setImageUrl(fileStorageService.save(file));
            image.setStatus(ExamImageStatus.PENDING);
            examImageRepository.save(image);
        }

        exam.setStatus(ExamStatus.PROCESSING);
        examRepository.save(exam);
        enqueueExamAfterCommit(examId);

        List<EducationDtos.ExamImageResponse> payload = examImageRepository.findByExam_IdOrderByPageOrderAsc(examId)
                .stream()
                .map(image -> toExamImageResponse(image, Map.of()))
                .toList();
        return new EducationDtos.UploadExamImagesResponse(examId, exam.getStatus().name(), payload);
    }

    @Transactional(readOnly = true)
    public EducationDtos.TeacherExamStatusResponse getExamStatus(Long examId) {
        UserAccount teacher = accessService.requireRole(Role.ROLE_TEACHER);
        Exam exam = examRepository.findByIdAndTeacher_Id(examId, teacher.getId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "exam not found"));

        List<UserAccount> students = userRepository.findBySchoolClass_IdAndRoleOrderByFullNameAsc(
                exam.getSchoolClass().getId(),
                Role.ROLE_STUDENT
        );
        Map<Long, UserAccount> studentLookup = students.stream()
                .collect(java.util.stream.Collectors.toMap(UserAccount::getId, Function.identity()));

        List<ExamImage> examImages = examImageRepository.findByExam_IdOrderByPageOrderAsc(examId);
        List<EducationDtos.ExamImageResponse> images = examImages
                .stream()
                .map(image -> toExamImageResponse(image, studentLookup))
                .toList();

        List<EducationDtos.OcrJobStatusResponse> jobs = ocrJobRepository.findByExamImage_Exam_IdOrderByCreatedAtAsc(examId)
                .stream()
                .map(this::toOcrJobStatusResponse)
                .toList();

        List<Question> questionEntities = questionRepository
                .findByExam_IdOrderByPageNumberAscQuestionOrderAsc(examId);
        List<EducationDtos.QuestionResponse> questions = questionEntities
                .stream()
                .map(this::toQuestionResponse)
                .toList();

        List<StudentExamResult> studentResultEntities = studentExamResultRepository
                .findByExam_IdOrderByAwardedPointsDescStudentNameAsc(examId);
        List<EducationDtos.StudentExamResultResponse> studentResults = studentResultEntities
                .stream()
                .map(this::toStudentExamResultResponse)
                .toList();
        List<EducationDtos.TeacherStudentClusterResponse> studentClusters = buildStudentClusters(
                students,
                images,
                questions,
                studentResults
        );

        return new EducationDtos.TeacherExamStatusResponse(
                exam.getId(),
                exam.getSchoolClass().getId(),
                exam.getTitle(),
                exam.getStatus().name(),
                exam.getGradingSystemSummary(),
                exam.getTotalMaxPoints(),
                images,
                students.stream().map(this::toStudentRosterResponse).toList(),
                jobs,
                questions.size(),
                questions,
                studentClusters,
                studentResults
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
    public EducationDtos.TeacherDashboardSummary getDashboardSummary() {
        UserAccount teacher = accessService.requireRole(Role.ROLE_TEACHER);
        Long teacherId = teacher.getId();
        List<SchoolClass> classes = schoolClassRepository.findByTeacher_Id(teacherId);
        long totalExams = examRepository.countByTeacher_Id(teacherId);
        long processing = examRepository.countByTeacher_IdAndStatus(teacherId, ExamStatus.PROCESSING);
        long ready = examRepository.countByTeacher_IdAndStatus(teacherId, ExamStatus.READY);
        List<EducationDtos.ExamResponse> latestExams = examRepository.findTop5ByTeacher_IdOrderByCreatedAtDesc(teacherId)
                .stream()
                .map(this::toExamResponse)
                .toList();
        List<EducationDtos.OcrJobStatusResponse> recentJobs = ocrJobRepository.findTop5ByUser_IdOrderByCreatedAtDesc(teacherId)
                .stream()
                .map(this::toOcrJobStatusResponse)
                .toList();
        return new EducationDtos.TeacherDashboardSummary(
                classes.size(),
                totalExams,
                processing,
                ready,
                latestExams,
                recentJobs
        );
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

    @Transactional
    public EducationDtos.TeacherExamStatusResponse reprocessExam(Long examId) {
        UserAccount teacher = accessService.requireRole(Role.ROLE_TEACHER);
        Exam exam = examRepository.findByIdAndTeacher_Id(examId, teacher.getId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "exam not found"));

        List<ExamImage> images = examImageRepository.findByExam_IdOrderByPageOrderAsc(examId);
        if (images.isEmpty()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "no images to reprocess");
        }

        // Reprocess explicitly restarts the full exam so every page is regenerated.
        for (ExamImage image : images) {
            image.setStatus(ExamImageStatus.PENDING);
            image.setErrorMessage(null);
            image.setProcessingStartedAt(null);
            image.setProcessingCompletedAt(null);
            if (image.getStudentMatchStatus() != StudentMatchStatus.MANUAL) {
                image.setDetectedStudentName(null);
                image.setDetectedStudentNameConfidence(null);
                image.setMatchedStudentId(null);
                image.setMatchedStudentName(null);
                image.setStudentMatchConfidence(null);
                image.setStudentMatchStatus(null);
                image.setCandidateStudentIds(null);
            }
            examImageRepository.save(image);
        }

        // Clear previous questions and re-enqueue every page via PENDING status.
        questionRepository.deleteByExam_Id(examId);
        studentExamResultRepository.deleteByExam_Id(examId);
        exam.setGradingSystemSummary(null);
        exam.setTotalMaxPoints(null);
        exam.setStatus(ExamStatus.PROCESSING);
        examRepository.save(exam);
        enqueueExamAfterCommit(examId);

        return getExamStatus(examId);
    }

    @Transactional
    public EducationDtos.TeacherExamStatusResponse updateExamImageStudentMatch(
            Long examId,
            Long imageId,
            EducationDtos.UpdateExamImageStudentMatchRequest request
    ) {
        UserAccount teacher = accessService.requireRole(Role.ROLE_TEACHER);
        Exam exam = examRepository.findByIdAndTeacher_Id(examId, teacher.getId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "exam not found"));
        ExamImage image = examImageRepository.findByIdAndExam_Id(imageId, examId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "exam image not found"));
        UserAccount student = userRepository.findByIdAndSchoolClass_IdAndRole(
                        request.studentId(),
                        exam.getSchoolClass().getId(),
                        Role.ROLE_STUDENT
                )
                .orElseThrow(() -> new ApiException(HttpStatus.BAD_REQUEST, "student not found in class"));

        image.setMatchedStudentId(student.getId());
        image.setMatchedStudentName(student.getFullName());
        image.setStudentMatchStatus(StudentMatchStatus.MANUAL);
        image.setStudentMatchConfidence(1.0);
        if (image.getCandidateStudentIds() == null || image.getCandidateStudentIds().isBlank()) {
            image.setCandidateStudentIds(String.valueOf(student.getId()));
        }
        examImageRepository.save(image);
        examGradingService.recomputeStudentResults(exam);

        return getExamStatus(examId);
    }

    @Transactional
    public EducationDtos.TeacherExamStatusResponse updateQuestionOverride(
            Long examId,
            Long questionId,
            EducationDtos.UpdateQuestionOverrideRequest request
    ) {
        UserAccount teacher = accessService.requireRole(Role.ROLE_TEACHER);
        Exam exam = examRepository.findByIdAndTeacher_Id(examId, teacher.getId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "exam not found"));
        Question question = questionRepository.findByIdAndExam_Id(questionId, examId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "question not found"));

        double maxPoints = sanitizeScore(request.maxPoints());
        double awardedPoints = sanitizeScore(Math.min(request.awardedPoints(), maxPoints));

        question.setMaxPoints(maxPoints);
        question.setAwardedPoints(awardedPoints);
        question.setExpectedAnswerRaw(trimToNull(request.expectedAnswer()));
        question.setGradingRubricRaw(trimToNull(request.gradingRubric()));
        question.setEvaluationSummary(trimToNull(request.evaluationSummary()));
        question.setCorrect(resolveCorrectFlag(request.correct(), awardedPoints, maxPoints));
        question.setGradingConfidence(1.0);
        question.setGradingStatus(GradingStatus.OVERRIDDEN);
        questionRepository.save(question);

        examGradingService.recomputeStudentResults(exam);
        return getExamStatus(examId);
    }

    private SchoolClass getTeacherClassOrThrow(Long classId, Long teacherId) {
        SchoolClass schoolClass = schoolClassRepository.findById(classId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "class not found"));
        if (!schoolClass.getTeacher().getId().equals(teacherId)) {
            throw new ApiException(HttpStatus.FORBIDDEN, "teacher can only manage own classes");
        }
        return schoolClass;
    }

    private void enqueueExamAfterCommit(Long examId) {
        if (!TransactionSynchronizationManager.isSynchronizationActive()) {
            examOcrQueueService.enqueueExam(examId);
            return;
        }

        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                examOcrQueueService.enqueueExam(examId);
            }
        });
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

    private EducationDtos.ExamImageResponse toExamImageResponse(ExamImage image, Map<Long, UserAccount> studentLookup) {
        return new EducationDtos.ExamImageResponse(
                image.getId(),
                image.getPageOrder(),
                image.getImageUrl(),
                image.getStatus().name(),
                image.getErrorMessage(),
                image.getProcessingStartedAt(),
                image.getProcessingCompletedAt(),
                toStudentMatchResponse(image, studentLookup)
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

    private EducationDtos.OcrJobStatusResponse toOcrJobStatusResponse(OcrJob job) {
        return new EducationDtos.OcrJobStatusResponse(
                job.getJobId(),
                job.getRequestId(),
                job.getStatus().name(),
                job.getRetryCount(),
                job.getErrorMessage(),
                job.getCreatedAt()
        );
    }

    private EducationDtos.QuestionResponse toQuestionResponse(Question question) {
        ExamImage image = question.getExamImage();
        return new EducationDtos.QuestionResponse(
                question.getId(),
                question.getPageNumber(),
                question.getQuestionOrder(),
                question.getSourceQuestionId(),
                question.getQuestionTextRaw(),
                question.getStudentAnswerRaw(),
                question.getConfidence(),
                question.getQuestionType().name(),
                question.getExpectedAnswerRaw(),
                question.getGradingRubricRaw(),
                question.getMaxPoints(),
                question.getAwardedPoints(),
                question.getGradingConfidence(),
                question.getGradingStatus().name(),
                question.getEvaluationSummary(),
                question.getCorrect(),
                image == null ? null : image.getMatchedStudentId(),
                image == null ? null : image.getMatchedStudentName(),
                image == null || image.getStudentMatchStatus() == null ? null : image.getStudentMatchStatus().name()
        );
    }

    private EducationDtos.StudentExamResultResponse toStudentExamResultResponse(StudentExamResult result) {
        double percentage = calculateScorePercentage(result.getAwardedPoints(), result.getMaxPoints());
        return new EducationDtos.StudentExamResultResponse(
                result.getStudentId(),
                result.getStudentName(),
                result.getTotalQuestions(),
                result.getScoredQuestions(),
                result.getAwardedPoints(),
                result.getMaxPoints(),
                result.getGradingConfidence(),
                result.getGradingStatus().name(),
                result.getGradingSummary(),
                percentage
        );
    }

    private List<EducationDtos.TeacherStudentClusterResponse> buildStudentClusters(
            List<UserAccount> students,
            List<EducationDtos.ExamImageResponse> images,
            List<EducationDtos.QuestionResponse> questions,
            List<EducationDtos.StudentExamResultResponse> studentResults
    ) {
        Map<Long, List<EducationDtos.ExamImageResponse>> imagesByStudentId = new HashMap<>();
        List<EducationDtos.ExamImageResponse> unmatchedImages = new ArrayList<>();
        for (EducationDtos.ExamImageResponse image : images) {
            Long studentId = image.studentMatch() == null ? null : image.studentMatch().matchedStudentId();
            if (studentId == null) {
                unmatchedImages.add(image);
                continue;
            }
            imagesByStudentId.computeIfAbsent(studentId, ignored -> new ArrayList<>()).add(image);
        }

        Map<Long, List<EducationDtos.QuestionResponse>> questionsByStudentId = new HashMap<>();
        List<EducationDtos.QuestionResponse> unmatchedQuestions = new ArrayList<>();
        for (EducationDtos.QuestionResponse question : questions) {
            if (question.studentId() == null) {
                unmatchedQuestions.add(question);
                continue;
            }
            questionsByStudentId.computeIfAbsent(question.studentId(), ignored -> new ArrayList<>()).add(question);
        }

        Map<Long, EducationDtos.StudentExamResultResponse> resultsByStudentId = studentResults.stream()
                .collect(java.util.stream.Collectors.toMap(
                        EducationDtos.StudentExamResultResponse::studentId,
                        Function.identity(),
                        (left, right) -> left
                ));

        List<EducationDtos.TeacherStudentClusterResponse> clusters = new ArrayList<>();
        if (!unmatchedImages.isEmpty() || !unmatchedQuestions.isEmpty()) {
            clusters.add(buildStudentCluster(
                    null,
                    "Atanmamis Kagitlar",
                    null,
                    true,
                    resolveMatchingStatus(unmatchedImages, true),
                    unmatchedImages,
                    unmatchedQuestions,
                    null
            ));
        }

        for (UserAccount student : students) {
            List<EducationDtos.ExamImageResponse> studentImages = imagesByStudentId.getOrDefault(student.getId(), List.of());
            List<EducationDtos.QuestionResponse> studentQuestions = questionsByStudentId.getOrDefault(student.getId(), List.of());
            EducationDtos.StudentExamResultResponse result = resultsByStudentId.get(student.getId());
            if (studentImages.isEmpty() && studentQuestions.isEmpty() && result == null) {
                continue;
            }
            clusters.add(buildStudentCluster(
                    student.getId(),
                    student.getFullName(),
                    student.getEmail(),
                    false,
                    resolveMatchingStatus(studentImages, false),
                    studentImages,
                    studentQuestions,
                    result
            ));
        }

        resultsByStudentId.forEach((studentId, result) -> {
            boolean missingCluster = clusters.stream()
                    .noneMatch(cluster -> !cluster.unmatched() && studentId.equals(cluster.studentId()));
            if (!missingCluster) {
                return;
            }
            clusters.add(buildStudentCluster(
                    studentId,
                    result.studentName(),
                    null,
                    false,
                    resolveMatchingStatus(imagesByStudentId.getOrDefault(studentId, List.of()), false),
                    imagesByStudentId.getOrDefault(studentId, List.of()),
                    questionsByStudentId.getOrDefault(studentId, List.of()),
                    result
            ));
        });

        List<EducationDtos.TeacherStudentClusterResponse> matchedClusters = clusters.stream()
                .filter(cluster -> !cluster.unmatched())
                .sorted(Comparator.comparing(
                        EducationDtos.TeacherStudentClusterResponse::studentName,
                        String.CASE_INSENSITIVE_ORDER
                ))
                .toList();
        List<EducationDtos.TeacherStudentClusterResponse> unmatchedClusters = clusters.stream()
                .filter(EducationDtos.TeacherStudentClusterResponse::unmatched)
                .toList();

        List<EducationDtos.TeacherStudentClusterResponse> orderedClusters = new ArrayList<>(unmatchedClusters);
        orderedClusters.addAll(matchedClusters);
        return orderedClusters;
    }

    private EducationDtos.TeacherStudentClusterResponse buildStudentCluster(
            Long studentId,
            String studentName,
            String studentEmail,
            boolean unmatched,
            String matchingStatus,
            List<EducationDtos.ExamImageResponse> images,
            List<EducationDtos.QuestionResponse> questions,
            EducationDtos.StudentExamResultResponse result
    ) {
        double awardedPoints = result == null
                ? questions.stream()
                        .map(EducationDtos.QuestionResponse::awardedPoints)
                        .filter(java.util.Objects::nonNull)
                        .mapToDouble(Double::doubleValue)
                        .sum()
                : result.awardedPoints();
        double maxPoints = result == null
                ? questions.stream()
                        .map(EducationDtos.QuestionResponse::maxPoints)
                        .filter(java.util.Objects::nonNull)
                        .mapToDouble(Double::doubleValue)
                        .sum()
                : result.maxPoints();

        return new EducationDtos.TeacherStudentClusterResponse(
                studentId,
                studentName,
                studentEmail,
                unmatched,
                matchingStatus,
                images.size(),
                questions.size(),
                awardedPoints,
                maxPoints,
                calculateScorePercentage(awardedPoints, maxPoints),
                result == null ? null : result.gradingStatus(),
                result == null ? null : result.gradingSummary(),
                images,
                questions
        );
    }

    private String resolveMatchingStatus(List<EducationDtos.ExamImageResponse> images, boolean unmatched) {
        if (images.isEmpty()) {
            return unmatched ? StudentMatchStatus.UNMATCHED.name() : null;
        }
        List<String> statuses = images.stream()
                .map(EducationDtos.ExamImageResponse::studentMatch)
                .filter(java.util.Objects::nonNull)
                .map(EducationDtos.StudentMatchResponse::matchingStatus)
                .filter(status -> status != null && !status.isBlank())
                .toList();
        if (statuses.stream().anyMatch(StudentMatchStatus.MANUAL.name()::equalsIgnoreCase)) {
            return StudentMatchStatus.MANUAL.name();
        }
        if (statuses.stream().anyMatch(StudentMatchStatus.AMBIGUOUS.name()::equalsIgnoreCase)) {
            return StudentMatchStatus.AMBIGUOUS.name();
        }
        if (statuses.stream().anyMatch(StudentMatchStatus.UNMATCHED.name()::equalsIgnoreCase)) {
            return StudentMatchStatus.UNMATCHED.name();
        }
        if (statuses.stream().anyMatch(StudentMatchStatus.MATCHED.name()::equalsIgnoreCase)) {
            return StudentMatchStatus.MATCHED.name();
        }
        return unmatched ? StudentMatchStatus.UNMATCHED.name() : null;
    }

    private double calculateScorePercentage(double awardedPoints, double maxPoints) {
        if (maxPoints <= 0) {
            return 0.0;
        }
        return Math.round((awardedPoints / maxPoints) * 10000.0) / 100.0;
    }

    private EducationDtos.TeacherStudentRosterResponse toStudentRosterResponse(UserAccount student) {
        return new EducationDtos.TeacherStudentRosterResponse(
                student.getId(),
                student.getFullName(),
                student.getEmail(),
                student.getSchoolClass() == null ? null : student.getSchoolClass().getId()
        );
    }

    private EducationDtos.StudentMatchResponse toStudentMatchResponse(
            ExamImage image,
            Map<Long, UserAccount> studentLookup
    ) {
        return new EducationDtos.StudentMatchResponse(
                image.getDetectedStudentName(),
                image.getDetectedStudentNameConfidence(),
                image.getMatchedStudentId(),
                image.getMatchedStudentName(),
                image.getStudentMatchConfidence(),
                image.getStudentMatchStatus() == null ? null : image.getStudentMatchStatus().name(),
                image.getCandidateStudentIdList()
                        .stream()
                        .map(studentLookup::get)
                        .filter(java.util.Objects::nonNull)
                        .map(student -> new EducationDtos.StudentMatchCandidateResponse(
                                student.getId(),
                                student.getFullName()
                        ))
                        .toList()
        );
    }

    private double sanitizeScore(Double value) {
        if (value == null || value < 0) {
            return 0.0;
        }
        return Math.round(value * 100.0) / 100.0;
    }

    private String trimToNull(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }

    private Boolean resolveCorrectFlag(Boolean explicit, double awardedPoints, double maxPoints) {
        if (explicit != null) {
            return explicit;
        }
        if (maxPoints <= 0) {
            return null;
        }
        if (awardedPoints == 0.0d) {
            return Boolean.FALSE;
        }
        if (Math.abs(awardedPoints - maxPoints) < 0.0001d) {
            return Boolean.TRUE;
        }
        return null;
    }
}
