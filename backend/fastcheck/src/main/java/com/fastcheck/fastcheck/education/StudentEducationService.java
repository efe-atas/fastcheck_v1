package com.fastcheck.fastcheck.education;

import com.fastcheck.fastcheck.common.ApiException;
import com.fastcheck.fastcheck.user.Role;
import com.fastcheck.fastcheck.user.UserAccount;
import com.fastcheck.fastcheck.user.UserRepository;
import java.util.List;
import java.util.Locale;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class StudentEducationService {

    private final EducationAccessService accessService;
    private final ExamRepository examRepository;
    private final QuestionRepository questionRepository;
    private final ParentStudentLinkRepository parentStudentLinkRepository;
    private final UserRepository userRepository;

    public StudentEducationService(
            EducationAccessService accessService,
            ExamRepository examRepository,
            QuestionRepository questionRepository,
            ParentStudentLinkRepository parentStudentLinkRepository,
            UserRepository userRepository
    ) {
        this.accessService = accessService;
        this.examRepository = examRepository;
        this.questionRepository = questionRepository;
        this.parentStudentLinkRepository = parentStudentLinkRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public List<EducationDtos.QuestionResponse> getQuestionsForStudent(Long examId) {
        UserAccount student = accessService.requireRole(Role.ROLE_STUDENT);
        Exam exam = examRepository.findById(examId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "exam not found"));

        if (student.getSchoolClass() == null || !exam.getSchoolClass().getId().equals(student.getSchoolClass().getId())) {
            throw new ApiException(HttpStatus.FORBIDDEN, "forbidden");
        }

        return mapQuestions(examId);
    }

    @Transactional(readOnly = true)
    public EducationDtos.PagedResponse<EducationDtos.StudentExamListItem> listStudentExams(
            int page,
            int size,
            String examStatus
    ) {
        UserAccount student = accessService.requireRole(Role.ROLE_STUDENT);
        Pageable pageable = PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), 100));
        if (student.getSchoolClass() == null) {
            return new EducationDtos.PagedResponse<>(List.of(), pageable.getPageNumber(), pageable.getPageSize(), 0, 0);
        }

        Page<Exam> exams;
        if (examStatus == null || examStatus.isBlank()) {
            exams = examRepository.findBySchoolClass_IdOrderByCreatedAtDesc(student.getSchoolClass().getId(), pageable);
        } else {
            ExamStatus parsedStatus;
            try {
                parsedStatus = ExamStatus.valueOf(examStatus.trim().toUpperCase(Locale.ROOT));
            } catch (IllegalArgumentException exc) {
                throw new ApiException(HttpStatus.BAD_REQUEST, "invalid examStatus value");
            }
            exams = examRepository.findBySchoolClass_IdAndStatusOrderByCreatedAtDesc(
                    student.getSchoolClass().getId(),
                    parsedStatus,
                    pageable
            );
        }

        List<EducationDtos.StudentExamListItem> items = exams.getContent()
                .stream()
                .map(exam -> new EducationDtos.StudentExamListItem(
                        exam.getId(),
                        exam.getSchoolClass().getId(),
                        exam.getTitle(),
                        exam.getStatus().name(),
                        exam.getCreatedAt()
                ))
                .toList();

        return new EducationDtos.PagedResponse<>(
                items,
                exams.getNumber(),
                exams.getSize(),
                exams.getTotalElements(),
                exams.getTotalPages()
        );
    }

    @Transactional(readOnly = true)
    public EducationDtos.StudentDashboardSummary getStudentDashboardSummary() {
        UserAccount student = accessService.requireRole(Role.ROLE_STUDENT);
        if (student.getSchoolClass() == null) {
            return new EducationDtos.StudentDashboardSummary(0, 0, 0, 0, List.of());
        }
        Long classId = student.getSchoolClass().getId();
        long total = examRepository.countBySchoolClass_Id(classId);
        long ready = examRepository.countBySchoolClass_IdAndStatus(classId, ExamStatus.READY);
        long processing = examRepository.countBySchoolClass_IdAndStatus(classId, ExamStatus.PROCESSING);
        long draft = examRepository.countBySchoolClass_IdAndStatus(classId, ExamStatus.DRAFT);

        List<EducationDtos.StudentExamListItem> latest = examRepository
                .findTop5BySchoolClass_IdOrderByCreatedAtDesc(classId)
                .stream()
                .map(this::toStudentExamList)
                .toList();

        return new EducationDtos.StudentDashboardSummary(
                total,
                ready,
                processing,
                draft,
                latest
        );
    }

    @Transactional(readOnly = true)
    public EducationDtos.ParentDashboardSummary getParentDashboardSummary() {
        UserAccount parent = accessService.requireRole(Role.ROLE_PARENT);
        List<EducationDtos.ParentStudentSummary> summaries = parentStudentLinkRepository
                .findByParent_IdOrderByCreatedAtDesc(parent.getId())
                .stream()
                .map(link -> buildParentStudentSummary(link.getStudent()))
                .toList();
        return new EducationDtos.ParentDashboardSummary(summaries.size(), summaries);
    }

    @Transactional(readOnly = true)
    public List<EducationDtos.QuestionResponse> getQuestionsForParent(Long studentId, Long examId) {
        UserAccount parent = accessService.requireRole(Role.ROLE_PARENT);
        boolean linked = parentStudentLinkRepository.findByParent_Id(parent.getId())
                .stream()
                .anyMatch(link -> link.getStudent().getId().equals(studentId));
        if (!linked) {
            throw new ApiException(HttpStatus.FORBIDDEN, "forbidden");
        }

        Exam exam = examRepository.findById(examId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "exam not found"));
        UserAccount student = userRepository.findById(studentId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "student not found"));
        if (student.getRole() != Role.ROLE_STUDENT || student.getSchoolClass() == null
            || !exam.getSchoolClass().getId().equals(student.getSchoolClass().getId())) {
            throw new ApiException(HttpStatus.FORBIDDEN, "forbidden");
        }

        return mapQuestions(examId);
    }

    private List<EducationDtos.QuestionResponse> mapQuestions(Long examId) {
        return questionRepository.findByExam_IdOrderByPageNumberAscQuestionOrderAsc(examId)
                .stream()
                .map(q -> new EducationDtos.QuestionResponse(
                        q.getId(),
                        q.getPageNumber(),
                        q.getQuestionOrder(),
                        q.getSourceQuestionId(),
                        q.getQuestionTextRaw(),
                        q.getStudentAnswerRaw(),
                        q.getConfidence()
                ))
                .toList();
    }

    private EducationDtos.StudentExamListItem toStudentExamList(Exam exam) {
        return new EducationDtos.StudentExamListItem(
                exam.getId(),
                exam.getSchoolClass().getId(),
                exam.getTitle(),
                exam.getStatus().name(),
                exam.getCreatedAt()
        );
    }

    private EducationDtos.ParentStudentSummary buildParentStudentSummary(UserAccount student) {
        Long classId = student.getSchoolClass() == null ? null : student.getSchoolClass().getId();
        long total = classId == null ? 0 : examRepository.countBySchoolClass_Id(classId);
        long ready = classId == null ? 0 : examRepository.countBySchoolClass_IdAndStatus(classId, ExamStatus.READY);
        Exam latest = classId == null
                ? null
                : examRepository.findTop1BySchoolClass_IdOrderByCreatedAtDesc(classId).orElse(null);
        return new EducationDtos.ParentStudentSummary(
                student.getId(),
                student.getFullName(),
                student.getEmail(),
                classId,
                total,
                ready,
                latest == null ? null : latest.getTitle(),
                latest == null ? null : latest.getStatus().name(),
                latest == null ? null : latest.getCreatedAt()
        );
    }
}
