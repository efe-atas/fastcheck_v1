package com.fastcheck.fastcheck.education;

import com.fasterxml.jackson.databind.JsonNode;
import java.text.Normalizer;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.regex.Pattern;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ExamGradingService {
    private static final Pattern MULTIPLE_CHOICE_PATTERN = Pattern.compile("^[A-E]$");
    private static final Pattern NUMERIC_PATTERN = Pattern.compile("^-?\\d+(?:[\\.,]\\d+)?$");

    private final ExamRepository examRepository;
    private final QuestionRepository questionRepository;
    private final StudentExamResultRepository studentExamResultRepository;

    public ExamGradingService(
            ExamRepository examRepository,
            QuestionRepository questionRepository,
            StudentExamResultRepository studentExamResultRepository
    ) {
        this.examRepository = examRepository;
        this.questionRepository = questionRepository;
        this.studentExamResultRepository = studentExamResultRepository;
    }

    public Question createQuestionFromOcr(Exam exam, ExamImage image, JsonNode questionNode, int questionOrder) {
        Question question = new Question();
        question.setExam(exam);
        question.setExamImage(image);
        question.setPageNumber(image.getPageOrder());
        question.setQuestionOrder(questionOrder);
        question.setSourceQuestionId(readText(questionNode, "question_id"));
        question.setQuestionTextRaw(readText(questionNode, "question_text_raw"));
        question.setStudentAnswerRaw(readText(questionNode, "student_answer_raw"));
        question.setConfidence(readDouble(questionNode, "confidence", 0.0));

        String expectedAnswer = readText(questionNode, "expected_answer_raw");
        String gradingRubric = readText(questionNode, "grading_rubric_raw");
        Double maxPoints = readNullableDouble(questionNode, "max_points");
        Double extractedAwardedPoints = readNullableDouble(questionNode, "awarded_points");
        Double gradingConfidence = readNullableDouble(questionNode, "grading_confidence");
        String evaluationSummary = readText(questionNode, "evaluation_summary");
        boolean needsReview = readBoolean(questionNode, "needs_review");

        QuestionType questionType = resolveQuestionType(
                readText(questionNode, "question_type"),
                expectedAnswer,
                question.getStudentAnswerRaw()
        );
        double resolvedMaxPoints = resolveMaxPoints(maxPoints);
        double resolvedAwardedPoints = resolveAwardedPoints(
                questionType,
                expectedAnswer,
                question.getStudentAnswerRaw(),
                gradingRubric,
                resolvedMaxPoints,
                extractedAwardedPoints
        );
        double resolvedGradingConfidence = resolveGradingConfidence(gradingConfidence, question.getConfidence(), needsReview);
        Boolean correct = resolveCorrectness(questionNode.get("is_correct"), resolvedAwardedPoints, resolvedMaxPoints);
        GradingStatus gradingStatus = resolveGradingStatus(needsReview, resolvedGradingConfidence, resolvedAwardedPoints, resolvedMaxPoints);

        question.setQuestionType(questionType);
        question.setExpectedAnswerRaw(emptyToNull(expectedAnswer));
        question.setGradingRubricRaw(emptyToNull(gradingRubric));
        question.setMaxPoints(resolvedMaxPoints);
        question.setAwardedPoints(resolvedAwardedPoints);
        question.setGradingConfidence(roundScore(resolvedGradingConfidence));
        question.setGradingStatus(gradingStatus);
        question.setCorrect(correct);
        question.setEvaluationSummary(buildEvaluationSummary(
                emptyToNull(evaluationSummary),
                questionType,
                resolvedAwardedPoints,
                resolvedMaxPoints,
                correct
        ));
        return question;
    }

    public void updateExamMetadataFromOcr(Exam exam, JsonNode result) {
        String gradingSystemSummary = readText(result, "grading_system_summary");
        Double totalMaxPoints = readNullableDouble(result, "total_max_points");

        if (gradingSystemSummary != null && !gradingSystemSummary.isBlank()) {
            exam.setGradingSystemSummary(gradingSystemSummary.trim());
        }
        if (totalMaxPoints != null && totalMaxPoints > 0) {
            exam.setTotalMaxPoints(roundScore(totalMaxPoints));
        }
        examRepository.save(exam);
    }

    @Transactional
    public void recomputeStudentResults(Exam exam) {
        List<Question> questions = questionRepository.findByExam_IdOrderByPageNumberAscQuestionOrderAsc(exam.getId());
        Map<Long, StudentAggregate> aggregates = new LinkedHashMap<>();
        Map<Long, StudentExamResult> existingResultsByStudentId = studentExamResultRepository
                .findByExam_IdOrderByAwardedPointsDescStudentNameAsc(exam.getId())
                .stream()
                .collect(java.util.stream.Collectors.toMap(
                        StudentExamResult::getStudentId,
                        result -> result,
                        (left, right) -> left,
                        LinkedHashMap::new
                ));

        for (Question question : questions) {
            ExamImage image = question.getExamImage();
            if (image == null || image.getMatchedStudentId() == null) {
                continue;
            }
            StudentAggregate aggregate = aggregates.computeIfAbsent(
                    image.getMatchedStudentId(),
                    studentId -> new StudentAggregate(studentId, image.getMatchedStudentName())
            );
            aggregate.accept(question);
        }

        double examMaxPoints = 0.0;
        List<StudentExamResult> results = new ArrayList<>();
        HashSet<Long> activeStudentIds = new HashSet<>();
        for (StudentAggregate aggregate : aggregates.values()) {
            activeStudentIds.add(aggregate.studentId());
            StudentExamResult result = aggregate.toEntity(exam, existingResultsByStudentId.get(aggregate.studentId()));
            results.add(result);
            examMaxPoints = Math.max(examMaxPoints, result.getMaxPoints());
        }

        List<StudentExamResult> staleResults = existingResultsByStudentId.values()
                .stream()
                .filter(existing -> !activeStudentIds.contains(existing.getStudentId()))
                .toList();

        if (!staleResults.isEmpty()) {
            studentExamResultRepository.deleteAll(staleResults);
        }

        if (!results.isEmpty()) {
            studentExamResultRepository.saveAll(results);
        }
        exam.setTotalMaxPoints(results.isEmpty() ? null : roundScore(examMaxPoints));
        examRepository.save(exam);
    }

    private double resolveMaxPoints(Double maxPoints) {
        if (maxPoints == null || maxPoints <= 0) {
            return 1.0;
        }
        return roundScore(maxPoints);
    }

    private double resolveAwardedPoints(
            QuestionType questionType,
            String expectedAnswer,
            String studentAnswer,
            String gradingRubric,
            double maxPoints,
            Double extractedAwardedPoints
    ) {
        if (extractedAwardedPoints != null) {
            return clampScore(extractedAwardedPoints, maxPoints);
        }

        if (questionType == QuestionType.MULTIPLE_CHOICE
                || questionType == QuestionType.SHORT_TEXT
                || questionType == QuestionType.NUMERIC) {
            return compareDeterministic(questionType, expectedAnswer, studentAnswer) ? maxPoints : 0.0;
        }

        return heuristicOpenEndedScore(expectedAnswer, studentAnswer, gradingRubric, maxPoints);
    }

    private boolean compareDeterministic(QuestionType questionType, String expectedAnswer, String studentAnswer) {
        if (expectedAnswer == null || expectedAnswer.isBlank() || studentAnswer == null || studentAnswer.isBlank()) {
            return false;
        }
        if (questionType == QuestionType.NUMERIC) {
            String normalizedExpected = normalizeNumeric(expectedAnswer);
            String normalizedStudent = normalizeNumeric(studentAnswer);
            return normalizedExpected.equals(normalizedStudent);
        }
        return normalizeExact(expectedAnswer).equals(normalizeExact(studentAnswer));
    }

    private double heuristicOpenEndedScore(
            String expectedAnswer,
            String studentAnswer,
            String gradingRubric,
            double maxPoints
    ) {
        if (studentAnswer == null || studentAnswer.isBlank()) {
            return 0.0;
        }
        if (expectedAnswer == null || expectedAnswer.isBlank()) {
            return gradingRubric == null || gradingRubric.isBlank() ? 0.0 : roundScore(maxPoints * 0.5);
        }

        List<String> expectedTokens = tokenize(expectedAnswer);
        if (expectedTokens.isEmpty()) {
            return 0.0;
        }
        List<String> answerTokens = tokenize(studentAnswer);
        long overlap = expectedTokens.stream().filter(answerTokens::contains).count();
        double ratio = (double) overlap / (double) expectedTokens.size();
        double rubricBoost = gradingRubric != null && !gradingRubric.isBlank() ? 0.1 : 0.0;
        return clampScore((ratio + rubricBoost) * maxPoints, maxPoints);
    }

    private QuestionType resolveQuestionType(String rawType, String expectedAnswer, String studentAnswer) {
        if (rawType != null && !rawType.isBlank()) {
            String normalized = normalizeExact(rawType);
            return switch (normalized) {
                case "multiplechoice", "coktansecmeli" -> QuestionType.MULTIPLE_CHOICE;
                case "shorttext", "kisacevap" -> QuestionType.SHORT_TEXT;
                case "numeric", "sayisal" -> QuestionType.NUMERIC;
                case "openended", "acikuclu" -> QuestionType.OPEN_ENDED;
                default -> QuestionType.UNKNOWN;
            };
        }
        if (matchesMultipleChoice(expectedAnswer) || matchesMultipleChoice(studentAnswer)) {
            return QuestionType.MULTIPLE_CHOICE;
        }
        if (matchesNumeric(expectedAnswer)) {
            return QuestionType.NUMERIC;
        }
        if (expectedAnswer != null && tokenize(expectedAnswer).size() <= 4) {
            return QuestionType.SHORT_TEXT;
        }
        return QuestionType.OPEN_ENDED;
    }

    private double resolveGradingConfidence(Double gradingConfidence, double ocrConfidence, boolean needsReview) {
        double base = gradingConfidence == null ? ocrConfidence : gradingConfidence;
        if (needsReview) {
            base = Math.min(base, 0.45);
        }
        return Math.max(0.0, Math.min(1.0, base));
    }

    private Boolean resolveCorrectness(JsonNode explicitNode, double awardedPoints, double maxPoints) {
        if (explicitNode != null && !explicitNode.isNull()) {
            return explicitNode.asBoolean();
        }
        if (maxPoints <= 0) {
            return null;
        }
        if (awardedPoints == 0.0d) {
            return Boolean.FALSE;
        }
        if (Math.abs(awardedPoints - maxPoints) < 0.0001d) {
            return Boolean.TRUE;
        }
        return null;
    }

    private GradingStatus resolveGradingStatus(
            boolean needsReview,
            double gradingConfidence,
            double awardedPoints,
            double maxPoints
    ) {
        if (needsReview || gradingConfidence < 0.25) {
            return GradingStatus.NEEDS_REVIEW;
        }
        if (maxPoints > 0.0 && awardedPoints > 0.0 && awardedPoints < maxPoints) {
            return GradingStatus.PARTIALLY_GRADED;
        }
        return GradingStatus.GRADED;
    }

    private String buildEvaluationSummary(
            String explicitSummary,
            QuestionType questionType,
            double awardedPoints,
            double maxPoints,
            Boolean correct
    ) {
        if (explicitSummary != null && !explicitSummary.isBlank()) {
            return explicitSummary;
        }
        if (Boolean.TRUE.equals(correct)) {
            return "Beklenen cevaba uygun bulundu.";
        }
        if (Boolean.FALSE.equals(correct) && awardedPoints == 0.0d) {
            return "Beklenen cevapla uyumsuz bulundu.";
        }
        if (questionType == QuestionType.OPEN_ENDED) {
            return "Acik uclu cevap rubrik ve icerik uyumuna gore puanlandi.";
        }
        return "Kismi uyum nedeniyle ara puan verildi.";
    }

    private boolean matchesMultipleChoice(String value) {
        return value != null && MULTIPLE_CHOICE_PATTERN.matcher(value.trim().toUpperCase(Locale.ROOT)).matches();
    }

    private boolean matchesNumeric(String value) {
        return value != null && NUMERIC_PATTERN.matcher(value.trim()).matches();
    }

    private String normalizeExact(String value) {
        if (value == null) {
            return "";
        }
        String normalized = Normalizer.normalize(value, Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "")
                .toLowerCase(Locale.ROOT);
        return normalized.replaceAll("[^a-z0-9]+", "");
    }

    private String normalizeNumeric(String value) {
        if (value == null) {
            return "";
        }
        return value.trim().replace(",", ".").replaceAll("\\s+", "");
    }

    private List<String> tokenize(String value) {
        String normalized = Normalizer.normalize(Objects.toString(value, ""), Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "")
                .toLowerCase(Locale.ROOT)
                .replaceAll("[^a-z0-9\\s]+", " ");
        return List.of(normalized.trim().split("\\s+"))
                .stream()
                .filter(token -> !token.isBlank())
                .distinct()
                .toList();
    }

    private String readText(JsonNode node, String fieldName) {
        JsonNode value = node == null ? null : node.get(fieldName);
        if (value == null || value.isNull()) {
            return "";
        }
        return value.asText("");
    }

    private Double readNullableDouble(JsonNode node, String fieldName) {
        JsonNode value = node == null ? null : node.get(fieldName);
        if (value == null || value.isNull()) {
            return null;
        }
        return value.asDouble();
    }

    private double readDouble(JsonNode node, String fieldName, double defaultValue) {
        JsonNode value = node == null ? null : node.get(fieldName);
        if (value == null || value.isNull()) {
            return defaultValue;
        }
        return value.asDouble(defaultValue);
    }

    private boolean readBoolean(JsonNode node, String fieldName) {
        JsonNode value = node == null ? null : node.get(fieldName);
        return value != null && !value.isNull() && value.asBoolean(false);
    }

    private String emptyToNull(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }

    private double clampScore(double value, double maxPoints) {
        if (Double.isNaN(value) || Double.isInfinite(value)) {
            return 0.0;
        }
        return roundScore(Math.max(0.0, Math.min(value, maxPoints)));
    }

    private double roundScore(double value) {
        return Math.round(value * 100.0) / 100.0;
    }

    private final class StudentAggregate {
        private final Long studentId;
        private final String studentName;
        private int totalQuestions;
        private int scoredQuestions;
        private double maxPoints;
        private double awardedPoints;
        private double confidenceTotal;
        private int confidenceCount;
        private boolean hasNeedsReview;
        private boolean hasPartial;

        private StudentAggregate(Long studentId, String studentName) {
            this.studentId = studentId;
            this.studentName = studentName == null || studentName.isBlank() ? "Bilinmeyen Ogrenci" : studentName;
        }

        private void accept(Question question) {
            totalQuestions++;
            double questionMaxPoints = question.getMaxPoints() == null ? 0.0 : question.getMaxPoints();
            double questionAwardedPoints = question.getAwardedPoints() == null ? 0.0 : question.getAwardedPoints();
            maxPoints += questionMaxPoints;
            awardedPoints += questionAwardedPoints;
            if (question.getAwardedPoints() != null) {
                scoredQuestions++;
            }
            double confidence = question.getGradingConfidence() == null ? question.getConfidence() : question.getGradingConfidence();
            confidenceTotal += confidence;
            confidenceCount++;

            if (question.getGradingStatus() == GradingStatus.NEEDS_REVIEW
                    || question.getGradingStatus() == GradingStatus.FAILED) {
                hasNeedsReview = true;
            }
            if (question.getGradingStatus() == GradingStatus.PARTIALLY_GRADED
                    || (questionMaxPoints > 0.0 && questionAwardedPoints > 0.0 && questionAwardedPoints < questionMaxPoints)) {
                hasPartial = true;
            }
        }

        private Long studentId() {
            return studentId;
        }

        private StudentExamResult toEntity(Exam exam, StudentExamResult existing) {
            StudentExamResult result = existing == null ? new StudentExamResult() : existing;
            result.setExam(exam);
            result.setStudentId(studentId);
            result.setStudentName(studentName);
            result.setTotalQuestions(totalQuestions);
            result.setScoredQuestions(scoredQuestions);
            result.setMaxPoints(roundScore(maxPoints));
            result.setAwardedPoints(roundScore(awardedPoints));
            result.setGradingConfidence(confidenceCount == 0 ? null : roundScore(confidenceTotal / confidenceCount));
            result.setGradingStatus(resolveStatus());
            result.setGradingSummary(buildSummary());
            result.setUpdatedAt(Instant.now());
            return result;
        }

        private GradingStatus resolveStatus() {
            if (hasNeedsReview) {
                return GradingStatus.NEEDS_REVIEW;
            }
            if (scoredQuestions < totalQuestions || hasPartial) {
                return GradingStatus.PARTIALLY_GRADED;
            }
            return GradingStatus.GRADED;
        }

        private String buildSummary() {
            return String.format(
                    Locale.US,
                    "%.2f / %.2f puan, %d sorunun %d tanesi puanlandi.",
                    roundScore(awardedPoints),
                    roundScore(maxPoints),
                    scoredQuestions,
                    totalQuestions
            );
        }
    }
}
