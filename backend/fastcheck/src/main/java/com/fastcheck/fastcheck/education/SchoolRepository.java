package com.fastcheck.fastcheck.education;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SchoolRepository extends JpaRepository<School, Long> {
    Optional<School> findByNameIgnoreCase(String name);
}
