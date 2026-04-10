package com.fastcheck.fastcheck.education;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface QuestionRepository extends JpaRepository<Question, Long> {
    @EntityGraph(attributePaths = "examImage")
    List<Question> findByExam_IdOrderByPageNumberAscQuestionOrderAsc(Long examId);

    List<Question> findByExamImage_IdOrderByQuestionOrderAsc(Long examImageId);

    Optional<Question> findByIdAndExam_Id(Long id, Long examId);

    @Transactional
    void deleteByExamImage_Id(Long examImageId);

    @Transactional
    void deleteByExam_Id(Long examId);
}
