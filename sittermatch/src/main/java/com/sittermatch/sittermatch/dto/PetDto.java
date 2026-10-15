package com.sittermatch.sittermatch.dto;

public record PetDto(
        Integer id,
        String name,
        String species,
        String breed,
        Integer age,
        String careNotes,
        Double behaviourScore,
        Integer totalReviews,
        String imageUrl) {}
