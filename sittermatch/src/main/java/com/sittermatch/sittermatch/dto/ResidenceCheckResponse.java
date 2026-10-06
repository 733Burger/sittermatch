package com.sittermatch.sittermatch.dto;

public record ResidenceCheckResponse(
    boolean success,
    String message
) {
    public static ResidenceCheckResponse failure (String message) {
        return new ResidenceCheckResponse(false, message);
    }
}