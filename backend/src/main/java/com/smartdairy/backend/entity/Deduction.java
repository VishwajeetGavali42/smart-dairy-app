package com.smartdairy.backend.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDate;

@Document(collection = "deductions")
public class Deduction {
    @Id
    private String id;

    private String member;
    private String animal; // Cow or Buffalo
    private String type; // Cattle Feed, Advance Recovery, Insurance, Equipment, Loan, Other
    private Double amount;
    private LocalDate date = LocalDate.now();
    private boolean recurring = false;
    private String reason;

    public Deduction() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getMember() { return member; }
    public void setMember(String member) { this.member = member; }
    public String getAnimal() { return animal; }
    public void setAnimal(String animal) { this.animal = animal; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public Double getAmount() { return amount; }
    public void setAmount(Double amount) { this.amount = amount; }
    public LocalDate getDate() { return date; }
    public void setDate(LocalDate date) { this.date = date; }
    public boolean isRecurring() { return recurring; }
    public void setRecurring(boolean recurring) { this.recurring = recurring; }
    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }
}
