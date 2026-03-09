package com.fastcheck.fastcheck.ocr;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface OcrJobRepository extends JpaRepository<OcrJob, UUID> {
    List<OcrJob> findByUser_IdOrderByCreatedAtDesc(Long userId);

    Optional<OcrJob> findByJobIdAndUser_Id(UUID jobId, Long userId);

    List<OcrJob> findByExamImage_Exam_IdOrderByCreatedAtAsc(Long examId);
}
