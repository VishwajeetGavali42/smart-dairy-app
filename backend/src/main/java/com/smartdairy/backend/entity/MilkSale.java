package com.smartdairy.backend.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDate;

@Document(collection = "milk_sales")
public class MilkSale {
    @Id
    private String id;

    private String buyer;
    private String milk; // Cow Milk, Buffalo Milk, Mixed Milk
    private Double quantity; // Litres
    private Double rate;
    private String status = "Paid"; // Paid, Pending
    private LocalDate date = LocalDate.now();

    public MilkSale() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getBuyer() { return buyer; }
    public void setBuyer(String buyer) { this.buyer = buyer; }
    public String getMilk() { return milk; }
    public void setMilk(String milk) { this.milk = milk; }
    public Double getQuantity() { return quantity; }
    public void setQuantity(Double quantity) { this.quantity = quantity; }
    public Double getRate() { return rate; }
    public void setRate(Double rate) { this.rate = rate; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public LocalDate getDate() { return date; }
    public void setDate(LocalDate date) { this.date = date; }
}
