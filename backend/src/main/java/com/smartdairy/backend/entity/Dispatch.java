package com.smartdairy.backend.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDate;

@Document(collection = "dispatches")
public class Dispatch {
    @Id
    private String id;

    private String destination;
    private String type; // Cow Milk, Buffalo Milk, Mixed Milk
    private Double quantity; // Litres
    private String vehicle;
    private LocalDate date = LocalDate.now();
    private String status = "Dispatched"; // Dispatched, In Transit, Delivered

    public Dispatch() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getDestination() { return destination; }
    public void setDestination(String destination) { this.destination = destination; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public Double getQuantity() { return quantity; }
    public void setQuantity(Double quantity) { this.quantity = quantity; }
    public String getVehicle() { return vehicle; }
    public void setVehicle(String vehicle) { this.vehicle = vehicle; }
    public LocalDate getDate() { return date; }
    public void setDate(LocalDate date) { this.date = date; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}
