package com.smartdairy.backend.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDate;

@Document(collection = "members")
public class Member {
    @Id
    private String id;

    @Indexed(unique = true)
    private String memberCode; // e.g. M001

    private String name;
    private String phone;
    private String animalType; // Cow or Buffalo
    private String bankName;
    private String accountNumber;
    private String ifscCode;

    private Double totalMilkSupplied = 0.0;
    private Double avgFat = 4.2;
    private Double totalAdvanceTaken = 0.0;
    private Double totalAdvancePending = 0.0;

    private boolean active = true;
    private LocalDate joinedDate = LocalDate.now();

    public Member() {}

    public Member(String memberCode, String name, String phone, String animalType, Double avgFat) {
        this.memberCode = memberCode;
        this.name = name;
        this.phone = phone;
        this.animalType = animalType;
        this.avgFat = avgFat;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getMemberCode() { return memberCode; }
    public void setMemberCode(String memberCode) { this.memberCode = memberCode; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getAnimalType() { return animalType; }
    public void setAnimalType(String animalType) { this.animalType = animalType; }

    public String getBankName() { return bankName; }
    public void setBankName(String bankName) { this.bankName = bankName; }

    public String getAccountNumber() { return accountNumber; }
    public void setAccountNumber(String accountNumber) { this.accountNumber = accountNumber; }

    public String getIfscCode() { return ifscCode; }
    public void setIfscCode(String ifscCode) { this.ifscCode = ifscCode; }

    public Double getTotalMilkSupplied() { return totalMilkSupplied; }
    public void setTotalMilkSupplied(Double totalMilkSupplied) { this.totalMilkSupplied = totalMilkSupplied; }

    public Double getAvgFat() { return avgFat; }
    public void setAvgFat(Double avgFat) { this.avgFat = avgFat; }

    public Double getTotalAdvanceTaken() { return totalAdvanceTaken; }
    public void setTotalAdvanceTaken(Double totalAdvanceTaken) { this.totalAdvanceTaken = totalAdvanceTaken; }

    public Double getTotalAdvancePending() { return totalAdvancePending; }
    public void setTotalAdvancePending(Double totalAdvancePending) { this.totalAdvancePending = totalAdvancePending; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public LocalDate getJoinedDate() { return joinedDate; }
    public void setJoinedDate(LocalDate joinedDate) { this.joinedDate = joinedDate; }
}
