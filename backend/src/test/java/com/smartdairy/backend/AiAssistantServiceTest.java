package com.smartdairy.backend;

import com.smartdairy.backend.service.AiAssistantService;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicReference;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
public class AiAssistantServiceTest {

    @Autowired
    private AiAssistantService aiAssistantService;

    @Test
    void testSystemPromptContainsComprehensiveDomainKnowledge() {
        String prompt = AiAssistantService.SMART_DAIRY_SYSTEM_PROMPT;
        assertNotNull(prompt);
        assertTrue(prompt.contains("DAIRY_OWNER"));
        assertTrue(prompt.contains("MEMBER (Farmer)"));
        assertTrue(prompt.contains("M001"));
        assertTrue(prompt.contains("Rate (₹/L)"));
        assertTrue(prompt.contains("10-Day Cooperative Cycles"));
        assertTrue(prompt.contains("MongoDB"));
        assertTrue(prompt.contains("Marathi"));
        assertTrue(prompt.contains("BLE"));
    }

    @Test
    void testUnconfiguredLlmReturnsHonestSetupInstructionsForCustomQuestion() {
        aiAssistantService.setOllamaEnabled(false);
        try {
            Map<String, Object> response = aiAssistantService.generateChatResponse(
                    "Can you write a poem about artificial intelligence in agriculture?",
                    "DAIRY_OWNER",
                    "Home",
                    "en",
                    List.of()
            );

            assertNotNull(response);
            assertEquals(false, response.get("isConfigured"));
            assertEquals("NOT_CONFIGURED", response.get("status"));
            assertEquals(false, response.get("isLlmGenerated"));

            String reply = (String) response.get("reply");
            assertNotNull(reply);
            assertTrue(reply.contains("Conversational AI Model Not Configured"));
            assertTrue(reply.contains("OPENAI_API_KEY"));
            assertTrue(reply.contains("Ollama"));
        } finally {
            aiAssistantService.setOllamaEnabled(true);
        }
    }

    @Test
    void testUnconfiguredLlmReturnsVerifiedFeatureGuideForDomainQuestion() {
        aiAssistantService.setOllamaEnabled(false);
        try {
            Map<String, Object> response = aiAssistantService.generateChatResponse(
                    "detailed bill",
                    "DAIRY_OWNER",
                    "Dashboard",
                    "en",
                    List.of()
            );

            assertNotNull(response);
            assertEquals(false, response.get("isConfigured"));
            assertEquals("LOCAL_FALLBACK", response.get("status"));
            assertEquals(false, response.get("isLlmGenerated"));

            String reply = (String) response.get("reply");
            assertNotNull(reply);
            assertTrue(reply.contains("Detailed Bill Screen Guide"));
            assertTrue(reply.contains("Shift Collection Records"));
            assertTrue(reply.contains("Final Net Payable"));
            assertTrue(reply.contains("Smart Dairy App Knowledge"));
        } finally {
            aiAssistantService.setOllamaEnabled(true);
        }
    }

    @Test
    void testUnconfiguredLlmInMarathiReturnsMarathiSetupInstructions() {
        aiAssistantService.setOllamaEnabled(false);
        try {
            Map<String, Object> response = aiAssistantService.generateChatResponse(
                    "फ्रान्सची राजधानी काय आहे?",
                    "DAIRY_OWNER",
                    "Home",
                    "mr",
                    List.of()
            );

            assertNotNull(response);
            assertEquals(false, response.get("isConfigured"));
            assertEquals("NOT_CONFIGURED", response.get("status"));

            String reply = (String) response.get("reply");
            assertNotNull(reply);
            assertTrue(reply.contains("थेट AI सहाय्यक सध्या अनुपलब्ध आहे") || reply.contains("Large Language Model"));
            assertTrue(reply.contains("OpenAI") || reply.contains("Ollama"));
        } finally {
            aiAssistantService.setOllamaEnabled(true);
        }
    }

    @Test
    void testCheckAiStatusEndpointReportsCorrectProvider() {
        aiAssistantService.setOllamaEnabled(false);
        try {
            assertEquals("openai", aiAssistantService.getProvider());
            assertEquals("gpt-4o-mini", aiAssistantService.getModel());
        } finally {
            aiAssistantService.setOllamaEnabled(true);
        }
    }

    @Test
    void testLiveOllamaIntegrationStatusWhenOnline() {
        if (aiAssistantService.isLlmConfigured()) {
            assertEquals("ollama", aiAssistantService.getProvider());
            assertEquals("llama3.1", aiAssistantService.getModel());
        }
    }

