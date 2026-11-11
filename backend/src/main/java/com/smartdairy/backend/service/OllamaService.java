package com.smartdairy.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.*;

@Service
public class OllamaService {

    private static final Logger log = LoggerFactory.getLogger(OllamaService.class);

    @Value("${ollama.api-url:http://127.0.0.1:11434/api/chat}")
    private String apiUrl;

    @Value("${ollama.base-url:http://127.0.0.1:11434}")
    private String baseUrl;

    @Value("${ollama.model:llama3.1}")
    private String model;

    @Value("${ollama.timeout-seconds:90}")
    private int timeoutSeconds;

    @Value("${ollama.temperature:0.3}")
    private double temperature;

    @Value("${ollama.max-tokens:350}")
    private int maxTokens;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    @PostConstruct
    public void init() {
        log.info("[OllamaService] Initialized with endpoint: {}, model: {}, timeout: {}s",
                apiUrl, model, timeoutSeconds);
    }

    /**
     * Checks whether the local Ollama instance is reachable and healthy.
     */
    public boolean isOllamaAvailable() {
        try {
            String checkUrl = baseUrl.replaceAll("/+$", "") + "/api/tags";
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(checkUrl))
                    .timeout(Duration.ofSeconds(3))
                    .GET()
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            return response.statusCode() == 200;
        } catch (Exception e) {
            log.debug("[OllamaService] Health check failed: {}", e.getMessage());
            return false;
        }
    }

    /**
     * Sends a chat completion request to Ollama's /api/chat endpoint.
     *
     * @param messages List of maps with "role" and "content"
     * @return Model's generated text answer
     * @throws Exception on network, timeout, or parsing error
     */
    public String chat(List<Map<String, String>> messages) throws Exception {
        if (messages == null || messages.isEmpty()) {
            throw new IllegalArgumentException("Messages list cannot be empty for Ollama chat");
        }

        Map<String, Object> payload = new HashMap<>();
        payload.put("model", model);
        payload.put("messages", messages);
        payload.put("stream", false);

        Map<String, Object> options = new HashMap<>();
        options.put("temperature", temperature);
        options.put("num_predict", maxTokens > 0 ? maxTokens : 350);
        payload.put("options", options);

        String jsonBody = objectMapper.writeValueAsString(payload);

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(apiUrl))
                .header("Content-Type", "application/json")
                .timeout(Duration.ofSeconds(timeoutSeconds))
                .POST(HttpRequest.BodyPublishers.ofString(jsonBody))
                .build();

        long startTime = System.currentTimeMillis();
        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        long elapsed = System.currentTimeMillis() - startTime;

        if (response.statusCode() != 200) {
            log.error("[OllamaService] HTTP error {}: {}", response.statusCode(), response.body());
            throw new RuntimeException("Ollama API returned HTTP " + response.statusCode() + ": " + response.body());
        }

        JsonNode root = objectMapper.readTree(response.body());
        JsonNode messageNode = root.path("message");
        if (!messageNode.isMissingNode()) {
            String reply = messageNode.path("content").asText();
            if (reply != null && !reply.isBlank()) {
                log.info("[OllamaService] Completed in {}ms via model '{}'", elapsed, model);
                return reply.trim();
            }
        }

        // Alternative Ollama response format (response field for generate endpoint)
        JsonNode responseNode = root.path("response");
        if (!responseNode.isMissingNode() && !responseNode.asText().isBlank()) {
            log.info("[OllamaService] Completed in {}ms via model '{}'", elapsed, model);
            return responseNode.asText().trim();
        }

        throw new RuntimeException("Empty response received from Ollama model " + model);
    }

    public String getApiUrl() {
        return apiUrl;
    }

    public void setApiUrl(String apiUrl) {
        this.apiUrl = apiUrl;
    }

    public String getBaseUrl() {
        return baseUrl;
    }

    public void setBaseUrl(String baseUrl) {
        this.baseUrl = baseUrl;
    }

    public String getModel() {
        return model;
    }

    public void setModel(String model) {
        this.model = model;
    }

    public int getTimeoutSeconds() {
        return timeoutSeconds;
    }

    public void setTimeoutSeconds(int timeoutSeconds) {
        this.timeoutSeconds = timeoutSeconds;
    }

    public double getTemperature() {
        return temperature;
    }

    public void setTemperature(double temperature) {
        this.temperature = temperature;
    }
}
