package com.sittermatch.sittermatch.dto;

public record AddPetRequest(
        String name,
        String species,
        String breed,
        Integer age,
        String careNotes) {}
