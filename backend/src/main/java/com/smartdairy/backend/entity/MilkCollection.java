package com.smartdairy.backend.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDate;
import java.time.LocalTime;

@Document(collection = "milk_collections")
public class MilkCollection {
    @Id
    private String id;

    private String memberCode;
    private String memberName;
    private String animalType; // Cow or Buffalo
    private String shift; // Morning or Evening

    private Double quantity; // Litres
    private Double fat;
    private Double snf;

    private Double ratePerLitre;
    private Double totalAmount;

    private LocalDate collectionDate = LocalDate.now();
    private LocalTime collectionTime = LocalTime.now();

    private boolean isAnomaly = false;
    private String anomalyReason;

    public MilkCollection() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getMemberCode() { return memberCode; }
    public void setMemberCode(String memberCode) { this.memberCode = memberCode; }

    public String getMemberName() { return memberName; }
    public void setMemberName(String memberName) { this.memberName = memberName; }

    public String getAnimalType() { return animalType; }
    public void setAnimalType(String animalType) { this.animalType = animalType; }

    public String getShift() { return shift; }
    public void setShift(String shift) { this.shift = shift; }

    public Double getQuantity() { return quantity; }
    public void setQuantity(Double quantity) { this.quantity = quantity; }

    public Double getFat() { return fat; }
    public void setFat(Double fat) { this.fat = fat; }

    public Double getSnf() { return snf; }
    public void setSnf(Double snf) { this.snf = snf; }

    public Double getRatePerLitre() { return ratePerLitre; }
    public void setRatePerLitre(Double ratePerLitre) { this.ratePerLitre = ratePerLitre; }

    public Double getTotalAmount() { return totalAmount; }
    public void setTotalAmount(Double totalAmount) { this.totalAmount = totalAmount; }

    public LocalDate getCollectionDate() { return collectionDate; }
    public void setCollectionDate(LocalDate collectionDate) { this.collectionDate = collectionDate; }

    public LocalTime getCollectionTime() { return collectionTime; }
    public void setCollectionTime(LocalTime collectionTime) { this.collectionTime = collectionTime; }

    public boolean isAnomaly() { return isAnomaly; }
    public void setAnomaly(boolean anomaly) { isAnomaly = anomaly; }

    public String getAnomalyReason() { return anomalyReason; }
    public void setAnomalyReason(String anomalyReason) { this.anomalyReason = anomalyReason; }
}
