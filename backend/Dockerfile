# ==============================================================================
# SMART DAIRY APPLICATION - SPRING BOOT 3.4.3 (JAVA 23) DOCKERFILE
# Multi-stage production build optimized for Render, Railway, AWS ECS, Docker
# ==============================================================================

# STAGE 1: Build Stage
FROM eclipse-temurin:23-jdk-alpine AS builder
WORKDIR /app

# Install bash required by standard Gradle wrapper script on Alpine
RUN apk add --no-cache bash

# Copy Gradle wrapper files
COPY gradlew .
COPY gradle gradle
COPY build.gradle settings.gradle* ./

# Grant execution rights on gradlew
RUN chmod +x gradlew

# Pre-fetch Gradle dependencies
RUN ./gradlew dependencies --no-daemon || true

# Copy source code
COPY src src

# Build executable bootJar (skipping tests for fast deterministic cloud builds)
RUN ./gradlew bootJar -x test --no-daemon

# STAGE 2: Lightweight Production Runtime
FROM eclipse-temurin:23-jdk-alpine
WORKDIR /app

# Create non-root application user for production security
RUN addgroup -S smartdairy && adduser -S smartdairy -G smartdairy
USER smartdairy:smartdairy

# Copy executable jar from builder stage
COPY --from=builder /app/build/libs/smartdairy-backend-1.0.0.jar app.jar

# Dynamic port assigned by cloud platforms (Render, Railway, Heroku)
ENV PORT=8080
EXPOSE 8080

# Launch application with dynamic port mapping and secure random seed
ENTRYPOINT ["sh", "-c", "java -Dserver.port=${PORT} -Djava.security.egd=file:/dev/./urandom -jar app.jar"]
