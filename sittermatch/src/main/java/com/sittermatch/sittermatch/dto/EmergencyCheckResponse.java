package com.sittermatch.sittermatch.dto;

public record EmergencyCheckResponse(
    boolean success,
    String message
) {
    public static EmergencyCheckResponse failure (String message) {
        return new EmergencyCheckResponse(false, message);
    }
}