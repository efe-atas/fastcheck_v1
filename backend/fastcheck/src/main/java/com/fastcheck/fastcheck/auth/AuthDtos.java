package com.fastcheck.fastcheck.auth;

import com.fastcheck.fastcheck.user.Role;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class AuthDtos {

    public record RegisterRequest(
            @NotBlank String fullName,
            @NotBlank @Email String email,
            @NotBlank @Size(min = 8, max = 120) String password,
            Role role
    ) {
    }

    public record LoginRequest(
            @NotBlank @Email String email,
            @NotBlank String password
    ) {
    }

    public record RefreshRequest(
            @NotBlank String refreshToken
    ) {
    }

    public record AuthResponse(
            Long userId,
            String email,
            String accessToken,
            String refreshToken
    ) {
    }
}
