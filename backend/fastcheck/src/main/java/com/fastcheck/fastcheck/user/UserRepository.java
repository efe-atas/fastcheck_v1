package com.fastcheck.fastcheck.user;

import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<UserAccount, Long> {
    Optional<UserAccount> findByEmail(String email);

    boolean existsByEmail(String email);

    Page<UserAccount> findBySchoolClass_IdAndRoleAndFullNameContainingIgnoreCaseOrderByFullNameAsc(
            Long classId, Role role, String fullName, Pageable pageable);
}
