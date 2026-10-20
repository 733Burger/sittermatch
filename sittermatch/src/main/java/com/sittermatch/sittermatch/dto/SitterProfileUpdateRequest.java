package com.sittermatch.sittermatch.dto;

import java.util.List;

public record SitterProfileUpdateRequest(
        String name,
        String email,
        String phone,
        String experience,
        List<ServiceInput> services,
        List<String> petPreferences) {

    public record ServiceInput(String serviceType, Double price, Integer durationMinutes) {}
}
