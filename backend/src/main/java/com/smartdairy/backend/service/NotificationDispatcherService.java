package com.smartdairy.backend.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Service
public class NotificationDispatcherService {

    private static final Logger log = LoggerFactory.getLogger(NotificationDispatcherService.class);

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(5))
            .build();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${smartdairy.fcm.enabled:true}")
    private boolean fcmEnabled;

    @Value("${smartdairy.fcm.server-key:}")
    private String fcmServerKey;

    @Value("${smartdairy.fcm.project-id:smartdairy-fcm}")
    private String fcmProjectId;

    public boolean isLiveConfigured() {
        return fcmServerKey != null && !fcmServerKey.trim().isEmpty() && !fcmServerKey.contains("MOCK") && !fcmServerKey.contains("KEY_789123");
    }

    /**
     * Sends Firebase Cloud Messaging (FCM) Push Notification
     */
    public Map<String, Object> sendPushNotification(String targetTopicOrToken, String title, String body, Map<String, String> data) {
        String fcmMessageId = "FCM-MSG-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        Map<String, Object> result = new HashMap<>();
        result.put("messageId", fcmMessageId);
        result.put("recipient", targetTopicOrToken);
        result.put("title", title);
        result.put("body", body);
        result.put("payloadData", data != null ? data : Map.of());
        result.put("timestamp", System.currentTimeMillis());

        if (!fcmEnabled) {
            result.put("success", false);
            result.put("status", "DISABLED");
            result.put("live", false);
            return result;
        }

        // 1. Live FCM Dispatch
        if (isLiveConfigured()) {
            try {
                log.info("[FCM PUSH LIVE] Dispatching to {}: Title='{}', Body='{}'", targetTopicOrToken, title, body);

                Map<String, Object> payload = new HashMap<>();
                if (targetTopicOrToken.startsWith("/")) {
                    payload.put("to", targetTopicOrToken);
                } else if (targetTopicOrToken.contains("_")) {
                    payload.put("to", "/topics/" + targetTopicOrToken);
                } else {
                    payload.put("to", targetTopicOrToken);
                }

                Map<String, String> notification = new HashMap<>();
                notification.put("title", title);
                notification.put("body", body);
                payload.put("notification", notification);
                if (data != null && !data.isEmpty()) {
                    payload.put("data", data);
                }

                String json = objectMapper.writeValueAsString(payload);

                HttpRequest request = HttpRequest.newBuilder()
                        .uri(URI.create("https://fcm.googleapis.com/fcm/send"))
                        .header("Authorization", "key=" + fcmServerKey.trim())
                        .header("Content-Type", "application/json")
                        .timeout(Duration.ofSeconds(5))
                        .POST(HttpRequest.BodyPublishers.ofString(json))
                        .build();

                HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
                log.info("[FCM Response] Status: {}, Body: {}", response.statusCode(), response.body());

                result.put("success", response.statusCode() == 200);
                result.put("status", response.statusCode() == 200 ? "DISPATCHED_LIVE" : "GATEWAY_ERROR");
                result.put("live", true);
                result.put("gatewayResponse", response.body());
                return result;
            } catch (Exception e) {
                log.warn("[FCM Exception] Live push notification failed, falling back to sandbox: {}", e.getMessage());
            }
        }

        // 2. Sandbox Mock Mode (Safe demonstration mode)
        log.info("[FCM PUSH - SANDBOX MOCK] Simulated dispatch to {}: Title='{}', Body='{}'", targetTopicOrToken, title, body);
        result.put("success", true);
        result.put("status", "DISPATCHED_SANDBOX");
        result.put("live", false);
        result.put("info", "Operating in safe sandbox mode. Add FCM_SERVER_KEY in application.yml for real device push notifications.");
        return result;
    }

    /**
     * Broadcasts milk shift completion summary to all dairy staff
     */
    public Map<String, Object> broadcastShiftAlert(String shift, int totalEntries, double totalLiters) {
        String title = String.format("%s Shift Milk Collection Completed", shift);
        String body = String.format("Recorded %d farmer entries with %.1f Litres collected.", totalEntries, totalLiters);
        return sendPushNotification("dairy_staff_topic", title, body, Map.of("shift", shift, "liters", String.valueOf(totalLiters)));
    }
}
