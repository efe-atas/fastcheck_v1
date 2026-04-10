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
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;

@Entity
@Table(
        name = "student_exam_results",
        uniqueConstraints = @UniqueConstraint(
                name = "uq_student_exam_result",
                columnNames = {"exam_id", "student_id"}
        )
)
public class StudentExamResult {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "exam_id", nullable = false)
    private Exam exam;

    @Column(nullable = false)
    private Long studentId;

    @Column(nullable = false, length = 255)
    private String studentName;

    @Column(nullable = false)
    private int totalQuestions;

    @Column(nullable = false)
    private int scoredQuestions;

    @Column(nullable = false)
    private double maxPoints;

    @Column(nullable = false)
    private double awardedPoints;

    private Double gradingConfidence;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private GradingStatus gradingStatus = GradingStatus.PENDING;

    @Column(columnDefinition = "TEXT")
    private String gradingSummary;

    @Column(nullable = false)
    private Instant createdAt = Instant.now();

    @Column(nullable = false)
    private Instant updatedAt = Instant.now();

    public Long getId() {
        return id;
    }

    public Exam getExam() {
        return exam;
    }

    public void setExam(Exam exam) {
        this.exam = exam;
    }

    public Long getStudentId() {
        return studentId;
    }

    public void setStudentId(Long studentId) {
        this.studentId = studentId;
    }

    public String getStudentName() {
        return studentName;
    }

    public void setStudentName(String studentName) {
        this.studentName = studentName;
    }

    public int getTotalQuestions() {
        return totalQuestions;
    }

    public void setTotalQuestions(int totalQuestions) {
        this.totalQuestions = totalQuestions;
    }

    public int getScoredQuestions() {
        return scoredQuestions;
    }

    public void setScoredQuestions(int scoredQuestions) {
        this.scoredQuestions = scoredQuestions;
    }

    public double getMaxPoints() {
        return maxPoints;
    }

    public void setMaxPoints(double maxPoints) {
        this.maxPoints = maxPoints;
    }

    public double getAwardedPoints() {
        return awardedPoints;
    }

    public void setAwardedPoints(double awardedPoints) {
        this.awardedPoints = awardedPoints;
    }

    public Double getGradingConfidence() {
        return gradingConfidence;
    }

    public void setGradingConfidence(Double gradingConfidence) {
        this.gradingConfidence = gradingConfidence;
    }

    public GradingStatus getGradingStatus() {
        return gradingStatus;
    }

    public void setGradingStatus(GradingStatus gradingStatus) {
        this.gradingStatus = gradingStatus;
    }

    public String getGradingSummary() {
        return gradingSummary;
    }

    public void setGradingSummary(String gradingSummary) {
        this.gradingSummary = gradingSummary;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Instant updatedAt) {
        this.updatedAt = updatedAt;
    }
}
