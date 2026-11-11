package com.smartdairy.backend.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;

@Document(collection = "users")
public class User {
    @Id
    private String id;

    @Indexed(unique = true)
    private String username;

    private String password;
    private String fullName;
    private String phone;
    private String dairyName = "Late L D Kadam Milk Producers Cooperative Society Ltd., Kadamwadi, Kolhapur";
    private String centerCode = "LDK-402";
    private RoleType role = RoleType.DAIRY_OWNER;
    private boolean enabled = true;
    private LocalDateTime createdAt = LocalDateTime.now();

    // Link to farmer profile when role is MEMBER
    private String memberId;
    private String memberCode; // e.g. M001

    public User() {}

    public User(String username, String password, String fullName, String phone, RoleType role) {
        this.username = username;
        this.password = password;
        this.fullName = fullName;
        this.phone = phone;
        this.role = role;
    }

    public User(String username, String password, String fullName, String phone, RoleType role, String memberCode) {
        this.username = username;
        this.password = password;
        this.fullName = fullName;
        this.phone = phone;
        this.role = role;
        this.memberCode = memberCode;
        this.memberId = memberCode;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getDairyName() { return dairyName; }
    public void setDairyName(String dairyName) { this.dairyName = dairyName; }

    public String getCenterCode() { return centerCode; }
    public void setCenterCode(String centerCode) { this.centerCode = centerCode; }

    public RoleType getRole() { return role; }
    public void setRole(RoleType role) { this.role = role; }

    public boolean isEnabled() { return enabled; }
    public void setEnabled(boolean enabled) { this.enabled = enabled; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public String getMemberId() { return memberId; }
    public void setMemberId(String memberId) { this.memberId = memberId; }

    public String getMemberCode() { return memberCode; }
    public void setMemberCode(String memberCode) { this.memberCode = memberCode; }
}
