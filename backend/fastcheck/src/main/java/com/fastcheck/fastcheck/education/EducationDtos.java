package com.fastcheck.fastcheck.education;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public class EducationDtos {

        public record PagedResponse<T>(
                        List<T> items,
                        int page,
                        int size,
                        long totalElements,
                        int totalPages
        ) {
        }

    public record CreateClassRequest(
            @NotBlank @Size(min = 2, max = 120) String className
    ) {
    }

    public record ClassResponse(
            Long classId,
            Long schoolId,
            Long teacherId,
            String className,
            Instant createdAt
    ) {
    }

    public record CreateStudentRequest(
            @NotBlank @Size(min = 2, max = 255) String fullName,
            String email,
            String password
    ) {
    }

    public record StudentResponse(
            Long userId,
            String fullName,
            String email,
            String role,
            Long classId,
            String initialPassword
    ) {
    }

    public record TeacherStudentRosterResponse(
            Long userId,
            String fullName,
            String email,
            Long classId
    ) {
    }

    public record CreateSchoolRequest(
            @NotBlank @Size(min = 2, max = 255) String schoolName
    ) {
    }

    public record SchoolResponse(
            Long schoolId,
            String schoolName,
            Instant createdAt
    ) {
    }

    public record ParentStudentLinkRequest(
            @NotNull Long parentUserId,
            @NotNull Long studentUserId
    ) {
    }

    public record ParentStudentLinkResponse(
            Long linkId,
            Long parentUserId,
            Long studentUserId,
            Instant createdAt
    ) {
    }

    public record ParentStudentView(
            Long userId,
            String fullName,
            String email,
            Long classId
    ) {
    }

    public record ParentStudentSummary(
            Long studentId,
            String fullName,
            String email,
            Long classId,
            long totalExams,
            long readyExams,
            Long latestExamId,
            String latestExamTitle,
            String latestExamStatus,
            Instant latestExamCreatedAt
    ) {
    }

    public record ParentDashboardSummary(
            long linkedStudents,
            List<ParentStudentSummary> students
    ) {
    }

    public record AdminUserSummary(
            Long userId,
            String fullName,
            String email,
            String role,
            Long schoolId,
            Long classId
    ) {
    }

    public record AdminSchoolSummary(
            Long schoolId,
            String schoolName,
            Instant createdAt
    ) {
    }

    public record BulkRowError(
            int rowNumber,
            String message
    ) {
    }

    public record BulkOperationResponse(
            int processed,
            int success,
            int failed,
            List<BulkRowError> errors
    ) {
    }

    public record CreateExamRequest(
            @NotBlank @Size(min = 2, max = 255) String title
    ) {
    }

    public record ExamResponse(
            Long examId,
            Long classId,
            String title,
            String status,
            Instant createdAt
    ) {
    }

    public record StudentExamListItem(
            Long examId,
            Long classId,
            String title,
            String status,
            Instant createdAt
    ) {
    }

    public record StudentDashboardSummary(
            long totalExams,
            long readyExams,
            long processingExams,
            long draftExams,
            List<StudentExamListItem> latestExams
    ) {
    }

    public record ClassWithExamCountResponse(
            Long classId,
            Long schoolId,
            String className,
            long examCount,
            Instant createdAt
    ) {
    }

    public record TeacherDashboardSummary(
            long totalClasses,
            long totalExams,
            long processingExams,
            long readyExams,
            List<ExamResponse> latestExams,
            List<OcrJobStatusResponse> recentOcrJobs
    ) {
    }

    public record ExamImageResponse(
            Long imageId,
            int pageOrder,
            String imageUrl,
            String status,
            String errorMessage,
            Instant processingStartedAt,
            Instant processingCompletedAt
    ) {
    }

    public record UploadExamImagesResponse(
            Long examId,
            String status,
            List<ExamImageResponse> images
    ) {
    }

    public record OcrJobStatusResponse(
            UUID jobId,
            UUID requestId,
            String status,
            int retryCount,
            String errorMessage,
            Instant createdAt
    ) {
    }

    public record TeacherExamStatusResponse(
            Long examId,
            Long classId,
            String title,
            String examStatus,
            List<ExamImageResponse> images,
            List<OcrJobStatusResponse> ocrJobs,
            int questionCount,
            List<QuestionResponse> questions
    ) {
    }

    public record QuestionResponse(
            Long id,
            int pageNumber,
            int questionOrder,
            String sourceQuestionId,
            String questionText,
            String studentAnswer,
            double confidence
    ) {
    }
}
