package com.sittermatch.sittermatch.dto;

public record ProfileResponse(
        boolean success,
        String message,
        String name,
        String email,
        String phone,
        String address,
        String requirements) {

    public static ProfileResponse failure(String message) {
        return new ProfileResponse(false, message, null, null, null, null, null);
    }
}