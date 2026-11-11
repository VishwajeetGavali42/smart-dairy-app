package com.smartdairy.backend.dto;

public class AuthResponse {
    private String token;
    private String type = "Bearer";
    private String username;
    private String fullName;
    private String role;
    private String dairyName;
    private String centerCode;
    private String memberId;
    private String memberCode;

    public AuthResponse(String token, String username, String fullName, String role, String dairyName, String centerCode) {
        this(token, username, fullName, role, dairyName, centerCode, null, null);
    }

    public AuthResponse(String token, String username, String fullName, String role, String dairyName, String centerCode, String memberId, String memberCode) {
        this.token = token;
        this.username = username;
        this.fullName = fullName;
        this.role = role;
        this.dairyName = dairyName;
        this.centerCode = centerCode;
        this.memberId = memberId;
        this.memberCode = memberCode;
    }

    public String getToken() { return token; }
    public String getType() { return type; }
    public String getUsername() { return username; }
    public String getFullName() { return fullName; }
    public String getRole() { return role; }
    public String getDairyName() { return dairyName; }
    public String getCenterCode() { return centerCode; }
    public String getMemberId() { return memberId; }
    public String getMemberCode() { return memberCode; }
}
