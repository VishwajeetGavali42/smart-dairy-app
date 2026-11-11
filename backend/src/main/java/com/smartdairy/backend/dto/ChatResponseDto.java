package com.smartdairy.backend.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.ArrayList;
import java.util.List;

public class ChatResponseDto {
    private String reply;
    private String status; // "SUCCESS", "ERROR"

    @JsonProperty("isLlmGenerated")
    private boolean isLlmGenerated;

    @JsonProperty("isConfigured")
    private boolean isConfigured;

    private String model;
    private String provider;
    private List<String> suggestedActions = new ArrayList<>();
    private long timestamp = System.currentTimeMillis();
    private String error;

    public ChatResponseDto() {}

    public ChatResponseDto(String reply, boolean isLlmGenerated, boolean isConfigured, String model, String provider) {
        this.reply = reply;
        this.status = "SUCCESS";
        this.isLlmGenerated = isLlmGenerated;
        this.isConfigured = isConfigured;
        this.model = model;
        this.provider = provider;
        this.timestamp = System.currentTimeMillis();
    }

    public static ChatResponseDto error(String error, String fallbackReply) {
        ChatResponseDto dto = new ChatResponseDto();
        dto.setStatus("ERROR");
        dto.setError(error);
        dto.setReply(fallbackReply != null ? fallbackReply : "An error occurred while processing your request.");
        dto.setLlmGenerated(false);
        dto.setConfigured(false);
        dto.setTimestamp(System.currentTimeMillis());
        return dto;
    }

    public String getReply() {
        return reply;
    }

    public void setReply(String reply) {
        this.reply = reply;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    @JsonProperty("isLlmGenerated")
    public boolean isLlmGenerated() {
        return isLlmGenerated;
    }

    @JsonProperty("isLlmGenerated")
    public void setLlmGenerated(boolean llmGenerated) {
        isLlmGenerated = llmGenerated;
    }

    @JsonProperty("isConfigured")
    public boolean isConfigured() {
        return isConfigured;
    }

    @JsonProperty("isConfigured")
    public void setConfigured(boolean configured) {
        isConfigured = configured;
    }

    public String getModel() {
        return model;
    }

    public void setModel(String model) {
        this.model = model;
    }

    public String getProvider() {
        return provider;
    }

    public void setProvider(String provider) {
        this.provider = provider;
    }

    public List<String> getSuggestedActions() {
        return suggestedActions;
    }

    public void setSuggestedActions(List<String> suggestedActions) {
        this.suggestedActions = suggestedActions;
    }

    public long getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(long timestamp) {
        this.timestamp = timestamp;
    }

    public String getError() {
        return error;
    }

    public void setError(String error) {
        this.error = error;
    }
}
