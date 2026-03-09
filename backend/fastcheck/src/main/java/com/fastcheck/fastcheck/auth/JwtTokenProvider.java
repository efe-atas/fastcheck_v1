package com.fastcheck.fastcheck.auth;

import com.fastcheck.fastcheck.config.JwtProperties;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;
import javax.crypto.SecretKey;
import org.springframework.stereotype.Component;

@Component
public class JwtTokenProvider {

    private final JwtProperties properties;

    public JwtTokenProvider(JwtProperties properties) {
        this.properties = properties;
    }

    public String createAccessToken(Long userId, String email, String role) {
        Instant now = Instant.now();
        Instant expiry = now.plus(properties.accessTokenMinutes(), ChronoUnit.MINUTES);

        return Jwts.builder()
                .subject(email)
                .issuer(properties.issuer())
                .claim("uid", userId)
                .claim("role", role)
                .claim("token_type", "access")
                .issuedAt(Date.from(now))
                .expiration(Date.from(expiry))
                .signWith(signingKey())
                .compact();
    }

    public String createRefreshToken(Long userId, String email) {
        Instant now = Instant.now();
        Instant expiry = now.plus(properties.refreshTokenDays(), ChronoUnit.DAYS);

        return Jwts.builder()
                .subject(email)
                .issuer(properties.issuer())
                .claim("uid", userId)
                .claim("token_type", "refresh")
                .issuedAt(Date.from(now))
                .expiration(Date.from(expiry))
                .signWith(signingKey())
                .compact();
    }

    public Claims parseAndValidate(String token) {
        return Jwts.parser()
                .verifyWith(signingKey())
                .requireIssuer(properties.issuer())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    private SecretKey signingKey() {
        return Keys.hmacShaKeyFor(properties.secret().getBytes(StandardCharsets.UTF_8));
    }
}
