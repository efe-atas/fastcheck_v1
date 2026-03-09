package com.fastcheck.fastcheck.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.fastapi")
public record FastApiProperties(
        String baseUrl,
        int connectTimeoutSeconds,
        int readTimeoutSeconds,
        ServiceJwt serviceJwt
) {
    public record ServiceJwt(
            String audience,
            String secret,
            int ttlMinutes
    ) {
    }
}
