package com.fastcheck.fastcheck.education;

import com.fastcheck.fastcheck.auth.ServiceTokenProvider;
import com.fastcheck.fastcheck.common.ApiException;
import com.fastcheck.fastcheck.ocr.OcrClient;
import com.fastcheck.fastcheck.ocr.OcrDtos;
import com.fastcheck.fastcheck.ocr.OcrJob;
import com.fastcheck.fastcheck.ocr.OcrJobRepository;
import com.fastcheck.fastcheck.ocr.OcrJobStatus;
import com.fastcheck.fastcheck.user.Role;
import com.fastcheck.fastcheck.user.UserAccount;
import com.fastcheck.fastcheck.user.UserRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Instant;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.http.HttpStatus;
import org.springframework.scheduling.annotation.Async;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
public class ExamOcrQueueService {
    private static final Logger log = LoggerFactory.getLogger(ExamOcrQueueService.class);

    private final ExamRepository examRepository;
    private final ExamImageRepository examImageRepository;
    private final OcrJobRepository ocrJobRepository;
    private final QuestionRepository questionRepository;
    private final UserRepository userRepository;
    private final OcrClient ocrClient;
    private final StudentNameMatcherService studentNameMatcherService;
    private final ExamGradingService examGradingService;
    private final ServiceTokenProvider serviceTokenProvider;
    private final ObjectMapper objectMapper;
    private final ExamOcrEventPublisher eventPublisher;

    public ExamOcrQueueService(
            ExamRepository examRepository,
            ExamImageRepository examImageRepository,
            OcrJobRepository ocrJobRepository,
            QuestionRepository questionRepository,
            UserRepository userRepository,
            OcrClient ocrClient,
            StudentNameMatcherService studentNameMatcherService,
            ExamGradingService examGradingService,
            ServiceTokenProvider serviceTokenProvider,
            ObjectMapper objectMapper,
            ExamOcrEventPublisher eventPublisher
    ) {
        this.examRepository = examRepository;
        this.examImageRepository = examImageRepository;
        this.ocrJobRepository = ocrJobRepository;
        this.questionRepository = questionRepository;
        this.userRepository = userRepository;
        this.ocrClient = ocrClient;
        this.studentNameMatcherService = studentNameMatcherService;
        this.examGradingService = examGradingService;
        this.serviceTokenProvider = serviceTokenProvider;
        this.objectMapper = objectMapper;
        this.eventPublisher = eventPublisher;
    }

    @Async("ocrExecutor")
    public void enqueueExam(Long examId) {
        log.info("OCR queue started examId={}", examId);
        processExam(examId);
    }

    void processExam(Long examId) {
        Exam exam = examRepository.findById(examId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "exam not found"));

        List<ExamImage> allImages = examImageRepository.findByExam_IdOrderByPageOrderAsc(examId);
        if (allImages.isEmpty()) {
            log.warn("OCR queue aborted because exam has no images examId={}", examId);
            return;
        }

        List<ExamImage> queuedImages = allImages.stream()
                .filter(image -> image.getStatus() == ExamImageStatus.PENDING)
                .toList();
        if (queuedImages.isEmpty()) {
            updateExamStatusFromImages(exam, allImages);
            log.info("OCR queue skipped because exam has no pending pages examId={}", examId);
            return;
        }

        exam.setStatus(ExamStatus.PROCESSING);
        publishEvent(exam, "QUEUED", "Exam queued for OCR");
        log.info(
                "OCR exam marked processing examId={} pendingPages={} totalPages={}",
                examId,
                queuedImages.size(),
                allImages.size()
        );

        for (ExamImage image : queuedImages) {
            processImage(exam, image, allImages);
            if (image.getStatus() == ExamImageStatus.FAILED) {
                updateExamStatusFromImages(exam, allImages);
                publishEvent(exam, "FAILED", "OCR failed on page " + image.getPageOrder());
                log.warn(
                        "OCR exam failed examId={} pageOrder={} error={}",
                        examId,
                        image.getPageOrder(),
                        image.getErrorMessage()
                );
                return;
            }
        }

