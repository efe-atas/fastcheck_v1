package com.fastcheck.fastcheck.education;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

import com.fastcheck.fastcheck.user.Role;
import com.fastcheck.fastcheck.user.UserAccount;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

class StudentNameMatcherServiceTest {

    private StudentNameMatcherService service;

    @BeforeEach
    void setUp() {
        service = new StudentNameMatcherService();
    }

    @Test
    void matchesExactStudentNameIgnoringTurkishCharacters() {
        UserAccount student = student(1L, "Çağrı Işık");

        StudentNameMatcherService.StudentNameMatchResult result =
                service.match("Cagri Isik", List.of(student));

        assertEquals(StudentMatchStatus.MATCHED, result.status());
        assertEquals(student.getId(), result.matchedStudentId());
        assertEquals(student.getFullName(), result.matchedStudentName());
    }

    @Test
    void marksAmbiguousWhenMultipleStudentsShareSameNormalizedName() {
        UserAccount first = student(1L, "Ali Veli");
        UserAccount second = student(2L, "Ali   Veli");

        StudentNameMatcherService.StudentNameMatchResult result =
                service.match("ali veli", List.of(first, second));

        assertEquals(StudentMatchStatus.AMBIGUOUS, result.status());
        assertNull(result.matchedStudentId());
        assertEquals(List.of(1L, 2L), result.candidateStudentIds());
    }

    @Test
    void staysUnmatchedForWeakSimilarity() {
        UserAccount student = student(1L, "Ayse Kaya");

        StudentNameMatcherService.StudentNameMatchResult result =
                service.match("Mehmet Demir", List.of(student));

        assertEquals(StudentMatchStatus.UNMATCHED, result.status());
        assertNull(result.matchedStudentId());
    }

    private UserAccount student(Long id, String fullName) {
        UserAccount student = new UserAccount();
        ReflectionTestUtils.setField(student, "id", id);
        student.setFullName(fullName);
        student.setRole(Role.ROLE_STUDENT);
        return student;
    }
}
