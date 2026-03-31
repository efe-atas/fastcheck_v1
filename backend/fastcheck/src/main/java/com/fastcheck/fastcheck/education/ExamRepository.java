package com.fastcheck.fastcheck.education;

import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ExamRepository extends JpaRepository<Exam, Long> {
    List<Exam> findBySchoolClass_IdOrderByCreatedAtDesc(Long classId);

    List<Exam> findByTeacher_IdOrderByCreatedAtDesc(Long teacherId);

    Optional<Exam> findByIdAndTeacher_Id(Long id, Long teacherId);

    long countBySchoolClass_Id(Long classId);

    long countBySchoolClass_IdAndStatus(Long classId, ExamStatus status);

    long countByTeacher_Id(Long teacherId);

    long countByTeacher_IdAndStatus(Long teacherId, ExamStatus status);

    List<Exam> findTop5ByTeacher_IdOrderByCreatedAtDesc(Long teacherId);

    List<Exam> findTop5BySchoolClass_IdOrderByCreatedAtDesc(Long classId);

    Optional<Exam> findTop1BySchoolClass_IdOrderByCreatedAtDesc(Long classId);

    Page<Exam> findBySchoolClass_IdOrderByCreatedAtDesc(Long classId, Pageable pageable);

    Page<Exam> findBySchoolClass_IdAndStatusOrderByCreatedAtDesc(Long classId, ExamStatus status, Pageable pageable);
}
