package com.fastcheck.fastcheck.education;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.transaction.annotation.Transactional;

public interface StudentExamResultRepository extends JpaRepository<StudentExamResult, Long> {
    List<StudentExamResult> findByExam_IdOrderByAwardedPointsDescStudentNameAsc(Long examId);

    Optional<StudentExamResult> findByExam_IdAndStudentId(Long examId, Long studentId);

    @Transactional
    void deleteByExam_Id(Long examId);
}
