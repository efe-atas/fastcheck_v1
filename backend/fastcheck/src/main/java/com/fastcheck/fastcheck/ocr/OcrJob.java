package com.fastcheck.fastcheck.ocr;

import com.fastcheck.fastcheck.education.ExamImage;
import com.fastcheck.fastcheck.user.UserAccount;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "ocr_jobs")
public class OcrJob {

    @Id
    @GeneratedValue
    private UUID jobId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private UserAccount user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "exam_image_id")
    private ExamImage examImage;

    @Column(nullable = false, length = 1200)
    private String imageUrl;

    @Column(length = 255)
    private String sourceId;

    @Column(nullable = false, unique = true)
    private UUID requestId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private OcrJobStatus status = OcrJobStatus.PENDING;

    @Column(nullable = false)
    private int retryCount = 0;

    @Column(columnDefinition = "TEXT")
    private String ocrResultJson;

    @Column(length = 500)
    private String errorMessage;

    @Column(nullable = false)
    private Instant createdAt = Instant.now();

    public UUID getJobId() {
        return jobId;
    }

    public UserAccount getUser() {
        return user;
    }

    public void setUser(UserAccount user) {
        this.user = user;
    }

    public ExamImage getExamImage() {
        return examImage;
    }

    public void setExamImage(ExamImage examImage) {
        this.examImage = examImage;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public String getSourceId() {
        return sourceId;
    }

    public void setSourceId(String sourceId) {
        this.sourceId = sourceId;
    }

    public UUID getRequestId() {
        return requestId;
    }

    public void setRequestId(UUID requestId) {
        this.requestId = requestId;
    }

    public OcrJobStatus getStatus() {
        return status;
    }

    public void setStatus(OcrJobStatus status) {
        this.status = status;
    }

    public int getRetryCount() {
        return retryCount;
    }

    public void setRetryCount(int retryCount) {
        this.retryCount = retryCount;
    }

    public String getOcrResultJson() {
        return ocrResultJson;
    }

    public void setOcrResultJson(String ocrResultJson) {
        this.ocrResultJson = ocrResultJson;
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
}
