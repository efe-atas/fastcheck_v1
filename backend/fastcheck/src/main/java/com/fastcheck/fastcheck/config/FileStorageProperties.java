package com.fastcheck.fastcheck.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.files")
public record FileStorageProperties(
        String storagePath,
        String publicBaseUrl
) {
}
