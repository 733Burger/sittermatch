package com.sittermatch.sittermatch.model;

public enum ServiceType {
    OVERNIGHT_SITTING("Overnight Sitting"),
    DROP_IN_VISIT("Drop-in Visit"),
    DOG_WALKING("Dog Walking"),
    PET_GROOMING("Pet Grooming");

    private final String displayName;

    ServiceType(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
