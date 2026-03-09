package com.fastcheck.fastcheck.education;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ExamImageRepository extends JpaRepository<ExamImage, Long> {
    List<ExamImage> findByExam_IdOrderByPageOrderAsc(Long examId);

    List<ExamImage> findByExam_IdAndStatusOrderByPageOrderAsc(Long examId, ExamImageStatus status);

    Optional<ExamImage> findTopByExam_IdOrderByPageOrderDesc(Long examId);
}
