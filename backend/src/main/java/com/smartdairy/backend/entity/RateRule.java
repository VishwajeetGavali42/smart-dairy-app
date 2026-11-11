package com.smartdairy.backend.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Document(collection = "rate_rules")
public class RateRule {
    @Id
    private String id;

    @Indexed(unique = true)
    private String animalType; // Cow or Buffalo

    private Double baseRate;
    private Double minFat;
    private Double maxFat;
    private Double fatStep;
    private Double minSnf;
    private Double maxSnf;
    private Double snfStep;

    public RateRule() {}

    public RateRule(String animalType, Double baseRate, Double minFat, Double maxFat, Double fatStep, Double minSnf, Double maxSnf, Double snfStep) {
        this.animalType = animalType;
        this.baseRate = baseRate;
        this.minFat = minFat;
        this.maxFat = maxFat;
        this.fatStep = fatStep;
        this.minSnf = minSnf;
        this.maxSnf = maxSnf;
        this.snfStep = snfStep;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getAnimalType() { return animalType; }
    public void setAnimalType(String animalType) { this.animalType = animalType; }

    public Double getBaseRate() { return baseRate; }
    public void setBaseRate(Double baseRate) { this.baseRate = baseRate; }

    public Double getMinFat() { return minFat; }
    public void setMinFat(Double minFat) { this.minFat = minFat; }

    public Double getMaxFat() { return maxFat; }
    public void setMaxFat(Double maxFat) { this.maxFat = maxFat; }

    public Double getFatStep() { return fatStep; }
    public void setFatStep(Double fatStep) { this.fatStep = fatStep; }

    public Double getMinSnf() { return minSnf; }
    public void setMinSnf(Double minSnf) { this.minSnf = minSnf; }

    public Double getMaxSnf() { return maxSnf; }
    public void setMaxSnf(Double maxSnf) { this.maxSnf = maxSnf; }

    public Double getSnfStep() { return snfStep; }
    public void setSnfStep(Double snfStep) { this.snfStep = snfStep; }
}
