package com.smartdairy.backend.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDate;

@Document(collection = "expenses")
public class Expense {
    @Id
    private String id;

    private String title;
    private String category; // Feed, Utilities, Transport, Maintenance, Medical, Other
    private Double amount;
    private LocalDate date = LocalDate.now();
    private String method = "Cash"; // UPI, Cash, Online, Bank

    public Expense() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }
    public Double getAmount() { return amount; }
    public void setAmount(Double amount) { this.amount = amount; }
    public LocalDate getDate() { return date; }
    public void setDate(LocalDate date) { this.date = date; }
    public String getMethod() { return method; }
    public void setMethod(String method) { this.method = method; }
}
