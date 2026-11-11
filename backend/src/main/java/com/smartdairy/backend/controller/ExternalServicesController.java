package com.smartdairy.backend.controller;

import com.smartdairy.backend.service.*;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/external")
@CrossOrigin(origins = "*")
public class ExternalServicesController {

    private final SmsGatewayService smsGatewayService;
    private final NotificationDispatcherService notificationDispatcherService;
    private final CloudStorageService cloudStorageService;
    private final EmailService emailService;
    private final LocationService locationService;

    public ExternalServicesController(SmsGatewayService smsGatewayService,
                                      NotificationDispatcherService notificationDispatcherService,
                                      CloudStorageService cloudStorageService,
                                      EmailService emailService,
                                      LocationService locationService) {
        this.smsGatewayService = smsGatewayService;
        this.notificationDispatcherService = notificationDispatcherService;
        this.cloudStorageService = cloudStorageService;
        this.emailService = emailService;
        this.locationService = locationService;
    }

    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getExternalServicesStatus() {
        Map<String, Object> status = new java.util.LinkedHashMap<>();
        
        // SMS Gateway Status
        Map<String, Object> smsStatus = new java.util.LinkedHashMap<>();
        smsStatus.put("provider", smsGatewayService.getActiveProvider());
        smsStatus.put("isLive", smsGatewayService.isLiveConfigured());
        smsStatus.put("mode", smsGatewayService.isLiveConfigured() ? "LIVE_CARRIER" : "SANDBOX_MOCK");
        smsStatus.put("supportedProviders", java.util.List.of("FAST2SMS", "TWILIO"));
        status.put("sms", smsStatus);

        // Firebase Cloud Messaging Status
        Map<String, Object> fcmStatus = new java.util.LinkedHashMap<>();
        fcmStatus.put("provider", "FIREBASE_CLOUD_MESSAGING");
        fcmStatus.put("isLive", notificationDispatcherService.isLiveConfigured());
        fcmStatus.put("mode", notificationDispatcherService.isLiveConfigured() ? "LIVE_FCM" : "SANDBOX_MOCK");
        status.put("fcm", fcmStatus);

        // Cloud Storage Status
        Map<String, Object> storageStatus = new java.util.LinkedHashMap<>();
        storageStatus.put("provider", cloudStorageService.getStorageProvider());
        storageStatus.put("bucket", cloudStorageService.getS3Bucket());
        storageStatus.put("region", cloudStorageService.getS3Region());
        storageStatus.put("isLive", cloudStorageService.isLiveConfigured());
        storageStatus.put("mode", cloudStorageService.isLiveConfigured() ? "LIVE_AWS_S3" : "LOCAL_CLOUD_CACHE");
        status.put("storage", storageStatus);

        // Google Maps Status
        Map<String, Object> mapsStatus = new java.util.LinkedHashMap<>();
        mapsStatus.put("provider", "GOOGLE_MAPS_DISTANCE_MATRIX");
        mapsStatus.put("isLive", locationService.isLiveConfigured());
        mapsStatus.put("mode", locationService.isLiveConfigured() ? "LIVE_GOOGLE_MAPS" : "HAVERSINE_MATHEMATICAL_MODEL");
        status.put("maps", mapsStatus);

        return ResponseEntity.ok(status);
    }

    @PostMapping("/sms/test")
    public ResponseEntity<Map<String, Object>> testSms(
            @RequestParam String phone,
            @RequestParam(defaultValue = "LDK Smart Dairy test receipt message.") String message) {
        return ResponseEntity.ok(smsGatewayService.dispatchSms(phone, message));
    }

    @PostMapping("/sms/send-payment-notice")
    public ResponseEntity<Map<String, Object>> sendPaymentNotice(
            @RequestParam String phone,
            @RequestParam String memberName,
            @RequestParam double amount,
            @RequestParam(defaultValue = "1-10 May") String cycle) {
        return ResponseEntity.ok(smsGatewayService.sendPaymentNoticeSms(phone, memberName, amount, cycle));
    }

    @PostMapping("/fcm/push-notification")
    public ResponseEntity<Map<String, Object>> sendPush(
            @RequestParam String target,
            @RequestParam String title,
            @RequestParam String body) {
        return ResponseEntity.ok(notificationDispatcherService.sendPushNotification(target, title, body, Map.of()));
    }

    @PostMapping("/fcm/broadcast-shift")
    public ResponseEntity<Map<String, Object>> broadcastShift(
            @RequestParam String shift,
            @RequestParam int count,
            @RequestParam double liters) {
        return ResponseEntity.ok(notificationDispatcherService.broadcastShiftAlert(shift, count, liters));
    }

    @PostMapping("/email/send-alert")
    public ResponseEntity<Map<String, Object>> sendEmailAlert(
            @RequestParam String toEmail,
            @RequestParam String subject,
            @RequestParam String body) {
        return ResponseEntity.ok(emailService.sendAlertEmail(toEmail, subject, body));
    }

    @GetMapping("/maps/transit")
    public ResponseEntity<Map<String, Object>> getTransit(
            @RequestParam(defaultValue = "Center 1") String origin,
            @RequestParam(defaultValue = "Sangli Dairy Plant") String destination,
            @RequestParam(defaultValue = "16.8524") double originLat,
            @RequestParam(defaultValue = "74.5815") double originLon,
            @RequestParam(defaultValue = "16.9200") double destLat,
            @RequestParam(defaultValue = "74.6500") double destLon) {
        return ResponseEntity.ok(locationService.getEstimatedTransit(origin, destination, originLat, originLon, destLat, destLon));
    }
}
