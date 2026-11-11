package com.smartdairy.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
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

@Service
public class LocationService {

    private static final Logger log = LoggerFactory.getLogger(LocationService.class);

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(5))
            .build();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${smartdairy.maps.api-key:}")
    private String mapsApiKey;

    public boolean isLiveConfigured() {
        return mapsApiKey != null && !mapsApiKey.trim().isEmpty() && !mapsApiKey.contains("MOCK") && !mapsApiKey.contains("KEY_456");
    }

    /**
     * Calculates great-circle distance between two GPS coordinates using Haversine formula
     */
    public double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
        final int R = 6371; // Earth radius in kilometers
        double latDistance = Math.toRadians(lat2 - lat1);
        double lonDistance = Math.toRadians(lon2 - lon1);
        double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return Math.round(R * c * 100.0) / 100.0;
    }

    /**
     * Computes route and estimated tanker transit time using Google Maps API (Live) or Haversine (Fallback)
     */
    public Map<String, Object> getEstimatedTransit(String originCenter, String destinationPlant, double originLat, double originLon, double destLat, double destLon) {
        Map<String, Object> result = new HashMap<>();
        result.put("origin", originCenter);
        result.put("destination", destinationPlant);

        // 1. Attempt Live Google Maps Distance Matrix API
        if (isLiveConfigured()) {
            try {
                String url = String.format(
                        "https://maps.googleapis.com/maps/api/distancematrix/json?origins=%f,%f&destinations=%f,%f&key=%s",
                        originLat, originLon, destLat, destLon, mapsApiKey.trim()
                );

                HttpRequest request = HttpRequest.newBuilder()
                        .uri(URI.create(url))
                        .timeout(Duration.ofSeconds(5))
                        .GET()
                        .build();

                HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
                if (response.statusCode() == 200) {
                    JsonNode root = objectMapper.readTree(response.body());
                    JsonNode elements = root.path("rows").path(0).path("elements").path(0);
                    if ("OK".equalsIgnoreCase(elements.path("status").asText())) {
                        double distanceMeters = elements.path("distance").path("value").asDouble();
                        double durationSeconds = elements.path("duration").path("value").asDouble();
                        double distanceKm = Math.round((distanceMeters / 1000.0) * 100.0) / 100.0;
                        int durationMinutes = (int) Math.round(durationSeconds / 60.0);

                        log.info("[GOOGLE MAPS LIVE] Distance: {} km, Duration: {} mins", distanceKm, durationMinutes);
                        result.put("distanceKm", distanceKm);
                        result.put("estimatedMinutes", durationMinutes);
                        result.put("transitSummary", String.format("%d km (~%d mins transit)", (int) distanceKm, durationMinutes));
                        result.put("source", "GOOGLE_MAPS_LIVE");
                        result.put("live", true);
                        return result;
                    }
                }
            } catch (Exception e) {
                log.warn("[Google Maps API Exception] Live routing failed, using Haversine calculation: {}", e.getMessage());
            }
        }

        // 2. Haversine Math Fallback (High-accuracy, zero API fee)
        double distanceKm = calculateDistanceKm(originLat, originLon, destLat, destLon);
        // Average rural dairy tanker road speed ~45 km/h
        double transitHours = distanceKm / 45.0;
        int transitMinutes = (int) Math.round(transitHours * 60);

        log.info("[LOCATION SERVICE - HAVERSINE] Route from {} to {}: {} km, Est time: {} mins", originCenter, destinationPlant, distanceKm, transitMinutes);
        result.put("distanceKm", distanceKm);
        result.put("estimatedMinutes", transitMinutes);
        result.put("transitSummary", String.format("%d km (~%d mins transit via Haversine calculation)", (int) distanceKm, transitMinutes));
        result.put("source", "HAVERSINE_ALGORITHM");
        result.put("live", false);
        return result;
    }
}
