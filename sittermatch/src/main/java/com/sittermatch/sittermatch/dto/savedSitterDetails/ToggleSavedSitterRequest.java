package com.sittermatch.sittermatch.dto.savedSitterDetails;

public record ToggleSavedSitterRequest(
    Integer homeownerId,
    Integer sitterId,
    Boolean isCurrentlySaved
) {}
