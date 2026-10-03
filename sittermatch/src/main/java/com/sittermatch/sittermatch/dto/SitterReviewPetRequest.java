package com.sittermatch.sittermatch.dto;

public record SitterReviewPetRequest (
    Integer bookingId,
    Integer petId,
    Integer rating,
    String notes
) {}
