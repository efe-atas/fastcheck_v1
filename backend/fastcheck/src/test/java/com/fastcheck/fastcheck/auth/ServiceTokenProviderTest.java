package com.fastcheck.fastcheck.auth;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.fastcheck.fastcheck.config.FastApiProperties;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import org.junit.jupiter.api.Test;

class ServiceTokenProviderTest {

    @Test
    void createsHs256ServiceToken() {
        FastApiProperties properties = new FastApiProperties(
                "http://127.0.0.1:8000",
                10,
                30,
                new FastApiProperties.ServiceJwt(
                        "fastcheck-ai",
                        "change-this-service-jwt-secret-change-this-service-jwt-secret",
                        10
                )
        );
        ServiceTokenProvider provider = new ServiceTokenProvider(properties);

        String token = provider.createServiceToken();
        String header = token.split("\\.")[0];
        String json = new String(Base64.getUrlDecoder().decode(header), StandardCharsets.UTF_8);

        assertTrue(json.contains("\"alg\":\"HS256\""));
    }
}
