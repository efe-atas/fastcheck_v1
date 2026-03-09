package com.fastcheck.fastcheck.education;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface QuestionRepository extends JpaRepository<Question, Long> {
    List<Question> findByExam_IdOrderByPageNumberAscQuestionOrderAsc(Long examId);

    void deleteByExam_Id(Long examId);
}
