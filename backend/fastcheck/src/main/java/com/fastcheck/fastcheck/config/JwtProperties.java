package com.fastcheck.fastcheck.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.jwt")
public record JwtProperties(
        String issuer,
        int accessTokenMinutes,
        int refreshTokenDays,
        String secret
) {
}
