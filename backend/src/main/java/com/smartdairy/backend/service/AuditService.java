package com.smartdairy.backend.service;

import com.smartdairy.backend.entity.AuditLog;
import com.smartdairy.backend.repository.AuditLogRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class AuditService {

    private final AuditLogRepository auditLogRepository;

    public AuditService(AuditLogRepository auditLogRepository) {
        this.auditLogRepository = auditLogRepository;
    }

    public AuditLog recordAudit(String action, String entityType, String entityId,
                                String performedBy, String performedRole, String details) {
        AuditLog log = new AuditLog(action, entityType, entityId, performedBy, performedRole, details);
        return auditLogRepository.save(log);
    }

    public List<AuditLog> getAuditLogs() {
        return auditLogRepository.findAllByOrderByTimestampDesc();
    }
}
