package com.fastcheck.fastcheck.education;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;
import java.util.Arrays;
import java.util.List;

@Entity
@Table(
        name = "exam_images",
        uniqueConstraints = @UniqueConstraint(name = "uq_exam_page_order", columnNames = {"exam_id", "page_order"})
)
public class ExamImage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "exam_id", nullable = false)
    private Exam exam;

    @Column(nullable = false, length = 1200)
    private String imageUrl;

    @Column(nullable = false)
    private int pageOrder;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private ExamImageStatus status = ExamImageStatus.PENDING;

    @Column(length = 500)
    private String errorMessage;

    @Column(nullable = false)
    private Instant createdAt = Instant.now();

    private Instant processingStartedAt;

    private Instant processingCompletedAt;

    @Column(length = 255)
    private String detectedStudentName;

    private Double detectedStudentNameConfidence;

    private Long matchedStudentId;

    @Column(length = 255)
    private String matchedStudentName;

    private Double studentMatchConfidence;

    @Enumerated(EnumType.STRING)
    @Column(length = 32)
    private StudentMatchStatus studentMatchStatus;

    @Column(columnDefinition = "TEXT")
    private String candidateStudentIds;

    public Long getId() {
        return id;
    }

    public Exam getExam() {
        return exam;
    }

    public void setExam(Exam exam) {
        this.exam = exam;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public int getPageOrder() {
        return pageOrder;
    }

    public void setPageOrder(int pageOrder) {
        this.pageOrder = pageOrder;
    }

    public ExamImageStatus getStatus() {
        return status;
    }

    public void setStatus(ExamImageStatus status) {
        this.status = status;
    }

    public String getErrorMessage() {
        return errorMessage;
    }

    public void setErrorMessage(String errorMessage) {
        this.errorMessage = errorMessage;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getProcessingStartedAt() {
        return processingStartedAt;
    }

    public void setProcessingStartedAt(Instant processingStartedAt) {
        this.processingStartedAt = processingStartedAt;
    }

    public Instant getProcessingCompletedAt() {
        return processingCompletedAt;
    }

    public void setProcessingCompletedAt(Instant processingCompletedAt) {
        this.processingCompletedAt = processingCompletedAt;
    }

    public String getDetectedStudentName() {
        return detectedStudentName;
    }

    public void setDetectedStudentName(String detectedStudentName) {
        this.detectedStudentName = detectedStudentName;
    }

    public Double getDetectedStudentNameConfidence() {
        return detectedStudentNameConfidence;
    }

    public void setDetectedStudentNameConfidence(Double detectedStudentNameConfidence) {
        this.detectedStudentNameConfidence = detectedStudentNameConfidence;
    }

    public Long getMatchedStudentId() {
        return matchedStudentId;
    }

    public void setMatchedStudentId(Long matchedStudentId) {
        this.matchedStudentId = matchedStudentId;
    }

    public String getMatchedStudentName() {
        return matchedStudentName;
    }

    public void setMatchedStudentName(String matchedStudentName) {
        this.matchedStudentName = matchedStudentName;
    }

    public Double getStudentMatchConfidence() {
        return studentMatchConfidence;
    }

    public void setStudentMatchConfidence(Double studentMatchConfidence) {
        this.studentMatchConfidence = studentMatchConfidence;
    }

    public StudentMatchStatus getStudentMatchStatus() {
        return studentMatchStatus;
    }

    public void setStudentMatchStatus(StudentMatchStatus studentMatchStatus) {
        this.studentMatchStatus = studentMatchStatus;
    }

    public String getCandidateStudentIds() {
        return candidateStudentIds;
    }

    public void setCandidateStudentIds(String candidateStudentIds) {
        this.candidateStudentIds = candidateStudentIds;
    }

    @Transient
    public List<Long> getCandidateStudentIdList() {
        if (candidateStudentIds == null || candidateStudentIds.isBlank()) {
            return List.of();
        }
        return Arrays.stream(candidateStudentIds.split(","))
                .map(String::trim)
                .filter(value -> !value.isBlank())
                .map(Long::valueOf)
                .toList();
    }
}
