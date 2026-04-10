package com.fastcheck.fastcheck.ocr;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.time.Instant;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

@Component
@Profile("mock-ocr")
public class MockOcrClient implements OcrClient {

    private static final Logger log = LoggerFactory.getLogger(MockOcrClient.class);
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public OcrDtos.FastApiResponse extract(
            OcrDtos.FastApiRequest request,
            String serviceJwt,
            Long userId,
            String requestId
    ) {
        log.info("Mock OCR invoked for user {} request {}", userId, requestId);
        ObjectNode page = objectMapper.createObjectNode();
        page.put("page_number", 1);
        page.put("detected_student_name", "Mock Student");
        page.put("name_confidence", 0.92);
        ObjectNode question = objectMapper.createObjectNode();
        question.put("question_id", "Q-" + Instant.now().toEpochMilli());
        question.put("question_text_raw", "Mock question text");
        question.putArray("question_lines").add("Mock question text");
        question.put("student_answer_raw", "Mock answer");
        question.putArray("student_answer_lines").add("Mock answer");
        question.put("confidence", 0.95);
        question.put("question_type", "open_ended");
        question.put("expected_answer_raw", "Mock expected answer");
        question.put("grading_rubric_raw", "Ana fikri dogru aciklamasi beklenir.");
        question.put("max_points", 10);
        question.put("awarded_points", 8);
        question.put("grading_confidence", 0.86);
        question.put("evaluation_summary", "Ana fikir buyuk oranda dogru.");
        question.put("needs_review", false);
        question.put("is_correct", false);
        page.putArray("questions").add(question);
        page.putArray("unmatched_text_blocks");
        ObjectNode result = objectMapper.createObjectNode();
        result.put("grading_system_summary", "Her soru 10 puan uzerinden degerlendirilir.");
        result.put("total_max_points", 10);
        result.putArray("pages").add(page);
        return new OcrDtos.FastApiResponse(
                requestId != null ? requestId : UUID.randomUUID().toString(),
                result
        );
    }
}
