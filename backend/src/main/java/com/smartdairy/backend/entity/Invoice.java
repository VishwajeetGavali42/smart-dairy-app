package com.smartdairy.backend.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDate;

@Document(collection = "invoices")
public class Invoice {
    @Id
    private String id;

    @Indexed(unique = true)
    private String invoiceNo;

    private String member;
    private String cycle;
    private Double milk; // Litres
    private Double gross;
    private Double advance;
    private Double deduction;
    private Double net;
    private String status = "Pending"; // Paid or Pending
    private LocalDate date = LocalDate.now();

    public Invoice() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getInvoiceNo() { return invoiceNo; }
    public void setInvoiceNo(String invoiceNo) { this.invoiceNo = invoiceNo; }
    public String getMember() { return member; }
    public void setMember(String member) { this.member = member; }
    public String getCycle() { return cycle; }
    public void setCycle(String cycle) { this.cycle = cycle; }
    public Double getMilk() { return milk; }
    public void setMilk(Double milk) { this.milk = milk; }
    public Double getGross() { return gross; }
    public void setGross(Double gross) { this.gross = gross; }
    public Double getAdvance() { return advance; }
    public void setAdvance(Double advance) { this.advance = advance; }
    public Double getDeduction() { return deduction; }
    public void setDeduction(Double deduction) { this.deduction = deduction; }
    public Double getNet() { return net; }
    public void setNet(Double net) { this.net = net; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public LocalDate getDate() { return date; }
    public void setDate(LocalDate date) { this.date = date; }
}
