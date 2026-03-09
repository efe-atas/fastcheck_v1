package com.fastcheck.fastcheck.education;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SchoolClassRepository extends JpaRepository<SchoolClass, Long> {
    List<SchoolClass> findByTeacher_Id(Long teacherId);

    List<SchoolClass> findBySchool_Id(Long schoolId);
}
