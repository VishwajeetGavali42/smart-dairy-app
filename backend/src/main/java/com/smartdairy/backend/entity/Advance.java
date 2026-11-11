package com.smartdairy.backend.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDate;

@Document(collection = "advances")
public class Advance {
    @Id
    private String id;

    private String member;
    private String memberId;
    private Double amount;
    private Double recovered = 0.0;
    private String reason;
    private String status = "Pending"; // Pending or Recovered
    private LocalDate date = LocalDate.now();

    public Advance() {}

    public Advance(String member, String memberId, Double amount, Double recovered, String reason, String status, LocalDate date) {
        this.member = member;
        this.memberId = memberId;
        this.amount = amount;
        this.recovered = recovered;
        this.reason = reason;
        this.status = status;
        this.date = date;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getMember() { return member; }
    public void setMember(String member) { this.member = member; }
    public String getMemberId() { return memberId; }
    public void setMemberId(String memberId) { this.memberId = memberId; }
    public Double getAmount() { return amount; }
    public void setAmount(Double amount) { this.amount = amount; }
    public Double getRecovered() { return recovered; }
    public void setRecovered(Double recovered) { this.recovered = recovered; }
    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public LocalDate getDate() { return date; }
    public void setDate(LocalDate date) { this.date = date; }
}
