package com.fastcheck.fastcheck.education;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.when;

import com.fastcheck.fastcheck.common.ApiException;
import com.fastcheck.fastcheck.user.Role;
import com.fastcheck.fastcheck.user.UserAccount;
import com.fastcheck.fastcheck.user.UserRepository;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.test.util.ReflectionTestUtils;

class AdminEducationServiceTest {

    @Mock
    private EducationAccessService accessService;
    @Mock
    private SchoolRepository schoolRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private ParentStudentLinkRepository parentStudentLinkRepository;

    private AdminEducationService service;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        service = new AdminEducationService(accessService, schoolRepository, userRepository, parentStudentLinkRepository);
    }

    @Test
    void parentCanViewOwnStudents() {
        UserAccount current = new UserAccount();
        ReflectionTestUtils.setField(current, "id", 10L);
        current.setRole(Role.ROLE_PARENT);
        when(accessService.currentUser()).thenReturn(current);

        UserAccount parent = new UserAccount();
        ReflectionTestUtils.setField(parent, "id", 10L);
        parent.setRole(Role.ROLE_PARENT);
        when(userRepository.findById(10L)).thenReturn(Optional.of(parent));
        ParentStudentLink link = new ParentStudentLink();
        UserAccount student = new UserAccount();
        ReflectionTestUtils.setField(student, "id", 42L);
        student.setFullName("Student");
        student.setEmail("student@fastcheck.demo");
        link.setParent(parent);
        link.setStudent(student);
        when(parentStudentLinkRepository.findByParent_IdOrderByCreatedAtDesc(10L))
                .thenReturn(List.of(link));

        List<EducationDtos.ParentStudentView> result = service.listParentStudents(10L);

        assertEquals(1, result.size());
        assertEquals("Student", result.get(0).fullName());
    }

    @Test
    void parentCannotViewAnotherParentsStudents() {
        UserAccount current = new UserAccount();
        ReflectionTestUtils.setField(current, "id", 11L);
        current.setRole(Role.ROLE_PARENT);
        when(accessService.currentUser()).thenReturn(current);
        ApiException ex = assertThrows(ApiException.class, () -> service.listParentStudents(10L));
        assertEquals("forbidden", ex.getMessage());
    }
}
