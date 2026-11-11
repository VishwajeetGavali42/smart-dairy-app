package com.smartdairy.backend.controller;

import com.smartdairy.backend.entity.AuditLog;
import com.smartdairy.backend.entity.Notification;
import com.smartdairy.backend.repository.AuditLogRepository;
import com.smartdairy.backend.repository.NotificationRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/analytics")
public class AnalyticsController {

    private final NotificationRepository notificationRepository;
    private final AuditLogRepository auditLogRepository;

    public AnalyticsController(NotificationRepository notificationRepository, AuditLogRepository auditLogRepository) {
        this.notificationRepository = notificationRepository;
        this.auditLogRepository = auditLogRepository;
    }

    @GetMapping("/dashboard/reports")
    public ResponseEntity<Map<String, Object>> getReportSummary(@RequestParam(defaultValue = "This Month") String period) {
        Map<String, Object> data = new HashMap<>();
        if ("This Week".equalsIgnoreCase(period)) {
            data.put("collection", "2,980 Ltr");
            data.put("revenue", "₹1,34,100");
            data.put("expenses", "₹18,400");
            data.put("netProfit", "₹1,15,700");
        } else if ("This Year".equalsIgnoreCase(period)) {
            data.put("collection", "1,48,200 Ltr");
            data.put("revenue", "₹66,69,000");
            data.put("expenses", "₹9,12,000");
            data.put("netProfit", "₹57,57,000");
        } else {
            data.put("collection", "12,540 Ltr");
            data.put("revenue", "₹5,64,300");
            data.put("expenses", "₹78,250");
            data.put("netProfit", "₹4,86,050");
        }
        return ResponseEntity.ok(data);
    }

    @GetMapping("/notifications")
    public ResponseEntity<List<Notification>> getNotifications() {
        return ResponseEntity.ok(notificationRepository.findAll());
    }

    @GetMapping("/audit-logs")
    public ResponseEntity<List<AuditLog>> getAuditLogs() {
        return ResponseEntity.ok(auditLogRepository.findAll());
    }
}
