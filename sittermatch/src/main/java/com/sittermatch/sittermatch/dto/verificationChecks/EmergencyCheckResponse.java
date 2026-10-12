package com.sittermatch.sittermatch.dto.verificationChecks;

public record EmergencyCheckResponse(
    boolean success,
    String message
) {
    public static EmergencyCheckResponse failure (String message) {
        return new EmergencyCheckResponse(false, message);
    }
}