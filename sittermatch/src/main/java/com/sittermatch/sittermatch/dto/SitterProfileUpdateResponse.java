package com.sittermatch.sittermatch.dto;

public record SitterProfileUpdateResponse(
        boolean success, String message, String name, String email, String phone) {

    public static SitterProfileUpdateResponse failure(String message) {
        return new SitterProfileUpdateResponse(false, message, null, null, null);
    }
}