        updateExamStatusFromImages(exam, allImages);
        publishEvent(exam, "COMPLETED", "OCR finished successfully");
        log.info(
                "OCR exam completed examId={} processedPages={} totalPages={}",
                examId,
                queuedImages.size(),
                allImages.size()
        );
    }

    private void processImage(Exam exam, ExamImage image, List<ExamImage> allImages) {
        questionRepository.deleteByExamImage_Id(image.getId());
        image.setStatus(ExamImageStatus.PROCESSING);
        image.setErrorMessage(null);
        image.setProcessingStartedAt(Instant.now());
        image.setProcessingCompletedAt(null);
        examImageRepository.save(image);

        OcrJob job = new OcrJob();
        job.setUser(exam.getTeacher());
        job.setExamImage(image);
        job.setImageUrl(image.getImageUrl());
        job.setSourceId("exam-" + exam.getId() + "-page-" + image.getPageOrder());
        job.setRequestId(UUID.randomUUID());
        job.setStatus(OcrJobStatus.PROCESSING);
        job = ocrJobRepository.save(job);
        log.info(
                "OCR page started examId={} pageOrder={} jobId={} requestId={}",
                exam.getId(),
                image.getPageOrder(),
                job.getJobId(),
                job.getRequestId()
        );

        String serviceJwt = serviceTokenProvider.createServiceToken();
        int maxRetries = 3;
        for (int attempt = 1; attempt <= maxRetries; attempt++) {
            try {
                log.info(
                        "OCR page attempt started examId={} pageOrder={} attempt={}/{} requestId={}",
                        exam.getId(),
                        image.getPageOrder(),
                        attempt,
                        maxRetries,
                        job.getRequestId()
                );
                OcrDtos.FastApiResponse response = ocrClient.extract(
                        new OcrDtos.FastApiRequest(image.getImageUrl(), job.getSourceId(), "tr"),
                        serviceJwt,
                        exam.getTeacher().getId(),
                        job.getRequestId().toString()
                );
                job.setOcrResultJson(objectMapper.writeValueAsString(response.result()));
                job.setStatus(OcrJobStatus.COMPLETED);
                job.setRetryCount(attempt - 1);
                ocrJobRepository.save(job);
                applyStudentMatch(exam, image, response.result());
                examGradingService.updateExamMetadataFromOcr(exam, response.result());
                persistQuestions(exam, image, response.result());
                propagateMatchedStudentAcrossExam(allImages);
                examGradingService.recomputeStudentResults(exam);
                image.setStatus(ExamImageStatus.COMPLETED);
                image.setProcessingCompletedAt(Instant.now());
                examImageRepository.save(image);
                publishEvent(exam, "PAGE_COMPLETED", "Page " + image.getPageOrder() + " completed");
                log.info(
                        "OCR page completed examId={} pageOrder={} attempt={} requestId={}",
                        exam.getId(),
                        image.getPageOrder(),
                        attempt,
                        job.getRequestId()
                );
                return;
            } catch (ApiException exc) {
                if (exc.getStatus() == HttpStatus.BAD_GATEWAY && attempt < maxRetries) {
                    job.setRetryCount(attempt);
                    ocrJobRepository.save(job);
                    log.warn(
                            "OCR page retry scheduled examId={} pageOrder={} attempt={}/{} requestId={} detail={}",
                            exam.getId(),
                            image.getPageOrder(),
                            attempt,
                            maxRetries,
                            job.getRequestId(),
                            exc.getMessage()
                    );
                    sleepBackoff(attempt);
                    continue;
                }
                markFailed(image, job, exc.getMessage(), attempt - 1);
                return;
            } catch (Exception exc) {
                log.error(
                        "OCR page crashed examId={} pageOrder={} requestId={}",
                        exam.getId(),
                        image.getPageOrder(),
                        job.getRequestId(),
                        exc
                );
                markFailed(image, job, "ocr processing failed", attempt - 1);
                return;
            }
        }
    }

    private void markFailed(ExamImage image, OcrJob job, String message, int retryCount) {
        image.setStatus(ExamImageStatus.FAILED);
        image.setErrorMessage(message.length() > 500 ? message.substring(0, 500) : message);
        image.setProcessingCompletedAt(Instant.now());
        examImageRepository.save(image);

        job.setStatus(OcrJobStatus.FAILED);
        job.setRetryCount(retryCount);
        job.setErrorMessage(image.getErrorMessage());
        ocrJobRepository.save(job);
        log.warn(
                "OCR page marked failed imageId={} jobId={} retries={} message={}",
                image.getId(),
                job.getJobId(),
                retryCount,
                image.getErrorMessage()
        );
    }

    private void sleepBackoff(int attempt) {
        long[] backoff = {200L, 400L, 800L};
        long millis = backoff[Math.min(attempt - 1, backoff.length - 1)];
        try {
            Thread.sleep(millis);
        } catch (InterruptedException ignored) {
            Thread.currentThread().interrupt();
        }
    }

    private void applyStudentMatch(Exam exam, ExamImage image, JsonNode result) {
        DetectedStudentName detectedStudentName = extractDetectedStudentName(result);
        List<UserAccount> students = userRepository.findBySchoolClass_IdAndRoleOrderByFullNameAsc(
                exam.getSchoolClass().getId(),
                Role.ROLE_STUDENT
        );
        StudentNameMatcherService.StudentNameMatchResult autoMatch = studentNameMatcherService.match(
                detectedStudentName.value(),
                students
        );

        image.setDetectedStudentName(emptyToNull(detectedStudentName.value()));
        image.setDetectedStudentNameConfidence(detectedStudentName.confidence());
        image.setCandidateStudentIds(joinIds(autoMatch.candidateStudentIds()));

        if (image.getStudentMatchStatus() == StudentMatchStatus.MANUAL && image.getMatchedStudentId() != null) {
            image.setStudentMatchConfidence(1.0);
            return;
        }

        image.setMatchedStudentId(autoMatch.matchedStudentId());
        image.setMatchedStudentName(autoMatch.matchedStudentName());
        image.setStudentMatchConfidence(autoMatch.confidence());
        image.setStudentMatchStatus(autoMatch.status());
    }

    private void propagateMatchedStudentAcrossExam(List<ExamImage> images) {
        List<ExamImage> trustedMatches = images.stream()
                .filter(this::isTrustedMatch)
                .toList();
        if (trustedMatches.isEmpty()) {
            clearPropagatedMatches(images);
            return;
        }

        Set<Long> distinctStudentIds = trustedMatches.stream()
                .map(ExamImage::getMatchedStudentId)
                .collect(Collectors.toCollection(LinkedHashSet::new));
        if (distinctStudentIds.size() != 1) {
            clearPropagatedMatches(images);
            return;
        }

        ExamImage source = selectPropagationSource(trustedMatches);
        for (ExamImage image : images) {
            if (isTrustedMatch(image) || hasDetectedStudentName(image)) {
                continue;
            }
            applyPropagatedMatch(image, source);
        }
    }

    private ExamImage selectPropagationSource(List<ExamImage> trustedMatches) {
        return trustedMatches.stream()
                .filter(image -> image.getStudentMatchStatus() == StudentMatchStatus.MANUAL)
                .findFirst()
                .orElse(trustedMatches.getFirst());
    }

    private boolean isTrustedMatch(ExamImage image) {
        if (image.getMatchedStudentId() == null || image.getStudentMatchStatus() == null) {
            return false;
        }
        if (image.getStudentMatchStatus() == StudentMatchStatus.MANUAL) {
            return true;
        }
        return image.getStudentMatchStatus() == StudentMatchStatus.MATCHED && hasDetectedStudentName(image);
    }

    private boolean hasDetectedStudentName(ExamImage image) {
        return image.getDetectedStudentName() != null && !image.getDetectedStudentName().isBlank();
    }

    private void applyPropagatedMatch(ExamImage target, ExamImage source) {
        if (source.getMatchedStudentId() == null) {
            return;
        }
        if (Objects.equals(target.getMatchedStudentId(), source.getMatchedStudentId())
                && Objects.equals(target.getMatchedStudentName(), source.getMatchedStudentName())
                && target.getStudentMatchStatus() == StudentMatchStatus.MATCHED) {
            return;
        }

        target.setMatchedStudentId(source.getMatchedStudentId());
        target.setMatchedStudentName(source.getMatchedStudentName());
        target.setStudentMatchConfidence(source.getStudentMatchConfidence() != null
                ? source.getStudentMatchConfidence()
                : 1.0);
        target.setStudentMatchStatus(StudentMatchStatus.MATCHED);
    }

    private void clearPropagatedMatches(List<ExamImage> images) {
        for (ExamImage image : images) {
            if (isTrustedMatch(image) || hasDetectedStudentName(image) || image.getMatchedStudentId() == null) {
                continue;
            }
            image.setMatchedStudentId(null);
            image.setMatchedStudentName(null);
            image.setStudentMatchConfidence(null);
            image.setStudentMatchStatus(StudentMatchStatus.UNMATCHED);
        }
    }

    private DetectedStudentName extractDetectedStudentName(JsonNode result) {
        JsonNode pages = result.path("pages");
        if (!pages.isArray()) {
            return new DetectedStudentName("", 0.0);
        }

        String bestName = "";
        double bestConfidence = 0.0;
        for (JsonNode page : pages) {
            String name = page.path("detected_student_name").asText("");
            double confidence = page.path("name_confidence").asDouble(0.0);
            if (name != null && !name.isBlank() && confidence >= bestConfidence) {
                bestName = name.trim();
                bestConfidence = confidence;
            }
        }
        return new DetectedStudentName(bestName, bestConfidence);
    }

    private String joinIds(List<Long> ids) {
        if (ids == null || ids.isEmpty()) {
            return null;
        }
        return ids.stream().map(String::valueOf).collect(Collectors.joining(","));
    }

    private String emptyToNull(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }

    private void persistQuestions(Exam exam, ExamImage image, JsonNode result) {
        JsonNode pages = result.path("pages");
        if (!pages.isArray()) {
            return;
        }
        for (JsonNode page : pages) {
            JsonNode questions = page.path("questions");
            if (!questions.isArray()) {
                continue;
            }
            int index = 0;
            for (JsonNode q : questions) {
                Question question = examGradingService.createQuestionFromOcr(exam, image, q, ++index);
                questionRepository.save(question);
            }
        }
    }

    private void publishEvent(Exam exam, String type, String message) {
        if (eventPublisher == null) {
            return;
        }
        eventPublisher.publish(new ExamOcrEventPublisher.ExamOcrEvent(
                exam.getId(),
                exam.getTeacher().getId(),
                type,
                message,
                Instant.now()
        ));
    }

    private void updateExamStatusFromImages(Exam exam, List<ExamImage> images) {
        boolean hasFailed = images.stream().anyMatch(image -> image.getStatus() == ExamImageStatus.FAILED);
        boolean hasPending = images.stream().anyMatch(image ->
                image.getStatus() == ExamImageStatus.PENDING || image.getStatus() == ExamImageStatus.PROCESSING
        );

        if (hasFailed) {
            exam.setStatus(ExamStatus.FAILED);
        } else if (hasPending) {
            exam.setStatus(ExamStatus.PROCESSING);
        } else {
            exam.setStatus(ExamStatus.READY);
        }
        examRepository.save(exam);
    }

    private record DetectedStudentName(String value, double confidence) {
    }
}
