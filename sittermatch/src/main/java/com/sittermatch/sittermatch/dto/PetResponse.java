package com.sittermatch.sittermatch.dto;

public record PetResponse(boolean success, String message, PetDto pet) {
    public static PetResponse failure(String message) {
        return new PetResponse(false, message, null);
    }
}
