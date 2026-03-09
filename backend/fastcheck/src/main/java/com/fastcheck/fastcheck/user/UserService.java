package com.fastcheck.fastcheck.user;

import com.fastcheck.fastcheck.auth.AuthDtos;
import com.fastcheck.fastcheck.auth.JwtTokenProvider;
import com.fastcheck.fastcheck.common.ApiException;
import io.jsonwebtoken.Claims;
import java.time.Instant;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;

    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder, JwtTokenProvider tokenProvider) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.tokenProvider = tokenProvider;
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
        user.setRole(Role.ROLE_STUDENT);
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

    private AuthDtos.AuthResponse issueTokens(UserAccount user) {
        String access = tokenProvider.createAccessToken(user.getId(), user.getEmail(), user.getRole().name());
        String refresh = tokenProvider.createRefreshToken(user.getId(), user.getEmail());
        return new AuthDtos.AuthResponse(user.getId(), user.getEmail(), access, refresh);
    }
}
