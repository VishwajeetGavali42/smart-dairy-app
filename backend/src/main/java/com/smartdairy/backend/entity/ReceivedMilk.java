package com.smartdairy.backend.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDate;

@Document(collection = "received_milks")
public class ReceivedMilk {
    @Id
    private String id;

    private String source;
    private String type; // Cow Milk, Buffalo Milk, Mixed Milk
    private Double quantity; // Litres
    private String quality; // e.g. "FAT 4.2%"
    private LocalDate date = LocalDate.now();
    private String status = "Accepted"; // Accepted, Pending

    public ReceivedMilk() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getSource() { return source; }
    public void setSource(String source) { this.source = source; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public Double getQuantity() { return quantity; }
    public void setQuantity(Double quantity) { this.quantity = quantity; }
    public String getQuality() { return quality; }
    public void setQuality(String quality) { this.quality = quality; }
    public LocalDate getDate() { return date; }
    public void setDate(LocalDate date) { this.date = date; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}
