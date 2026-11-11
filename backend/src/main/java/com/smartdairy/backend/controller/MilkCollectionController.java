package com.smartdairy.backend.controller;

import com.smartdairy.backend.entity.MilkCollection;
import com.smartdairy.backend.entity.User;
import com.smartdairy.backend.repository.UserRepository;
import com.smartdairy.backend.service.AuditService;
import com.smartdairy.backend.service.MilkCollectionService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/v1/collections")
public class MilkCollectionController {

    private final MilkCollectionService collectionService;
    private final UserRepository userRepository;
    private final AuditService auditService;

    public MilkCollectionController(MilkCollectionService collectionService, UserRepository userRepository, AuditService auditService) {
        this.collectionService = collectionService;
        this.userRepository = userRepository;
        this.auditService = auditService;
    }

    private Optional<User> getAuthenticatedUser(Authentication auth) {
        if (auth == null || !auth.isAuthenticated()) return Optional.empty();
        return userRepository.findByUsername(auth.getName());
    }

    private boolean isMemberRole(Authentication auth) {
        if (auth == null) return false;
        return auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_MEMBER"));
    }

    private boolean isAuthorizedToManageCollections(Authentication auth) {
        if (auth == null || !auth.isAuthenticated()) return false;
        return auth.getAuthorities().stream().anyMatch(a ->
                a.getAuthority().equals("ROLE_DAIRY_OWNER") ||
                a.getAuthority().equals("ROLE_OWNER") ||
                a.getAuthority().equals("ROLE_ADMIN") ||
                a.getAuthority().equals("ROLE_EMPLOYEE")
        );
    }

