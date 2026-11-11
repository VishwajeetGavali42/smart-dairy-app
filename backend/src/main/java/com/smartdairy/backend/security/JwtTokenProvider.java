package com.smartdairy.backend.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.Key;
import java.util.Date;

@Component
public class JwtTokenProvider {

    @Value("${jwt.secret}")
    private String jwtSecret;

    @Value("${jwt.expiration}")
    private long jwtExpirationInMs;

    private Key getSigningKey() {
        byte[] keyBytes = jwtSecret.getBytes(StandardCharsets.UTF_8);
        return Keys.hmacShaKeyFor(keyBytes);
    }

    public String generateToken(String username, String role) {
        return generateToken(username, role, null, null);
    }

    public String generateToken(String username, String role, String memberCode, String memberId) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + jwtExpirationInMs);

        JwtBuilder builder = Jwts.builder()
                .subject(username)
                .claim("role", role)
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(getSigningKey());

        if (memberCode != null && !memberCode.isBlank()) {
            builder.claim("memberCode", memberCode);
        }
        if (memberId != null && !memberId.isBlank()) {
            builder.claim("memberId", memberId);
        }

        return builder.compact();
    }

    public String getUsernameFromJWT(String token) {
        Claims claims = getClaims(token);
        return claims.getSubject();
    }

    public String getRoleFromJWT(String token) {
        Claims claims = getClaims(token);
        return claims.get("role", String.class);
    }

    public String getMemberCodeFromJWT(String token) {
        Claims claims = getClaims(token);
        return claims.get("memberCode", String.class);
    }

    public Claims getClaims(String token) {
        return Jwts.parser()
                .setSigningKey(getSigningKey())
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    public boolean validateToken(String authToken) {
        try {
            Jwts.parser().setSigningKey(getSigningKey()).build().parseClaimsJws(authToken);
            return true;
        } catch (Exception ex) {
            return false;
        }
    }
}
