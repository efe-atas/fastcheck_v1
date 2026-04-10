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
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;

@Entity
@Table(name = "questions")
public class Question {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "exam_id", nullable = false)
    private Exam exam;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "exam_image_id")
    private ExamImage examImage;

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

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private QuestionType questionType = QuestionType.UNKNOWN;

    @Column(columnDefinition = "TEXT")
    private String expectedAnswerRaw;

    @Column(columnDefinition = "TEXT")
    private String gradingRubricRaw;

    private Double maxPoints;

    private Double awardedPoints;

    private Double gradingConfidence;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private GradingStatus gradingStatus = GradingStatus.PENDING;

    @Column(columnDefinition = "TEXT")
    private String evaluationSummary;

    private Boolean correct;

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

    public ExamImage getExamImage() {
        return examImage;
    }

    public void setExamImage(ExamImage examImage) {
        this.examImage = examImage;
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

    public QuestionType getQuestionType() {
        return questionType;
    }

    public void setQuestionType(QuestionType questionType) {
        this.questionType = questionType;
    }

    public String getExpectedAnswerRaw() {
        return expectedAnswerRaw;
    }

    public void setExpectedAnswerRaw(String expectedAnswerRaw) {
        this.expectedAnswerRaw = expectedAnswerRaw;
    }

    public String getGradingRubricRaw() {
        return gradingRubricRaw;
    }

    public void setGradingRubricRaw(String gradingRubricRaw) {
        this.gradingRubricRaw = gradingRubricRaw;
    }

    public Double getMaxPoints() {
        return maxPoints;
    }

    public void setMaxPoints(Double maxPoints) {
        this.maxPoints = maxPoints;
    }

    public Double getAwardedPoints() {
        return awardedPoints;
    }

    public void setAwardedPoints(Double awardedPoints) {
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

    public String getEvaluationSummary() {
        return evaluationSummary;
    }

    public void setEvaluationSummary(String evaluationSummary) {
        this.evaluationSummary = evaluationSummary;
    }

    public Boolean getCorrect() {
        return correct;
    }

    public void setCorrect(Boolean correct) {
        this.correct = correct;
    }

    public double getConfidence() {
        return confidence;
    }

    public void setConfidence(double confidence) {
        this.confidence = confidence;
    }
}
