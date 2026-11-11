package com.smartdairy.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;

@Service
public class OnlineKnowledgeService {

    private static final Logger log = LoggerFactory.getLogger(OnlineKnowledgeService.class);

    @Value("${online-knowledge.enabled:true}")
    private boolean enabled = true;

    @Value("${online-knowledge.timeout-seconds:6}")
    private int timeoutSeconds = 6;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(4))
            .build();

    /**
     * Searches online sources (DuckDuckGo Instant Answer API & Wikipedia REST API)
     * for real-time external online knowledge to augment the AI model's context.
     *
     * @param query The user's question
     * @return Formatted online knowledge text, or empty string if not applicable.
     */
    public String searchOnlineKnowledge(String query) {
        if (!enabled || query == null || query.isBlank()) {
            return "";
        }

        String clean = query.trim();
        // Skip queries that are strictly internal app navigation commands
        if (isInternalAppQuery(clean)) {
            return "";
        }

        StringBuilder knowledge = new StringBuilder();

        // 1. DuckDuckGo Instant Knowledge API
        try {
            String ddgUrl = "https://api.duckduckgo.com/?q=" +
                    URLEncoder.encode(clean, StandardCharsets.UTF_8) +
                    "&format=json&no_html=1&skip_disambig=1";

            HttpRequest req = HttpRequest.newBuilder()
                    .uri(URI.create(ddgUrl))
                    .header("User-Agent", "SmartDairyAI/1.0 (Windows NT 10.0; Win64; x64)")
                    .timeout(Duration.ofSeconds(timeoutSeconds))
                    .GET()
                    .build();

            HttpResponse<String> resp = httpClient.send(req, HttpResponse.BodyHandlers.ofString());
            if (resp.statusCode() == 200 && resp.body() != null && !resp.body().isBlank()) {
                JsonNode root = objectMapper.readTree(resp.body());
                String abstractText = root.path("AbstractText").asText("");
                String heading = root.path("Heading").asText("");
                if (!abstractText.isBlank()) {
                    knowledge.append("### Online Knowledge (Live Web Summary):\n");
                    if (!heading.isBlank()) {
                        knowledge.append("**Topic:** ").append(heading).append("\n");
                    }
                    knowledge.append(abstractText).append("\n\n");
                } else {
                    JsonNode related = root.path("RelatedTopics");
                    if (related.isArray() && related.size() > 0) {
                        for (int i = 0; i < Math.min(2, related.size()); i++) {
                            String text = related.get(i).path("Text").asText("");
                            if (!text.isBlank()) {
                                if (knowledge.length() == 0) {
                                    knowledge.append("### Online Knowledge Context:\n");
                                }
                                knowledge.append("- ").append(text).append("\n");
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            log.debug("[OnlineKnowledgeService] DDG search skipped: {}", e.getMessage());
        }

        // 2. Wikipedia Summary if DDG had no abstract
        if (knowledge.length() == 0) {
            try {
                String wikiQuery = extractMainKeyword(clean);
                if (!wikiQuery.isBlank()) {
                    String wikiUrl = "https://en.wikipedia.org/api/rest_v1/page/summary/" +
                            URLEncoder.encode(wikiQuery.replace(' ', '_'), StandardCharsets.UTF_8);

                    HttpRequest req = HttpRequest.newBuilder()
                            .uri(URI.create(wikiUrl))
                            .header("User-Agent", "SmartDairyAI/1.0 (support@smartdairy.local)")
                            .timeout(Duration.ofSeconds(timeoutSeconds))
                            .GET()
                            .build();

                    HttpResponse<String> resp = httpClient.send(req, HttpResponse.BodyHandlers.ofString());
                    if (resp.statusCode() == 200 && resp.body() != null) {
                        JsonNode root = objectMapper.readTree(resp.body());
                        String title = root.path("title").asText("");
                        String extract = root.path("extract").asText("");
                        if (!extract.isBlank()) {
                            knowledge.append("### Online Knowledge (Wikipedia Live):\n");
                            if (!title.isBlank()) {
                                knowledge.append("**Subject:** ").append(title).append("\n");
                            }
                            knowledge.append(extract).append("\n\n");
                        }
                    }
                }
            } catch (Exception e) {
                log.debug("[OnlineKnowledgeService] Wikipedia lookup skipped: {}", e.getMessage());
            }
        }

        return knowledge.toString().trim();
    }

    /**
     * Fallback online LLM via Pollinations AI GET endpoint when no local model or API key is set.
     */
    public String fetchFreeOnlineLlmReply(String prompt, String systemContext) {
        try {
            String combined = (systemContext != null ? systemContext + "\n\nUser Question: " : "") + prompt;
            if (combined.length() > 600) {
                combined = combined.substring(0, 600);
            }
            String url = "https://text.pollinations.ai/" +
                    URLEncoder.encode(combined, StandardCharsets.UTF_8) +
                    "?model=openai";

            HttpRequest req = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .header("User-Agent", "SmartDairyAI/1.0")
                    .timeout(Duration.ofSeconds(12))
                    .GET()
                    .build();

            HttpResponse<String> resp = httpClient.send(req, HttpResponse.BodyHandlers.ofString());
            if (resp.statusCode() == 200 && resp.body() != null && !resp.body().isBlank()) {
                return resp.body().trim();
            }
        } catch (Exception e) {
            log.warn("[OnlineKnowledgeService] Online LLM fallback failed: {}", e.getMessage());
        }
        return null;
    }

    private boolean isInternalAppQuery(String q) {
        String lower = q.toLowerCase();
        return lower.contains("detailed bill")
                || lower.contains("milk passbook")
                || lower.contains("rate chart")
                || lower.contains("10-day")
                || lower.contains("customer list")
                || lower.contains("dispatch tanker")
                || lower.contains("app version");
    }

    private String extractMainKeyword(String query) {
        String clean = query.replaceAll("(?i)^(what is|who is|explain|tell me about|how to|why is|what are|where is)\\s+", "").trim();
        clean = clean.replaceAll("[?!.,;]+$", "").trim();
        return clean.length() > 50 ? clean.substring(0, 50).trim() : clean;
    }
}
