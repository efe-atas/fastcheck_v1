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
        page.putArray("questions").add(objectMapper.createObjectNode()
                .put("question_id", "Q-" + Instant.now().toEpochMilli())
                .put("question_text_raw", "Mock question text")
                .put("student_answer_raw", "Mock answer")
                .put("confidence", 0.95));
        ObjectNode result = objectMapper.createObjectNode();
        result.putArray("pages").add(page);
        return new OcrDtos.FastApiResponse(
                requestId != null ? requestId : UUID.randomUUID().toString(),
                result
        );
    }
}
