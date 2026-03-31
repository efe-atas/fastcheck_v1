package com.fastcheck.fastcheck.auth;

import com.fastcheck.fastcheck.user.Role;
import com.fastcheck.fastcheck.user.UserAccount;
import com.fastcheck.fastcheck.user.UserRepository;
import com.fastcheck.fastcheck.auth.JwtTokenProvider;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class AuthControllerIntegrationTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwtTokenProvider jwtTokenProvider;

    @Autowired
    private UserRepository userRepository;

    @Test
    void adminCanProvisionUsersViaAuthEndpoint() throws Exception {
        UserAccount admin = saveUser("prov-admin@fastcheck.local", "Prov Admin", Role.ROLE_ADMIN);

        String body = """
                {
                  "fullName": "Teacher Demo",
                  "email": "teacher-demo@fastcheck.local",
                  "role": "ROLE_TEACHER"
                }
                """;

        mockMvc.perform(post("/auth/admin/users")
                        .header("Authorization", bearerToken(admin))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.userId").exists())
                .andExpect(jsonPath("$.role").value("ROLE_TEACHER"))
                .andExpect(jsonPath("$.initialPassword").isNotEmpty());
    }

    @Test
    void nonAdminCannotProvisionUsers() throws Exception {
        UserAccount teacher = saveUser("prov-teacher@fastcheck.local", "Prov Teacher", Role.ROLE_TEACHER);

        String body = """
                {
                  "fullName": "Parent Demo",
                  "email": "parent-demo@fastcheck.local",
                  "role": "ROLE_PARENT"
                }
                """;

        mockMvc.perform(post("/auth/admin/users")
                        .header("Authorization", bearerToken(teacher))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isForbidden());
    }

    private UserAccount saveUser(String email, String fullName, Role role) {
        UserAccount user = new UserAccount();
        user.setEmail(email);
        user.setFullName(fullName);
        user.setPasswordHash("noop-password");
        user.setRole(role);
        return userRepository.save(user);
    }

    private String bearerToken(UserAccount user) {
        return "Bearer " + jwtTokenProvider.createAccessToken(
                user.getId(),
                user.getEmail(),
                user.getRole().name()
        );
    }
}
