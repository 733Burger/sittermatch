package com.sittermatch.sittermatch.dto;

public record ProfileResponse(
        boolean success,
        String message,
        String name,
        String email,
        String phone,
        String address,
        String requirements,
        Double latitude,
        Double longitude,
        String suburb,
        String city) {

    public static ProfileResponse failure(String message) {
        return new ProfileResponse(false, message, null, null, null, null, null, null, null, null, null);
    }
}