    @Test
    void testLiveOpenAiApiCallSuccessWithMockServer() throws Exception {
        AtomicReference<String> capturedAuth = new AtomicReference<>();
        AtomicReference<String> capturedBody = new AtomicReference<>();

        HttpServer server = HttpServer.create(new InetSocketAddress(0), 0);
        int port = server.getAddress().getPort();

        server.createContext("/chat/completions", exchange -> {
            capturedAuth.set(exchange.getRequestHeaders().getFirst("Authorization"));
            String reqBody = new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8);
            capturedBody.set(reqBody);

            String mockResp = """
                    {
                      "choices": [
                        {
                          "message": {
                            "role": "assistant",
                            "content": "The Detailed Bill screen lets you inspect shift records and deductions."
                          }
                        }
                      ]
                    }
                    """;
            byte[] bytes = mockResp.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().set("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, bytes.length);
            exchange.getResponseBody().write(bytes);
            exchange.close();
        });
        server.start();

        String origUrl = aiAssistantService.getBaseUrl();

        try {
            aiAssistantService.setApiKey("sk-test-live-mock-key");
            aiAssistantService.setBaseUrl("http://localhost:" + port);

            assertTrue(aiAssistantService.isLlmConfigured());

            Map<String, Object> res = aiAssistantService.generateChatResponse(
                    "detailed bill",
                    "DAIRY_OWNER",
                    "Billing",
                    "en",
                    List.of(Map.of("role", "user", "content", "Hello"))
            );

            assertNotNull(res);
            assertEquals("SUCCESS", res.get("status"));
            assertEquals(true, res.get("isLlmGenerated"));
            assertEquals(true, res.get("isConfigured"));
            assertTrue(((String) res.get("reply")).contains("Detailed Bill screen lets you inspect shift records"));

            // Verify the Authorization header was correctly transmitted
            assertEquals("Bearer sk-test-live-mock-key", capturedAuth.get());

            // Verify prompt and context reached the OpenAI payload
            assertNotNull(capturedBody.get());
            assertTrue(capturedBody.get().contains("SMART DAIRY APPLICATION ARCHITECTURE"));
            assertTrue(capturedBody.get().contains("detailed bill"));
        } finally {
            server.stop(0);
            aiAssistantService.setApiKey("");
            aiAssistantService.setBaseUrl(origUrl);
        }
    }

    @Test
    void testLiveOpenAiApiAuthenticationFailure401() throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(0), 0);
        int port = server.getAddress().getPort();

        server.createContext("/chat/completions", exchange -> {
            String errorResp = """
                    {
                      "error": {
                        "message": "Incorrect API key provided: sk-invalid. (401 Unauthorized)",
                        "type": "invalid_request_error",
                        "code": "invalid_api_key"
                      }
                    }
                    """;
            byte[] bytes = errorResp.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().set("Content-Type", "application/json");
            exchange.sendResponseHeaders(401, bytes.length);
            exchange.getResponseBody().write(bytes);
            exchange.close();
        });
        server.start();

        String origUrl = aiAssistantService.getBaseUrl();
        try {
            aiAssistantService.setApiKey("sk-invalid-key");
            aiAssistantService.setBaseUrl("http://localhost:" + port);

            Map<String, Object> res = aiAssistantService.generateChatResponse(
                    "how to connect BLE?",
                    "DAIRY_OWNER",
                    "Collection",
                    "en",
                    List.of()
            );

            assertNotNull(res);
            assertEquals("ERROR", res.get("status"));
            assertEquals(false, res.get("isLlmGenerated"));
            String reply = (String) res.get("reply");
            assertTrue(reply.contains("401 Unauthorized") || reply.contains("Authentication Failed"));
        } finally {
            server.stop(0);
            aiAssistantService.setApiKey("");
            aiAssistantService.setBaseUrl(origUrl);
        }
    }

    @Test
    void testLiveOpenAiApiRateLimitFailure429() throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(0), 0);
        int port = server.getAddress().getPort();

        server.createContext("/chat/completions", exchange -> {
            String errorResp = """
                    {
                      "error": {
                        "message": "You exceeded your current quota (429 Rate limit exceeded)",
                        "type": "insufficient_quota",
                        "code": "insufficient_quota"
                      }
                    }
                    """;
            byte[] bytes = errorResp.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().set("Content-Type", "application/json");
            exchange.sendResponseHeaders(429, bytes.length);
            exchange.getResponseBody().write(bytes);
            exchange.close();
        });
        server.start();

        String origUrl = aiAssistantService.getBaseUrl();
        try {
            aiAssistantService.setApiKey("sk-quota-exceeded-key");
            aiAssistantService.setBaseUrl("http://localhost:" + port);

            Map<String, Object> res = aiAssistantService.generateChatResponse(
                    "why is my yield low?",
                    "DAIRY_OWNER",
                    "Home",
                    "en",
                    List.of()
            );

            assertNotNull(res);
            assertEquals("ERROR", res.get("status"));
            assertEquals(false, res.get("isLlmGenerated"));
            String reply = (String) res.get("reply");
            assertTrue(reply.contains("429") || reply.contains("Quota Exceeded"));
        } finally {
            server.stop(0);
            aiAssistantService.setApiKey("");
            aiAssistantService.setBaseUrl(origUrl);
        }
    }
}
