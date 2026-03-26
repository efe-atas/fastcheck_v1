package com.fastcheck.fastcheck.education;

import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface SchoolRepository extends JpaRepository<School, Long> {
    Optional<School> findByNameIgnoreCase(String name);

    @Query("""
            select s
            from School s
            where lower(s.name) like lower(concat('%', :q, '%'))
            order by s.name asc
            """)
    Page<School> searchByName(@Param("q") String q, Pageable pageable);
}
