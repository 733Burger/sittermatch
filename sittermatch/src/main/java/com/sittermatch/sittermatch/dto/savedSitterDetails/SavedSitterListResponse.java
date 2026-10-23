package com.sittermatch.sittermatch.dto.savedSitterDetails;

public record SavedSitterListResponse (
    Integer id,
    String name,
    Double rating,
    Integer totalReviews,
    Double dayRate,
    Double nightRate,
    Boolean isVerified,
    String suburb
) {
    public static SavedSitterListResponse failure(String message) {
        return new SavedSitterListResponse(
            null, 
            message,
            null,
            null,
            null,
            null,
            false,
            null
        );
    }
}