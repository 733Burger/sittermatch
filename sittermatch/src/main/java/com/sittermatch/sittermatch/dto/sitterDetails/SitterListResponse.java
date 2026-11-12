package com.sittermatch.sittermatch.dto.sitterDetails;

import java.util.List;

public record SitterListResponse (
    Integer id,
    String name,
    Double rating,
    Integer totalReviews,
    Double dayRate,
    Double nightRate,
    Boolean isVerified,
    Boolean isSaved,
    String suburb,
    Double distanceKm,
    List<String> serviceTypes,
    List<String> petTypes
) {
    public static SitterListResponse failure(String message) {
        return new SitterListResponse(
            null, 
            message,
            null,
            null,
            null,
            null,
            false,
            false,
            null,
            null,
            List.of(),
            List.of()
        );
    }
}