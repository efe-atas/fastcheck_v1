package com.fastcheck.fastcheck.user;

import com.fastcheck.fastcheck.auth.AuthDtos;
import com.fastcheck.fastcheck.auth.JwtTokenProvider;
import com.fastcheck.fastcheck.common.ApiException;
import com.fastcheck.fastcheck.education.EducationAccessService;
import com.fastcheck.fastcheck.education.School;
import com.fastcheck.fastcheck.education.SchoolClass;
import com.fastcheck.fastcheck.education.SchoolClassRepository;
import com.fastcheck.fastcheck.education.SchoolRepository;
import io.jsonwebtoken.Claims;
import java.time.Instant;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;
    private final EducationAccessService accessService;
    private final SchoolRepository schoolRepository;
    private final SchoolClassRepository schoolClassRepository;

    public UserService(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            JwtTokenProvider tokenProvider,
            EducationAccessService accessService,
            SchoolRepository schoolRepository,
            SchoolClassRepository schoolClassRepository
    ) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.tokenProvider = tokenProvider;
        this.accessService = accessService;
        this.schoolRepository = schoolRepository;
        this.schoolClassRepository = schoolClassRepository;
    }

    @Transactional
    public AuthDtos.AuthResponse register(AuthDtos.RegisterRequest request) {
        String email = request.email().trim().toLowerCase();
        if (userRepository.existsByEmail(email)) {
            throw new ApiException(HttpStatus.CONFLICT, "email already exists");
        }

        UserAccount user = new UserAccount();
        user.setFullName(request.fullName().trim());
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setRole(resolveRegistrationRole(request.role()));
        user = userRepository.save(user);

        return issueTokens(user);
    }

    @Transactional(readOnly = true)
    public AuthDtos.AuthResponse login(AuthDtos.LoginRequest request) {
        String email = request.email().trim().toLowerCase();
        UserAccount user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "invalid credentials"));

        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "invalid credentials");
        }

        return issueTokens(user);
    }

    @Transactional(readOnly = true)
    public AuthDtos.AuthResponse refresh(String refreshToken) {
        Claims claims;
        try {
            claims = tokenProvider.parseAndValidate(refreshToken);
        } catch (Exception exc) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "invalid refresh token");
        }

        if (!"refresh".equals(String.valueOf(claims.get("token_type")))) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "token is not refresh token");
        }

        Long userId = claims.get("uid", Number.class).longValue();
        String email = claims.getSubject();

        UserAccount user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "user not found"));
        if (!user.getEmail().equals(email)) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "refresh token user mismatch");
        }

        String access = tokenProvider.createAccessToken(user.getId(), user.getEmail(), user.getRole().name());
        String refresh = tokenProvider.createRefreshToken(user.getId(), user.getEmail());
        user.setUpdatedAt(Instant.now());

        return new AuthDtos.AuthResponse(user.getId(), user.getEmail(), access, refresh);
    }

    private static Role resolveRegistrationRole(Role requested) {
        if (requested == null) {
            return Role.ROLE_STUDENT;
        }
        if (requested == Role.ROLE_STUDENT ||
                requested == Role.ROLE_TEACHER ||
                requested == Role.ROLE_ADMIN) {
            return requested;
        }
        if (requested == Role.ROLE_PARENT) {
            throw new ApiException(HttpStatus.FORBIDDEN, "parent accounts must be provisioned by an admin");
        }
        throw new ApiException(HttpStatus.BAD_REQUEST, "invalid registration role");
    }

    private AuthDtos.AuthResponse issueTokens(UserAccount user) {
        String access = tokenProvider.createAccessToken(user.getId(), user.getEmail(), user.getRole().name());
        String refresh = tokenProvider.createRefreshToken(user.getId(), user.getEmail());
        return new AuthDtos.AuthResponse(user.getId(), user.getEmail(), access, refresh);
    }

    @Transactional
    public AuthDtos.AdminCreatedUserResponse createUserAsAdmin(AuthDtos.AdminCreateUserRequest request) {
        accessService.requireRole(Role.ROLE_ADMIN);
        String normalizedEmail = request.email().trim().toLowerCase();
        if (userRepository.existsByEmail(normalizedEmail)) {
            throw new ApiException(HttpStatus.CONFLICT, "email already exists");
        }

        Role role = request.role();
        if (role == null) {
            role = Role.ROLE_STUDENT;
        }

        String password = request.password();
        boolean generatedPassword = false;
        if (password == null || password.isBlank()) {
            password = generateTemporaryPassword();
            generatedPassword = true;
        }

        UserAccount user = new UserAccount();
        user.setFullName(request.fullName().trim());
        user.setEmail(normalizedEmail);
        user.setPasswordHash(passwordEncoder.encode(password));
        user.setRole(role);

        if (request.schoolId() != null) {
            School school = schoolRepository.findById(request.schoolId())
                    .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "school not found"));
            user.setSchool(school);
        }

        if (request.classId() != null) {
            SchoolClass schoolClass = schoolClassRepository.findById(request.classId())
                    .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "class not found"));
            user.setSchoolClass(schoolClass);
            if (user.getSchool() == null) {
                user.setSchool(schoolClass.getSchool());
            }
        }

        user.setUpdatedAt(Instant.now());
        user = userRepository.save(user);

        return new AuthDtos.AdminCreatedUserResponse(
                user.getId(),
                user.getFullName(),
                user.getEmail(),
                user.getRole().name(),
                user.getSchool() == null ? null : user.getSchool().getId(),
                user.getSchoolClass() == null ? null : user.getSchoolClass().getId(),
                generatedPassword ? password : null
        );
    }

    private String generateTemporaryPassword() {
        String random = UUID.randomUUID().toString().replace("-", "");
        return "Temp#" + random.substring(0, 10);
    }
}
