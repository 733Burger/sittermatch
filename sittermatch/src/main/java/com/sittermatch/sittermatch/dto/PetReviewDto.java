package com.sittermatch.sittermatch.dto;

public record PetReviewDto(
    Integer petId,
    Integer rating,
    String notes
) {}