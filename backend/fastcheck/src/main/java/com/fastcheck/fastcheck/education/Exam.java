package com.fastcheck.fastcheck.education;

import com.fastcheck.fastcheck.user.UserAccount;
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
import java.time.Instant;

@Entity
@Table(name = "exams")
public class Exam {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "class_id", nullable = false)
    private SchoolClass schoolClass;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "teacher_id", nullable = false)
    private UserAccount teacher;

    @Column(nullable = false, length = 255)
    private String title;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private ExamStatus status = ExamStatus.DRAFT;

    @Column(columnDefinition = "TEXT")
    private String gradingSystemSummary;

    private Double totalMaxPoints;

    @Column(nullable = false)
    private Instant createdAt = Instant.now();

    public Long getId() {
        return id;
    }

    public SchoolClass getSchoolClass() {
        return schoolClass;
    }

    public void setSchoolClass(SchoolClass schoolClass) {
        this.schoolClass = schoolClass;
    }

    public UserAccount getTeacher() {
        return teacher;
    }

    public void setTeacher(UserAccount teacher) {
        this.teacher = teacher;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public ExamStatus getStatus() {
        return status;
    }

    public void setStatus(ExamStatus status) {
        this.status = status;
    }

    public String getGradingSystemSummary() {
        return gradingSystemSummary;
    }

    public void setGradingSystemSummary(String gradingSystemSummary) {
        this.gradingSystemSummary = gradingSystemSummary;
    }

    public Double getTotalMaxPoints() {
        return totalMaxPoints;
    }

    public void setTotalMaxPoints(Double totalMaxPoints) {
        this.totalMaxPoints = totalMaxPoints;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
