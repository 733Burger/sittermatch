package com.sittermatch.sittermatch.dto;

/** A sitter's review of one pet after a stay. */
public record PetReviewResponse(
    Integer id,
    Integer petId,
    String petName,
    Integer rating,
    String notes,
    String sitterName,
    String createdAt
) {}
