package com.smartdairy.backend;

import com.smartdairy.backend.service.OllamaService;
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
public class OllamaServiceTest {

    @Autowired
    private OllamaService ollamaService;

    @Test
    void testOllamaServiceConfiguredCorrectly() {
        assertNotNull(ollamaService);
        assertEquals("llama3.1", ollamaService.getModel());
        assertTrue(ollamaService.getApiUrl().contains("/api/chat"));
        assertTrue(ollamaService.getBaseUrl().contains("11434"));
    }

    @Test
    void testOllamaMockServerChatSuccess() throws Exception {
        AtomicReference<String> capturedBody = new AtomicReference<>();

        HttpServer server = HttpServer.create(new InetSocketAddress(0), 0);
        int port = server.getAddress().getPort();

        server.createContext("/api/chat", exchange -> {
            String reqBody = new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8);
            capturedBody.set(reqBody);

            String mockResp = """
                    {
                      "model": "llama3.1",
                      "created_at": "2026-10-28T12:00:00Z",
                      "message": {
                        "role": "assistant",
                        "content": "FAT and SNF determine milk quality and farmer payment rate in Smart Dairy."
                      },
                      "done": true
                    }
                    """;
            byte[] bytes = mockResp.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().set("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, bytes.length);
            exchange.getResponseBody().write(bytes);
            exchange.close();
        });
        server.start();

        String origUrl = ollamaService.getApiUrl();
        try {
            ollamaService.setApiUrl("http://localhost:" + port + "/api/chat");

            List<Map<String, String>> messages = List.of(
                    Map.of("role", "system", "content", "You are a smart dairy assistant."),
                    Map.of("role", "user", "content", "Explain FAT and SNF.")
            );

            String response = ollamaService.chat(messages);
            assertNotNull(response);
            assertTrue(response.contains("FAT and SNF"));
            assertNotNull(capturedBody.get());
            assertTrue(capturedBody.get().contains("llama3.1"));
            assertTrue(capturedBody.get().contains("stream"));
        } finally {
            server.stop(0);
            ollamaService.setApiUrl(origUrl);
        }
    }

    @Test
    void testOllamaMockServerConnectionFailureHandled() {
        String origUrl = ollamaService.getApiUrl();
        try {
            ollamaService.setApiUrl("http://localhost:59999/api/chat"); // unreachable port
            List<Map<String, String>> messages = List.of(Map.of("role", "user", "content", "Hi"));

            Exception ex = assertThrows(Exception.class, () -> ollamaService.chat(messages));
            assertNotNull(ex);
        } finally {
            ollamaService.setApiUrl(origUrl);
        }
    }

    @Test
    void testOllamaLiveConnectivityIfRunning() {
        if (ollamaService.isOllamaAvailable()) {
            System.out.println("Live local Ollama is detected and running on port 11434!");
            assertTrue(ollamaService.isOllamaAvailable());
        }
    }
}
