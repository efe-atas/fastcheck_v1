package com.fastcheck.fastcheck.user;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.when;

import com.fastcheck.fastcheck.auth.AuthDtos;
import com.fastcheck.fastcheck.auth.JwtTokenProvider;
import com.fastcheck.fastcheck.common.ApiException;
import com.fastcheck.fastcheck.education.EducationAccessService;
import com.fastcheck.fastcheck.education.SchoolClassRepository;
import com.fastcheck.fastcheck.education.SchoolRepository;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

class UserServiceTest {

    @Mock
    private UserRepository userRepository;
    @Mock
    private PasswordEncoder passwordEncoder;
    @Mock
    private JwtTokenProvider tokenProvider;
    @Mock
    private EducationAccessService accessService;
    @Mock
    private SchoolRepository schoolRepository;
    @Mock
    private SchoolClassRepository schoolClassRepository;

    private UserService userService;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        userService = new UserService(
                userRepository,
                passwordEncoder,
                tokenProvider,
                accessService,
                schoolRepository,
                schoolClassRepository
        );
    }

    @Test
    void createUserAsAdminGeneratesPasswordWhenMissing() {
        UserAccount admin = new UserAccount();
        ReflectionTestUtils.setField(admin, "id", 99L);
        admin.setRole(Role.ROLE_ADMIN);
        when(accessService.requireRole(Role.ROLE_ADMIN)).thenReturn(admin);
        when(userRepository.existsByEmail("new@fastcheck.demo")).thenReturn(false);
        when(passwordEncoder.encode(org.mockito.ArgumentMatchers.anyString())).thenAnswer(invocation -> "enc-" + invocation.getArgument(0));
        ArgumentCaptor<UserAccount> captor = ArgumentCaptor.forClass(UserAccount.class);
        when(userRepository.save(captor.capture())).thenAnswer(invocation -> {
            UserAccount saved = invocation.getArgument(0);
            ReflectionTestUtils.setField(saved, "id", 123L);
            return saved;
        });

        AuthDtos.AdminCreateUserRequest request = new AuthDtos.AdminCreateUserRequest(
                "New Teacher",
                "new@fastcheck.demo",
                Role.ROLE_TEACHER,
                null,
                null,
                null
        );

        AuthDtos.AdminCreatedUserResponse response = userService.createUserAsAdmin(request);

        assertEquals(123L, response.userId());
        assertEquals("ROLE_TEACHER", response.role());
        assertNotNull(response.initialPassword(), "initial password should be generated");
        UserAccount persisted = captor.getValue();
        assertEquals("enc-" + response.initialPassword(), persisted.getPasswordHash());
    }

    @Test
    void registerForParentRoleIsForbidden() {
        AuthDtos.RegisterRequest request = new AuthDtos.RegisterRequest(
                "Parent",
                "p@fastcheck.demo",
                "Password#1",
                Role.ROLE_PARENT
        );
        when(userRepository.existsByEmail("p@fastcheck.demo")).thenReturn(false);
        ApiException ex = assertThrows(ApiException.class, () -> userService.register(request));
        assertEquals("parent accounts must be provisioned by an admin", ex.getMessage());
    }
}
