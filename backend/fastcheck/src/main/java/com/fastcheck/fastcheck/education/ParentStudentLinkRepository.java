package com.fastcheck.fastcheck.education;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ParentStudentLinkRepository extends JpaRepository<ParentStudentLink, Long> {
    List<ParentStudentLink> findByParent_Id(Long parentId);

    List<ParentStudentLink> findByParent_IdOrderByCreatedAtDesc(Long parentId);

    boolean existsByParent_IdAndStudent_Id(Long parentId, Long studentId);
}
