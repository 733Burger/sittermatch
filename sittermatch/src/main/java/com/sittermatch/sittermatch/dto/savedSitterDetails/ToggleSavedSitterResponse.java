package com.sittermatch.sittermatch.dto.savedSitterDetails;

public record ToggleSavedSitterResponse(
    boolean success,
    String message,
    Boolean isSaved
) {
    public static ToggleSavedSitterResponse saved() {
        return new ToggleSavedSitterResponse(true, "Sitter added to saved list.", true);
    }
    public static ToggleSavedSitterResponse removed() {
        return new ToggleSavedSitterResponse(true, "Sitter removed from saved list.", false);
    }
    public static ToggleSavedSitterResponse failure(String message) {
        return new ToggleSavedSitterResponse(false, message, null);
    }
}