    @PostMapping
    public ResponseEntity<?> recordCollection(@RequestBody MilkCollection collection, Authentication auth) {
        // Security BUG 1: Members cannot create or modify official collection records
        if (!isAuthorizedToManageCollections(auth)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "Unauthorized: Only Dairy Owners and authorized operators can record milk collections."));
        }
        try {
            MilkCollection saved = collectionService.saveCollection(collection);
            String authName = auth != null ? auth.getName() : "OWNER";
            String authRole = (auth != null && !auth.getAuthorities().isEmpty()) ? auth.getAuthorities().iterator().next().getAuthority() : "ROLE_OWNER";
            auditService.recordAudit(
                    "COLLECTION_RECORDED",
                    "COLLECTION",
                    saved.getId() != null ? saved.getId() : saved.getMemberCode(),
                    authName,
                    authRole,
                    "Recorded " + saved.getQuantity() + "L " + saved.getShift() + " milk for Member " + saved.getMemberCode() +
                            " (Fat: " + saved.getFat() + "%, SNF: " + saved.getSnf() + "%) @ ₹" + saved.getRatePerLitre() + "/L = ₹" + saved.getTotalAmount()
            );
            return ResponseEntity.ok(saved);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("error", e.getMessage()));
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateCollection(@PathVariable String id, @RequestBody MilkCollection collection, Authentication auth) {
        if (!isAuthorizedToManageCollections(auth)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "Unauthorized: Members cannot edit collection records."));
        }
        collection.setId(id);
        MilkCollection saved = collectionService.saveCollection(collection);
        return ResponseEntity.ok(saved);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteCollection(@PathVariable String id, Authentication auth) {
        if (!isAuthorizedToManageCollections(auth)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "Unauthorized: Members cannot delete collection records."));
        }
        return ResponseEntity.ok(Map.of("message", "Collection deleted successfully", "id", id));
    }

    @GetMapping("/today")
    public ResponseEntity<List<MilkCollection>> getTodayCollections(Authentication auth) {
        // If authenticated user is a Member, return only their today collections
        if (isMemberRole(auth)) {
            Optional<User> uOpt = getAuthenticatedUser(auth);
            if (uOpt.isPresent() && uOpt.get().getMemberCode() != null && !uOpt.get().getMemberCode().isBlank()) {
                String memberCode = uOpt.get().getMemberCode().trim();
                List<MilkCollection> memberToday = collectionService.getTodayCollections().stream()
                        .filter(c -> memberCode.equalsIgnoreCase(c.getMemberCode()))
                        .toList();
                return ResponseEntity.ok(memberToday);
            }
            return ResponseEntity.ok(Collections.emptyList());
        }
        return ResponseEntity.ok(collectionService.getTodayCollections());
    }

    @GetMapping("/summary/today")
    public ResponseEntity<Map<String, Object>> getTodaySummary(Authentication auth) {
        if (isMemberRole(auth)) {
            Optional<User> uOpt = getAuthenticatedUser(auth);
            if (uOpt.isPresent() && uOpt.get().getMemberCode() != null && !uOpt.get().getMemberCode().isBlank()) {
                String memberCode = uOpt.get().getMemberCode().trim();
                List<MilkCollection> memberToday = collectionService.getTodayCollections().stream()
                        .filter(c -> memberCode.equalsIgnoreCase(c.getMemberCode()))
                        .toList();
                double totalMilk = memberToday.stream().mapToDouble(c -> c.getQuantity() != null ? c.getQuantity() : 0.0).sum();
                double totalAmt = memberToday.stream().mapToDouble(c -> c.getTotalAmount() != null ? c.getTotalAmount() : 0.0).sum();
                double avgFat = memberToday.isEmpty() ? 0.0 : memberToday.stream().mapToDouble(c -> c.getFat() != null ? c.getFat() : 0.0).average().orElse(0.0);
                return ResponseEntity.ok(Map.of(
                        "totalMilk", Math.round(totalMilk * 100.0) / 100.0,
                        "totalAmount", Math.round(totalAmt * 100.0) / 100.0,
                        "avgFat", Math.round(avgFat * 10.0) / 10.0,
                        "collectionsCount", memberToday.size(),
                        "memberCount", 1
                ));
            }
            return ResponseEntity.ok(Map.of(
                    "totalMilk", 0.0,
                    "totalAmount", 0.0,
                    "avgFat", 0.0,
                    "collectionsCount", 0,
                    "memberCount", 0
            ));
        }
        return ResponseEntity.ok(collectionService.getTodaySummary());
    }

    @GetMapping
    public ResponseEntity<List<MilkCollection>> getAllCollections(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(required = false) String shift,
            Authentication auth) {

        List<MilkCollection> results;
        if (isMemberRole(auth)) {
            Optional<User> uOpt = getAuthenticatedUser(auth);
            if (uOpt.isPresent() && uOpt.get().getMemberCode() != null && !uOpt.get().getMemberCode().isBlank()) {
                String memberCode = uOpt.get().getMemberCode().trim();
                if (startDate != null && endDate != null) {
                    results = collectionService.getMemberCollectionsByDateRange(memberCode, startDate, endDate);
                } else {
                    results = collectionService.getMemberCollections(memberCode);
                }
            } else {
                return ResponseEntity.ok(Collections.emptyList());
            }
        } else {
            if (startDate != null && endDate != null) {
                results = collectionService.getCollectionsByDateRange(startDate, endDate);
            } else {
                results = collectionService.getAllCollections();
            }
        }

        if (shift != null && !shift.trim().isEmpty() && !shift.equalsIgnoreCase("ALL")) {
            results = results.stream().filter(c -> shift.equalsIgnoreCase(c.getShift())).toList();
        }
        return ResponseEntity.ok(results);
    }

    @GetMapping("/my-collections")
    public ResponseEntity<List<MilkCollection>> getMyCollections(Authentication auth) {
        Optional<User> uOpt = getAuthenticatedUser(auth);
        if (uOpt.isPresent() && uOpt.get().getMemberCode() != null && !uOpt.get().getMemberCode().isBlank()) {
            return ResponseEntity.ok(collectionService.getMemberCollections(uOpt.get().getMemberCode().trim()));
        }
        if (isMemberRole(auth)) {
            return ResponseEntity.ok(Collections.emptyList());
        }
        return ResponseEntity.ok(collectionService.getAllCollections());
    }

    @GetMapping("/member/{memberCode}")
    public ResponseEntity<?> getMemberCollections(@PathVariable String memberCode, Authentication auth) {
        // Enforce strict tenant boundary: Ramesh can NEVER access Suresh's records
        if (isMemberRole(auth)) {
            Optional<User> uOpt = getAuthenticatedUser(auth);
            if (uOpt.isEmpty() || uOpt.get().getMemberCode() == null || !uOpt.get().getMemberCode().equalsIgnoreCase(memberCode)) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body(Map.of("error", "Access denied. You can only access your own collection records."));
            }
        }
        return ResponseEntity.ok(collectionService.getMemberCollections(memberCode));
    }

    @GetMapping("/member/{memberCode}/cycles")
    public ResponseEntity<?> getMemberCycleTotals(@PathVariable String memberCode, Authentication auth) {
        if (isMemberRole(auth)) {
            Optional<User> uOpt = getAuthenticatedUser(auth);
            if (uOpt.isEmpty() || uOpt.get().getMemberCode() == null || !uOpt.get().getMemberCode().equalsIgnoreCase(memberCode)) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body(Map.of("error", "Access denied. You can only access your own billing cycle summary."));
            }
        }
        return ResponseEntity.ok(collectionService.getMemberCycleTotals(memberCode));
    }

    @GetMapping("/rate/calculate")
    public ResponseEntity<Map<String, Object>> calculateRate(
            @RequestParam String animalType,
            @RequestParam Double fat,
            @RequestParam Double snf) {
        Double rate = collectionService.calculateRate(animalType, fat, snf);
        return ResponseEntity.ok(Map.of("animalType", animalType, "fat", fat, "snf", snf, "ratePerLitre", rate));
    }
}
