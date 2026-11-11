package com.smartdairy.backend.service;

import com.smartdairy.backend.entity.MilkCollection;
import com.smartdairy.backend.entity.RateRule;
import com.smartdairy.backend.entity.Member;
import com.smartdairy.backend.repository.MilkCollectionRepository;
import com.smartdairy.backend.repository.RateRuleRepository;
import com.smartdairy.backend.repository.MemberRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class MilkCollectionService {

    private final MilkCollectionRepository collectionRepository;
    private final RateRuleRepository rateRuleRepository;
    private final MemberRepository memberRepository;
    private final SmsGatewayService smsGatewayService;

    public MilkCollectionService(MilkCollectionRepository collectionRepository,
                                 RateRuleRepository rateRuleRepository,
                                 MemberRepository memberRepository,
                                 SmsGatewayService smsGatewayService) {
        this.collectionRepository = collectionRepository;
        this.rateRuleRepository = rateRuleRepository;
        this.memberRepository = memberRepository;
        this.smsGatewayService = smsGatewayService;
    }

    public Double calculateRate(String animalType, Double fat, Double snf) {
        RateRule rule = rateRuleRepository.findByAnimalTypeIgnoreCase(animalType)
                .orElse(new RateRule(animalType, "Cow".equalsIgnoreCase(animalType) ? 38.0 : 54.0, 3.5, 5.0, 0.40, 8.0, 9.0, 0.30));

        double baseRate = rule.getBaseRate();
        double minFat = rule.getMinFat();
        double fatStep = rule.getFatStep();
        double minSnf = rule.getMinSnf();
        double snfStep = rule.getSnfStep();

        double fatDiff = (fat - minFat) * 10;
        double snfDiff = (snf - minSnf) * 10;

        double rate = baseRate + (fatDiff * fatStep) + (snfDiff * snfStep);
        return Math.round(rate * 100.0) / 100.0;
    }

    public MilkCollection saveCollection(MilkCollection collection) {
        // P0 Validation: Enforce strict constraints on quantity, FAT, and SNF to prevent corrupted records
        if (collection.getQuantity() == null || collection.getQuantity() <= 0.0 || collection.getQuantity() > 1000.0) {
            throw new IllegalArgumentException("Invalid milk quantity: Must be between 0.1 and 1000.0 Litres.");
        }
        if (collection.getFat() == null || collection.getFat() < 1.0 || collection.getFat() > 15.0) {
            throw new IllegalArgumentException("Invalid FAT reading: Must be between 1.0% and 15.0%.");
        }
        if (collection.getSnf() == null || collection.getSnf() < 4.0 || collection.getSnf() > 15.0) {
            throw new IllegalArgumentException("Invalid SNF reading: Must be between 4.0% and 15.0%.");
        }

        if (collection.getCollectionDate() == null) {
            collection.setCollectionDate(LocalDate.now());
        }

        if (collection.getMemberCode() != null) {
            collection.setMemberCode(collection.getMemberCode().trim().toUpperCase());
        }

        // P0 Duplicate Prevention: Check if duplicate entry exists for same member, date, shift, and quantity
        if (collection.getMemberCode() != null && collection.getShift() != null) {
            List<MilkCollection> existingList = collectionRepository.findByCollectionDateAndShift(
                    collection.getCollectionDate(), collection.getShift()
            );
            for (MilkCollection existing : existingList) {
                if (existing.getMemberCode() != null &&
                        existing.getMemberCode().equalsIgnoreCase(collection.getMemberCode()) &&
                        Math.abs((existing.getQuantity() != null ? existing.getQuantity() : 0.0) - collection.getQuantity()) < 0.001) {
                    // Record already exists in MongoDB, return existing to prevent duplicate submission
                    return existing;
                }
            }
        }

        // Clear client-generated temporary IDs (e.g. col_17298...) so MongoDB generates clean ObjectId
        if (collection.getId() != null && collection.getId().startsWith("col_")) {
            collection.setId(null);
        }

        // P0 Calculation: Compute verified rate and exact total amount to prevent billing discrepancies
        Double calculatedRate = calculateRate(collection.getAnimalType(), collection.getFat(), collection.getSnf());
        if (collection.getRatePerLitre() == null || collection.getRatePerLitre() <= 0) {
            collection.setRatePerLitre(calculatedRate);
        }
        collection.setTotalAmount(Math.round(collection.getQuantity() * collection.getRatePerLitre() * 100.0) / 100.0);

        // Simple anomaly rule check: standard FAT is 3.0 - 10.0%, SNF is 7.5 - 10.0%
        if (collection.getFat() < 3.0 || collection.getFat() > 10.0 || collection.getSnf() < 7.5 || collection.getSnf() > 10.5) {
            collection.setAnomaly(true);
            collection.setAnomalyReason("Unusual FAT/SNF reading detected");
        }

        MilkCollection saved = collectionRepository.save(collection);

        // Update Member totalMilkSupplied and avgFat and send SMS receipt
        if (collection.getMemberCode() != null) {
            memberRepository.findByMemberCodeIgnoreCase(collection.getMemberCode()).ifPresent(member -> {
                double currentMilk = member.getTotalMilkSupplied() != null ? member.getTotalMilkSupplied() : 0.0;
                member.setTotalMilkSupplied(Math.round((currentMilk + collection.getQuantity()) * 100.0) / 100.0);
                if (collection.getFat() != null && collection.getFat() > 0) {
                    member.setAvgFat(collection.getFat());
                }
                memberRepository.save(member);
                smsGatewayService.sendMilkReceiptSms(saved, member);
            });
        }

        return saved;
    }

    public List<MilkCollection> getCollectionsByDateRange(LocalDate start, LocalDate end) {
        if (start == null && end == null) return getAllCollections();
        if (start == null) start = LocalDate.now().minusDays(30);
        if (end == null) end = LocalDate.now();
        return collectionRepository.findByCollectionDateBetween(start, end);
    }

    public List<MilkCollection> getMemberCollectionsByDateRange(String memberCode, LocalDate start, LocalDate end) {
        if (memberCode == null || memberCode.trim().isEmpty()) return java.util.Collections.emptyList();
        String cleanCode = memberCode.trim().toUpperCase();
        if (start == null && end == null) return getMemberCollections(cleanCode);
        if (start == null) start = LocalDate.now().minusDays(30);
        if (end == null) end = LocalDate.now();
        return collectionRepository.findByMemberCodeIgnoreCaseAndCollectionDateBetween(cleanCode, start, end);
    }

    public List<MilkCollection> getTodayCollections() {
        return collectionRepository.findByCollectionDate(LocalDate.now());
    }

    public List<MilkCollection> getAllCollections() {
        return collectionRepository.findAll();
    }

    public List<MilkCollection> getMemberCollections(String memberCode) {
        if (memberCode == null || memberCode.trim().isEmpty()) return java.util.Collections.emptyList();
        return collectionRepository.findByMemberCodeIgnoreCase(memberCode.trim().toUpperCase());
    }

    public Map<String, Object> getTodaySummary() {
        List<MilkCollection> todayList = getTodayCollections();
        double totalMilk = todayList.stream().mapToDouble(c -> c.getQuantity() != null ? c.getQuantity() : 0.0).sum();
        double totalAmount = todayList.stream().mapToDouble(c -> c.getTotalAmount() != null ? c.getTotalAmount() : 0.0).sum();
        double avgFat = todayList.isEmpty() ? 0.0 :
                todayList.stream().mapToDouble(c -> c.getFat() != null ? c.getFat() : 0.0).average().orElse(0.0);

        Map<String, Object> summary = new HashMap<>();
        summary.put("totalMilk", Math.round(totalMilk * 100.0) / 100.0);
        summary.put("totalAmount", Math.round(totalAmount * 100.0) / 100.0);
        summary.put("avgFat", Math.round(avgFat * 10.0) / 10.0);
        summary.put("collectionsCount", todayList.size());
        summary.put("memberCount", (int) memberRepository.count());
        return summary;
    }

    public Map<String, Object> getMemberCycleTotals(String memberCode) {
        List<MilkCollection> list = collectionRepository.findByMemberCode(memberCode);
        LocalDate now = LocalDate.now();
        LocalDate tenDaysAgo = now.minusDays(10);
        LocalDate fifteenDaysAgo = now.minusDays(15);
        LocalDate startOfMonth = now.withDayOfMonth(1);
        LocalDate startOfYear = now.withDayOfYear(1);

        double milk10 = 0.0, amt10 = 0.0;
        double milk15 = 0.0, amt15 = 0.0;
        double milkMonth = 0.0, amtMonth = 0.0;
        double milkYear = 0.0, amtYear = 0.0;

        for (MilkCollection c : list) {
            LocalDate d = c.getCollectionDate() != null ? c.getCollectionDate() : now;
            double qty = c.getQuantity() != null ? c.getQuantity() : 0.0;
            double amt = c.getTotalAmount() != null ? c.getTotalAmount() : 0.0;

            if (!d.isBefore(tenDaysAgo)) {
                milk10 += qty;
                amt10 += amt;
            }
            if (!d.isBefore(fifteenDaysAgo)) {
                milk15 += qty;
                amt15 += amt;
            }
            if (!d.isBefore(startOfMonth)) {
                milkMonth += qty;
                amtMonth += amt;
            }
            if (!d.isBefore(startOfYear)) {
                milkYear += qty;
                amtYear += amt;
            }
        }

        Map<String, Object> result = new HashMap<>();
        result.put("tenDays", Map.of("litres", Math.round(milk10 * 10.0) / 10.0, "amount", Math.round(amt10)));
        result.put("fifteenDays", Map.of("litres", Math.round(milk15 * 10.0) / 10.0, "amount", Math.round(amt15)));
        result.put("monthly", Map.of("litres", Math.round(milkMonth * 10.0) / 10.0, "amount", Math.round(amtMonth)));
        result.put("yearly", Map.of("litres", Math.round(milkYear * 10.0) / 10.0, "amount", Math.round(amtYear)));
        return result;
    }
}
