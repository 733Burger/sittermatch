package com.sittermatch.sittermatch.services;

import com.sittermatch.sittermatch.model.VerificationStatus;

// Validation and display rules shared by the homeowner and sitter verification checks,
// so both checklists accept the same input and show the same statuses and subtitles.
final class VerificationCheckRules {
    static final long MAX_ID_PHOTO_BYTES = 5L * 1024 * 1024;

    private VerificationCheckRules() {
    }

    // Returns "jpg", "png" or "webp" from the file's leading bytes, or null for anything else.
    static String idPhotoExtension(byte[] bytes) {
        if (bytes.length >= 3
                && (bytes[0] & 0xFF) == 0xFF
                && (bytes[1] & 0xFF) == 0xD8
                && (bytes[2] & 0xFF) == 0xFF) {
            return "jpg";
        }
        if (bytes.length >= 8
                && (bytes[0] & 0xFF) == 0x89
                && bytes[1] == 0x50
                && bytes[2] == 0x4E
                && bytes[3] == 0x47
                && bytes[4] == 0x0D
                && bytes[5] == 0x0A
                && bytes[6] == 0x1A
                && bytes[7] == 0x0A) {
            return "png";
        }
        if (bytes.length >= 12
                && bytes[0] == 'R' && bytes[1] == 'I' && bytes[2] == 'F' && bytes[3] == 'F'
                && bytes[8] == 'W' && bytes[9] == 'E' && bytes[10] == 'B' && bytes[11] == 'P') {
            return "webp";
        }
        return null;
    }

    static boolean isValidEmergencyName(String name) {
        return !name.isBlank() && name.length() <= 100;
    }

    static boolean isValidEmergencyPhone(String phone) {
        return !phone.isBlank() && phone.length() <= 20 && phone.matches("[0-9+()\\- ]+");
    }

    static String emptyIfNull(String string) {
        return (string == null) ? "" : string;
    }

    static String tileStatus(VerificationStatus status) {
        if (status == null) return "incomplete";
        return switch (status) {
            case PENDING -> "pending";
            case APPROVED -> "completed";
            case REJECTED -> "rejected";
            case INCOMPLETE -> "incomplete";
        };
    }

    static String idSubtitle(VerificationStatus status) {
        if (status == null) return "No ID uploaded";
        return switch (status) {
            case PENDING -> "ID uploaded";
            case APPROVED -> "ID verified";
            case REJECTED -> "ID rejected";
            case INCOMPLETE -> "No ID uploaded";
        };
    }

    static String residenceSubtitle(String address) {
        return (address == null || address.isBlank()) ? "No address provided" : address;
    }

    static String emergencySubtitle(String name, String phone) {
        if (name.isBlank() && phone.isBlank()) {
            return "No Emergency Contact Uploaded";
        }
        if (name.isBlank()) {
            return "No contact name - " + phone;
        }
        if (phone.isBlank()) {
            return name + " - No contact details provided";
        }
        return name + " - " + phone;
    }
}
