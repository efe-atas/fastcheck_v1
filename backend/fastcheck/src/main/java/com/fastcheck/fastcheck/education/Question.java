package com.fastcheck.fastcheck.education;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "questions")
public class Question {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "exam_id", nullable = false)
    private Exam exam;

    @Column(nullable = false, length = 100)
    private String sourceQuestionId;

    @Column(nullable = false)
    private int pageNumber;

    @Column(nullable = false)
    private int questionOrder;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String questionTextRaw;

    @Column(columnDefinition = "TEXT")
    private String studentAnswerRaw;

    @Column(nullable = false)
    private double confidence;

    public Long getId() {
        return id;
    }

    public Exam getExam() {
        return exam;
    }

    public void setExam(Exam exam) {
        this.exam = exam;
    }

    public String getSourceQuestionId() {
        return sourceQuestionId;
    }

    public void setSourceQuestionId(String sourceQuestionId) {
        this.sourceQuestionId = sourceQuestionId;
    }

    public int getPageNumber() {
        return pageNumber;
    }

    public void setPageNumber(int pageNumber) {
        this.pageNumber = pageNumber;
    }

    public int getQuestionOrder() {
        return questionOrder;
    }

    public void setQuestionOrder(int questionOrder) {
        this.questionOrder = questionOrder;
    }

    public String getQuestionTextRaw() {
        return questionTextRaw;
    }

    public void setQuestionTextRaw(String questionTextRaw) {
        this.questionTextRaw = questionTextRaw;
    }

    public String getStudentAnswerRaw() {
        return studentAnswerRaw;
    }

    public void setStudentAnswerRaw(String studentAnswerRaw) {
        this.studentAnswerRaw = studentAnswerRaw;
    }

    public double getConfidence() {
        return confidence;
    }

    public void setConfidence(double confidence) {
        this.confidence = confidence;
    }
}
