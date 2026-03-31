package com.fastcheck.fastcheck.education;

import java.time.Instant;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

@Component
public class ExamOcrEventPublisher {

    private static final Logger log = LoggerFactory.getLogger(ExamOcrEventPublisher.class);

    public void publish(ExamOcrEvent event) {
        log.info("exam-ocr-event examId={} teacherId={} type={} message={}",
                event.examId(), event.teacherId(), event.type(), event.message());
    }

    public record ExamOcrEvent(
            Long examId,
            Long teacherId,
            String type,
            String message,
            Instant occurredAt
    ) {
    }
}
