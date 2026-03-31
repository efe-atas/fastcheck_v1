package com.fastcheck.fastcheck.education;

import com.fastcheck.fastcheck.auth.ServiceTokenProvider;
import com.fastcheck.fastcheck.common.ApiException;
import com.fastcheck.fastcheck.ocr.OcrClient;
import com.fastcheck.fastcheck.ocr.OcrDtos;
import com.fastcheck.fastcheck.ocr.OcrJob;
import com.fastcheck.fastcheck.ocr.OcrJobRepository;
import com.fastcheck.fastcheck.ocr.OcrJobStatus;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ExamOcrQueueService {

    private final ExamRepository examRepository;
    private final ExamImageRepository examImageRepository;
    private final OcrJobRepository ocrJobRepository;
    private final QuestionRepository questionRepository;
    private final OcrClient ocrClient;
    private final ServiceTokenProvider serviceTokenProvider;
    private final ObjectMapper objectMapper;
    private final ExamOcrEventPublisher eventPublisher;

    public ExamOcrQueueService(
            ExamRepository examRepository,
            ExamImageRepository examImageRepository,
            OcrJobRepository ocrJobRepository,
            QuestionRepository questionRepository,
            OcrClient ocrClient,
            ServiceTokenProvider serviceTokenProvider,
            ObjectMapper objectMapper,
            ExamOcrEventPublisher eventPublisher
    ) {
        this.examRepository = examRepository;
        this.examImageRepository = examImageRepository;
        this.ocrJobRepository = ocrJobRepository;
        this.questionRepository = questionRepository;
        this.ocrClient = ocrClient;
        this.serviceTokenProvider = serviceTokenProvider;
        this.objectMapper = objectMapper;
        this.eventPublisher = eventPublisher;
    }

    @Async("ocrExecutor")
    @Transactional
    public void enqueueExam(Long examId) {
        processExam(examId);
    }

    private void processExam(Long examId) {
        Exam exam = examRepository.findById(examId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "exam not found"));

        List<ExamImage> images = examImageRepository.findByExam_IdOrderByPageOrderAsc(examId);
        if (images.isEmpty()) {
            return;
        }

        questionRepository.deleteByExam_Id(examId);
        exam.setStatus(ExamStatus.PROCESSING);
        publishEvent(exam, "QUEUED", "Exam queued for OCR");

        for (ExamImage image : images) {
            processImage(exam, image);
            if (image.getStatus() == ExamImageStatus.FAILED) {
                exam.setStatus(ExamStatus.FAILED);
                examRepository.save(exam);
                publishEvent(exam, "FAILED", "OCR failed on page " + image.getPageOrder());
                return;
            }
        }

        exam.setStatus(ExamStatus.READY);
        examRepository.save(exam);
        publishEvent(exam, "COMPLETED", "OCR finished successfully");
    }

    private void processImage(Exam exam, ExamImage image) {
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

        String serviceJwt = serviceTokenProvider.createServiceToken();
        int maxRetries = 3;
        for (int attempt = 1; attempt <= maxRetries; attempt++) {
            try {
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
                persistQuestions(exam, image.getPageOrder(), response.result());
                image.setStatus(ExamImageStatus.COMPLETED);
                image.setProcessingCompletedAt(Instant.now());
                examImageRepository.save(image);
                publishEvent(exam, "PAGE_COMPLETED", "Page " + image.getPageOrder() + " completed");
                return;
            } catch (ApiException exc) {
                if (exc.getStatus() == HttpStatus.BAD_GATEWAY && attempt < maxRetries) {
                    job.setRetryCount(attempt);
                    ocrJobRepository.save(job);
                    sleepBackoff(attempt);
                    continue;
                }
                markFailed(image, job, exc.getMessage(), attempt - 1);
                return;
            } catch (Exception exc) {
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

    private void persistQuestions(Exam exam, int pageOrder, JsonNode result) {
        JsonNode pages = result.path("pages");
        if (!pages.isArray()) {
            return;
        }
        for (JsonNode page : pages) {
            int pageNumber = page.path("page_number").asInt(pageOrder);
            JsonNode questions = page.path("questions");
            if (!questions.isArray()) {
                continue;
            }
            int index = 0;
            for (JsonNode q : questions) {
                Question question = new Question();
                question.setExam(exam);
                question.setPageNumber(pageNumber);
                question.setQuestionOrder(index++);
                question.setSourceQuestionId(q.path("question_id").asText(""));
                question.setQuestionTextRaw(q.path("question_text_raw").asText(""));
                question.setStudentAnswerRaw(q.path("student_answer_raw").asText(""));
                question.setConfidence(q.path("confidence").asDouble(0.0));
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
}
