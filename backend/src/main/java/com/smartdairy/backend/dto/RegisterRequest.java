package com.smartdairy.backend.dto;

public class RegisterRequest {
    private String username;
    private String password;
    private String confirmPassword;
    private String role; // OWNER, MEMBER, ADMIN
    private String fullName;
    private String phone;
    private String memberCode;
    private String adminSecretKey;

    public RegisterRequest() {}

    public RegisterRequest(String username, String password, String confirmPassword, String role) {
        this.username = username;
        this.password = password;
        this.confirmPassword = confirmPassword;
        this.role = role;
    }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public String getConfirmPassword() { return confirmPassword; }
    public void setConfirmPassword(String confirmPassword) { this.confirmPassword = confirmPassword; }

    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getMemberCode() { return memberCode; }
    public void setMemberCode(String memberCode) { this.memberCode = memberCode; }

    public String getAdminSecretKey() { return adminSecretKey; }
    public void setAdminSecretKey(String adminSecretKey) { this.adminSecretKey = adminSecretKey; }
}
