package com.fastcheck.fastcheck.auth;

import com.fastcheck.fastcheck.config.FastApiProperties;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;
import javax.crypto.SecretKey;
import org.springframework.stereotype.Component;

@Component
public class ServiceTokenProvider {

    private final FastApiProperties fastApiProperties;

    public ServiceTokenProvider(FastApiProperties fastApiProperties) {
        this.fastApiProperties = fastApiProperties;
    }

    public String createServiceToken() {
        Instant now = Instant.now();
        Instant expiry = now.plus(fastApiProperties.serviceJwt().ttlMinutes(), ChronoUnit.MINUTES);

        return Jwts.builder()
                .subject("fastcheck-spring")
                .issuer("fastcheck-spring")
                .audience().add(fastApiProperties.serviceJwt().audience()).and()
                .issuedAt(Date.from(now))
                .expiration(Date.from(expiry))
                .signWith(signingKey(), SignatureAlgorithm.HS256)
                .compact();
    }

    private SecretKey signingKey() {
        return Keys.hmacShaKeyFor(fastApiProperties.serviceJwt().secret().getBytes(StandardCharsets.UTF_8));
    }
}
