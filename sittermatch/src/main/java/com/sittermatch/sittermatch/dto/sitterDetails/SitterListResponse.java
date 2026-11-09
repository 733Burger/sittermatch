package com.sittermatch.sittermatch.dto.sitterDetails;

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
    Double distanceKm
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
            null
        );
    }
}