package com.sittermatch.sittermatch.dto;

import java.util.List;

public record SitterProfileResponse(
        boolean success,
        String message,
        String name,
        String email,
        String phone,
        String experience,
        Double rating,
        Integer totalReviews,
        String serviceArea,
        String suburb,
        String city,
        Double latitude,
        Double longitude,
        List<String> petPreferences,
        List<ServiceItem> services) {

    public record ServiceItem(String serviceType, Double price, Integer durationMinutes) {}

    public static SitterProfileResponse failure(String message) {
        return new SitterProfileResponse(false, message, null, null, null, null, null, null,
                null, null, null, null, null, List.of(), List.of());
    }
}
