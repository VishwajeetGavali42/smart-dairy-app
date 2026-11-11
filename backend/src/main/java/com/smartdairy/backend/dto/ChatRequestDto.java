package com.smartdairy.backend.dto;

import jakarta.validation.constraints.Size;
import java.util.ArrayList;
import java.util.List;

public class ChatRequestDto {

    @Size(max = 4000, message = "Prompt cannot exceed 4000 characters")
    private String prompt;

    private String message; // alias for prompt

    private String role; // "DAIRY_OWNER", "MEMBER", "ADMIN"

    private String screenContext; // e.g. "Milk Collection", "Billing & Invoices"

    private String language; // "en", "mr", "hi"

    private String memberCode; // e.g. "M001" for member-specific queries

    private List<ChatMessageDto> history = new ArrayList<>();

    public ChatRequestDto() {}

    public String getEffectivePrompt() {
        if (prompt != null && !prompt.trim().isEmpty()) {
            return prompt.trim();
        }
        if (message != null && !message.trim().isEmpty()) {
            return message.trim();
        }
        return "";
    }

    public String getPrompt() {
        return prompt;
    }

    public void setPrompt(String prompt) {
        this.prompt = prompt;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    public String getScreenContext() {
        return screenContext;
    }

    public void setScreenContext(String screenContext) {
        this.screenContext = screenContext;
    }

    public String getLanguage() {
        return language;
    }

    public void setLanguage(String language) {
        this.language = language;
    }

    public String getMemberCode() {
        return memberCode;
    }

    public void setMemberCode(String memberCode) {
        this.memberCode = memberCode;
    }

    public List<ChatMessageDto> getHistory() {
        return history;
    }

    public void setHistory(List<ChatMessageDto> history) {
        this.history = history;
    }
}
