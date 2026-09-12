package com.sittermatch.sittermatch.model;

public enum PetType {
    DOG("Dog"),
    CAT("Cat"),
    BIRD("Bird"),
    FISH("Fish"),
    REPTILE("Reptile"),
    RODENT("Rodent"),
    OTHER("Other");

    private final String displayName;

    PetType(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
