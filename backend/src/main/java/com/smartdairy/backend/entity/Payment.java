package com.smartdairy.backend.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDate;

@Document(collection = "payments")
public class Payment {
    @Id
    private String id;

    private String member;
    private String animal; // Cow or Buffalo
    private String milk; // e.g. "125.5 L"
    private Double gross;
    private Double advance = 0.0;
    private Double deduction = 0.0;
    private Double amount; // Net payable
    private String status = "Pending"; // Paid or Pending
    private String method = "Cash"; // UPI, Cash, Bank
    private String cycle = "Monthly"; // 10 Days, 15 Days, Monthly
    private LocalDate date = LocalDate.now();

    public Payment() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getMember() { return member; }
    public void setMember(String member) { this.member = member; }
    public String getAnimal() { return animal; }
    public void setAnimal(String animal) { this.animal = animal; }
    public String getMilk() { return milk; }
    public void setMilk(String milk) { this.milk = milk; }
    public Double getGross() { return gross; }
    public void setGross(Double gross) { this.gross = gross; }
    public Double getAdvance() { return advance; }
    public void setAdvance(Double advance) { this.advance = advance; }
    public Double getDeduction() { return deduction; }
    public void setDeduction(Double deduction) { this.deduction = deduction; }
    public Double getAmount() { return amount; }
    public void setAmount(Double amount) { this.amount = amount; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getMethod() { return method; }
    public void setMethod(String method) { this.method = method; }
    public String getCycle() { return cycle; }
    public void setCycle(String cycle) { this.cycle = cycle; }
    public LocalDate getDate() { return date; }
    public void setDate(LocalDate date) { this.date = date; }
}
