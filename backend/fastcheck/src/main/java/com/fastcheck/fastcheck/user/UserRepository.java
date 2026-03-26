package com.fastcheck.fastcheck.user;

import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserRepository extends JpaRepository<UserAccount, Long> {
    Optional<UserAccount> findByEmail(String email);

    Optional<UserAccount> findByEmailIgnoreCase(String email);

    boolean existsByEmail(String email);

    @Query("""
            select u
            from UserAccount u
            where (:role is null or u.role = :role)
              and (
                    lower(u.email) like lower(concat('%', :q, '%'))
                    or lower(u.fullName) like lower(concat('%', :q, '%'))
              )
            order by u.fullName asc
            """)
    Page<UserAccount> searchAdminUsers(
            @Param("role") Role role,
            @Param("q") String q,
            Pageable pageable);

    Page<UserAccount> findBySchoolClass_IdAndRoleAndFullNameContainingIgnoreCaseOrderByFullNameAsc(
            Long classId, Role role, String fullName, Pageable pageable);
}
